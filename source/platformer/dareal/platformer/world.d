/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.platformer.world;

import std.container.array : Array;
import std.traits : ReturnType;

// dfmt off
/++
    Determines whether P is a point-type
 +/
enum bool isPointType(P) =
(
    is(typeof(P.init) == P) &&
    is(ReturnType!((P p) => p.x) == int) &&
    is(ReturnType!((P p) => p.y) == int)
);

/++
    Determines whether T has a point-type position property
 +/
enum bool hasPosition(T) =
(
    is(typeof(T.init) == T) &&
    isPointType!(ReturnType!((T t) => t.position))
);

/++
    Determines whether S is a size-type
 +/
enum bool isSizeType(S) =
(
    is(typeof(S.init) == S) &&
    is(ReturnType!((S s) => s.width) == int) &&
    is(ReturnType!((S s) => s.height) == int)
);

/++
    Determines whether T has a size-type size property
 +/
enum bool hasSize(T) =
(
    is(typeof(T.init) == T) &&
    isSizeType!(ReturnType!((T t) => t.size))
);

/++
    Determines whether B is a block-type
 +/
enum bool isBlockType(B) =
(
    hasPosition!B &&
    hasSize!B
);
// dfmt on
