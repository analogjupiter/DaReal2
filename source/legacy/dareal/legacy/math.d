/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.math;

import std.traits : Unqual;

/++
    2D point
 +/
struct Point
{
@nogc nothrow pure @safe:

    private
    {
        int _x;
        int _y;
    }

    public
    {
        @property
        {
            /++
                x-coordinate

                "abscissa"
             +/
            ref int x()
            {
                return this._x;
            }

            /++ ditto +/
            void x(int value)
            {
                this._x = value;
            }
        }

        @property
        {
            /++
                y-coordinate

                "ordinate"
             +/
            ref int y()
            {
                return this._y;
            }

            /++ ditto +/
            void y(int value)
            {
                this._y = value;
            }
        }
    }

    @property
    {
        /++
            Reversed point
         +/
        Point reverse()
        {
            return (this * -1);
        }
    }

    /++
        ctor
     +/
    this(int x, int y)
    {
        this._x = x;
        this._y = y;
    }

    /++
        Binary Operators
     +/
    Point opBinary(string op, T)(T b)
    {
        static if (is(Unqual!T == Point) && (op == "+"))
        {
            return Point(this._x + b._x, this._y + b._y);
        }
        else static if (is(Unqual!T == Point) && (op == "-"))
        {
            return Point(this._x - b._x, this._y - b._y);
        }
        else static if (is(Unqual!T == int) && (op == "*"))
        {
            return Point(this._x * b, this._y * b);
        }
        else static if (is(Unqual!T == Size) && (op == "+"))
        {
            return Point(this._x + b.width, this._y + b.height);
        }
        else
        {
            static assert(0,
                    "Operator " ~ op ~ " not implemented for types "
                    ~ Point.stringof ~ " and " ~ T.stringof);
        }
    }

    /++
        Op Assignment Operator
     +/
    void opOpAssign(string op)(Point b)
    {
        final switch (op)
        {
        case "+":
            this._x += b._x;
            this._y += b._y;
            break;

        case "-":
            this._x -= b._x;
            this._y -= b._y;
            break;

        default:
            static assert(0,
                    "Op Assignment Operator " ~ op ~ " not implemented for type " ~ Point.stringof);
            break;
        }
    }

    /++ ditto +/
    void opOpAssign(string op)(int b) if (op == "*")
    {
        this._x *= b;
        this._y *= b;
    }
}

/++
    2D size
 +/
struct Size
{
@nogc nothrow pure @safe:

    private
    {
        int _width;
        int _height;
    }

    public
    {
        @property
        {
            /++
                Width
             +/
            ref int width()
            {
                return this._width;
            }

            /++ ditto +/
            void width(int value)
            {
                this._width = value;
            }
        }

        @property
        {
            /++
                Height
             +/
            ref int height()
            {
                return this._height;
            }

            /++ ditto +/
            void height(int value)
            {
                this._height = value;
            }
        }
    }

    /++
        ctor
     +/
    this(int width, int height)
    {
        this._width = width;
        this._height = height;
    }

    /++
        Binary Operators
     +/
    Size opBinary(string op, T)(T b)
    {
        static if (is(Unqual!T == Size) && (op == "+"))
        {
            return Size(this._width + b._width, this._height + b._height);
        }
        else static if (is(Unqual!T == Size) && (op == "-"))
        {
            return Size(this._width - b._width, this._height - b._height);
        }
        else static if (is(Unqual!T == int) && (op == "*"))
        {
            return Size(this._width * b, this._height * b);
        }
        else static if (is(Unqual!T == int) && (op == "/"))
        {
            return Size(this._width / b, this._height / b);
        }
        else
        {
            static assert(0,
                    "Operator " ~ op ~ " not implemented for types "
                    ~ Size.stringof ~ " and " ~ T.stringof);
        }
    }

    /++
        Op Assignment Operator
     +/
    void opOpAssign(string op)(Size b)
    {
        final switch (op)
        {
        case "+":
            this._width += b._width;
            this._height += b._height;
            break;

        case "-":
            this._width += b._width;
            this._height += b._height;
            break;

        default:
            static assert(0,
                    "Op Assignment Operator " ~ op ~ " not implemented for type " ~ Point.stringof);
            break;
        }
    }

    /++ ditto +/
    void opOpAssign(string op)(int b) if (op == "*")
    {
        this._width *= b;
        this._height *= b;
    }
}

/++
    Returns: Top left corner of the specified shape
 +/
Point centerToTopLeft(Point center, Size size)
{
    immutable x = (center.x - (size.width / 2));
    immutable y = (center.y - (size.height / 2));
    return Point(x, y);
}

/++
    Returns: Center point of the specified shape
 +/
Point topLeftToCenter(Point topLeft, Size size)
{
    immutable x = (topLeft.x + (size.width / 2));
    immutable y = (topLeft.y + (size.height / 2));
    return Point(x, y);
}
