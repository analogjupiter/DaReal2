/++
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
+/
/++
    dareal.legacy is a D port of DaRealJS.

    DaRealJS has been written in C# and relies on Bridge.NET (transpiles to JS).
    It is a drawing and timing library for game development and was developed
    as part of a school project. Some parts of it have been designed cheaply.
    Unfortunately, this was necessary for time reasons.

    DaRealJS credits:
        + development
            + Zake (Lukas Aufmesser)
            + 0xEAB (Elias Batek)
        + testing:
            + Kio20 (Bernhard Kornberger)
 +/
module dareal.legacy;

public:
import dareal.legacy.graphics;
import dareal.legacy.interfaces;
import dareal.legacy.layereddrawing;
import dareal.legacy.math;
import dareal.legacy.timing;
