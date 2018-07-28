/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.util.path;

/++
    Returns: folder where the program's executable is located in
 +/
string thisExeDir()
{
    import std.path : dirName;
    import std.file : thisExePath;

    return thisExePath.dirName;
}
