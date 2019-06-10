/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
+/
module dareal.util.format;

import std.algorithm : reverse;
import std.conv : to;
import std.range : retro;
import std.traits : isIntegral;

/++
    Converts an integer number to a string with thousands separators
 +/
string separateThousands(char separator = ',', Integer)(Integer value) @safe pure
        if (isIntegral!Integer)
{
    char[] output;

    immutable x = value.to!string;

    size_t cnt = 1;
    foreach (n; x.retro)
    {
        output ~= n;
        if (cnt++ % 3 == 0)
        {
            output ~= separator;
        }
    }

    return output.reverse.idup;
}
