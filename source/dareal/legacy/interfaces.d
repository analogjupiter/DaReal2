/++
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.interfaces;

public:

/++
    Interface for clocked stuff
 +/
interface IClocked
{
    /++
        Tells the object that it's the next tick
     +/
    void nextTick();
}

/++
    Interface for objects that can be drawn
 +/
interface IDrawable
{
    /++
        Draws the object
     +/
    void draw();
}

/++
    Interface for resetable objects
 +/
interface IResetable
{
    /++
        Resets the object
     +/
    void reset();
}
