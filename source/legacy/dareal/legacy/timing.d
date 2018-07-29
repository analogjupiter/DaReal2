/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.timing;

import std.container.array;
import std.traits : isNumeric;

public
{
    import dareal.legacy.interfaces : IClocked, IResetable;
}

public:

/++
    IClocked collection implementing IClocked itself
 +/
class Clockwork : IClocked
{
    private
    {
        Array!(IClocked) _clockhands;
    }

    public
    {
        alias _clockhands this;
    }

    /++
        Moves the clockwork one tick forward.

        Executes .nextTick() of all stored clockhands.
     +/
    public void nextTick()
    {
        foreach (IClocked clk; this._clockhands)
        {
            clk.nextTick();
        }
    }
}

/++
    Clockhand with transmission

    Moves its handle one tick forward once a threshold is reached.
 +/
class CounterClockhand(TCounter, THandle) : IClocked,
    IResetable if (is(isNumeric!(TCounter)) && is(THandle == IClocked))
{
    private
    {
        THandle _handle;

        TCounter _counter;
        TCounter _threshold;
    }

    public
    {
        @property
        {
            /++
                The internal counter's current value
             +/
            TCounter counter()
            {
                return this._counter;
            }

            /++ ditto +/
            void counter(TCounter value)
            {
                this._counter = value;
            }
        }

        @property
        {
            /++
                Handle clocked by the clockhand
             +/
            THandle handle()
            {
                return this._handle;
            }

            /++ ditto +/
            void handle(THandle value)
            {
                this._handle = value;
            }
        }

        @property
        {
            /++
                Threshold value

                Once the counter reaches this value, the handle will get moved one tick forward.
             +/
            TCounter threshold()
            {
                return this._threshold;
            }

            /++ ditto +/
            void threshold(TCounter value)
            {
                this._threshold = value;
            }
        }
    }

    /++
        ctor
     +/
    public this(THandle handle, TCounter threshold)
    {
        this._handle = handle;
    }

    /++
        Moves this clockhand one tick forward
     +/
    public void nextTick()
    {
        this._handle.nextTick();
    }

    /++
        Resets the internal counter
     +/
    public void reset()
    {
        this._counter = TCounter.init;
    }
}
