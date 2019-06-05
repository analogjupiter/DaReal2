/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.util.sync;

import core.sync.semaphore : Duration, Semaphore;
import core.sync.mutex : Mutex;

public
{
    alias TaskDelegateCallback = void delegate();
    alias TaskFunctionCallback = void function();

    alias TaskQueue(bool useDelegate = true) = TaskQueueBase!(Task!(useDelegate));

    /++
        Queue for scheduling one-time awaitable tasks
     +/
    alias Task1Queue(bool useDelegate = true) = TaskQueueBase!(Task1!(useDelegate));
}

/++
    Extended semaphore for special use-cases
    where notifyAll() is needed

    Allows also short-circuiting:
        .notify() won't do anything then
        .wait() will just return then
        .wait(Duration) will just return true then
        .tryWait() will just return true then

    Doesn't change the counter.
    So all blocked threads are kept blocked.

    See_Also:
        core.sync.semaphore.Semaphore
 +/
final class SemaphoreX : Semaphore
{
    private
    {
        int _counter;
        Mutex _mutex;
        bool _shortCircuit;
    }

    /++
        ctor

        See_Also:
            core.sync.semaphore.Semaphore
     +/
    public this(uint count = 0)
    {
        super(count);
        this._counter = -(int(count));
        this._mutex = new Mutex();
    }

    public
    {
        override
        {
            void wait()
            {
                synchronized (this._mutex)
                {
                    if (this._shortCircuit)
                    {
                        return;
                    }
                    this._counter++;
                }
                super.wait();
            }

            bool wait(Duration period)
            {
                synchronized (this._mutex)
                {
                    if (this._shortCircuit)
                    {
                        return true;
                    }
                    this._counter++;
                }
                immutable rslt = super.wait(period);
                if (!rslt)
                {
                    synchronized (this._mutex)
                    {
                        this._counter--;
                    }
                }
                return rslt;
            }

            void notify()
            {
                synchronized (this._mutex)
                {
                    if (this._shortCircuit)
                    {
                        return;
                    }
                    this._counter--;
                }
                super.notify();
            }

            bool tryWait()
            {
                synchronized (this._mutex)
                {
                    if (this._shortCircuit)
                    {
                        return true;
                    }
                    this._counter++;
                }
                immutable rslt = super.tryWait();
                if (!rslt)
                {
                    synchronized (this._mutex)
                    {
                        this._counter--;
                    }
                }
                return rslt;
            }
        }

        /++
            Notifies all waiters
         +/
        void notifyAll(bool shortCircuit = false)
        {
            int n = void;
            synchronized (this._mutex)
            {
                if (this._shortCircuit)
                {
                    return;
                }
                n = this._counter;
                this._counter = 0;
                if (shortCircuit)
                {
                    this._shortCircuit = true;
                }
            }

            for (; n > 0; --n)
            {
                super.notify();
            }
        }

        /++
            Short-circuits the semaphore
            or disables the short circuit
         +/
        void shortCircuit(bool enabled)
        {
            synchronized (this._mutex)
            {
                this._shortCircuit = enabled;
            }
        }
    }
}

/++
    Queue for scheduling tasks
 +/
final class TaskQueueBase(TaskType)
{
    private
    {
        import std.container.slist : SList;
    }

    private
    {
        SList!TaskType _tasks;
        Mutex _mutex;
    }

    /++
        ctor
     +/
    public this()
    {
        this._mutex = new Mutex();
    }

    public
    {
        /++
            Executes one task in the current thread
         +/
        void executeOne()
        {
            TaskType t = void;
            synchronized (this._mutex)
            {
                t = this._tasks.removeAny();
            }
            t.execute();
        }

        /++s
            Executes n tasks in the current thread
         +/
        void executeN(size_t n)()
        {
            TaskType t = void;
            static foreach (i; 0 .. n)
            {
                synchronized (this._mutex)
                {
                    if (this._tasks.empty)
                    {
                        return;
                    }

                    t = this._tasks.stableRemoveAny();
                }
                t.execute();
            }
        }

        /++
            Executes all scheduled taks in the current thread
         +/
        void executeAll()
        {
            synchronized (this._mutex)
            {
                while (!this._tasks.empty)
                {
                    this._tasks.removeAny().execute();
                }
            }
        }

        /++
            Adds a task to the queue
         +/
        void schedule(TaskType t)
        {
            synchronized (this._mutex)
            {
                this._tasks.insertFront(t);
            }
        }

        /++ ditto +/
        void opOpAssign(string op : "~")(TaskType t)
        {
            this.schedule(t);
        }

        static if (is(TaskType == Task!true) || is(TaskType == Task1!true))
        {
            /++
                Creates a new task from a callback and adds it to the queue
             +/
            TaskType schedule(TaskDelegateCallback callback)
            {
                auto t = TaskType(callback);
                this.schedule(t);
                return t;
            }

            /++ ditto +/
            TaskType schedule(TaskFunctionCallback callback)
            {
                import std.functional : toDelegate;

                return this.schedule(callback.toDelegate);
            }
        }
        else static if (is(TaskType == Task!false) || is(TaskType == Task1!false))
        {
            /++
                Creates a new task from a callback and adds it to the queue
             +/
            TaskType schedule(TaskFunctionCallback callback)
            {
                auto t = TaskType(callback);
                this.schedule(t);
                return t;
            }
        }
    }
}

/++
    Wrapper for callbacks making them awaitable
 +/
struct Task(bool useDelegate = true)
{
    private
    {
        static if (useDelegate)
        {
            alias CallbackType = TaskDelegateCallback;
        }
        else
        {
            alias CallbackType = TaskFunctionCallback;
        }

        SemaphoreX _semaphore;
    }

    /++
        Callback wrapped by the task
     +/
    CallbackType callback;

    /++
        ctor
     +/
    this(CallbackType callback)
    {
        this.callback = callback;
        this._semaphore = new SemaphoreX(0);
    }

    /++
        Executes the task in the current thread
     +/
    void execute()
    {
        this.callback();
        this._semaphore.notifyAll(true);
    }

    /++
        Starts a new thread that executes the task
     +/
    void executeInNewThread()
    {
        import core.thread : Thread;

        Thread th = new Thread(&this.execute);
        th.start();
    }

    /++
        Blocking await
     +/
    void await()
    {
        this._semaphore.wait();
    }
}

/++
    One-time awaitable task

    Can be awaited only once, calling await() a 2nd time or in another thread is undefined behavior.
    Use Task1 only when this is no problem.
 +/
struct Task1(bool useDelegate = true)
{
    private
    {
        static if (useDelegate)
        {
            alias CallbackType = TaskDelegateCallback;
        }
        else
        {
            alias CallbackType = TaskFunctionCallback;
        }

        Semaphore _semaphore;
    }

    /++
        Callback wrapped by the task
     +/
    CallbackType callback;

    /++
        ctor
     +/
    this(CallbackType callback)
    {
        this.callback = callback;
        this._semaphore = new Semaphore(0);
    }

    /++
        Executes the task in the thread calling this function
     +/
    void execute()
    {
        this.callback();
        this._semaphore.notify();
    }

    /++
        Starts a new thread that executes the task
     +/
    void executeInNewThread()
    {
        import core.thread : Thread;

        auto th = new Thread(&this.execute);
        th.start();
    }

    /++
        Blocking await
     +/
    void await()
    {
        this._semaphore.wait();
    }
}
