/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.platformer.movement;

import dareal.platformer.matrixcollider;

public
{
    import dareal.platformer.matrixcollider : ScanProcedure;
}

/++
    Don't pass the jumpthrough matrix to this function!
 +/
alias collideJumpUp(MatrixWalls) = collide!(ScanProcedure.borderTopOnly, MatrixWalls);
alias collideJumpFalling(MatrixWallsAndJumpThroughBlocks) = collide!(
        ScanProcedure.borderBottomOnly, MatrixWallsAndJumpThroughBlocks);
alias collideWalkLeft(MatrixWallsAndJumpThroughBlocks) = collide!(ScanProcedure.borderLeftOnly);
alias collideWalkRight(MatrixWallsAndJumpThroughBlocks) = collide!(
        ScanProcedure.borderRightOnly, MatrixWallsAndJumpThroughBlocks);

alias canFallThrough(MatrixFallThroughBlocks) = collide!(
        ScanProcedure.borderBottomOnly, MatrixFallThroughBlocks);
