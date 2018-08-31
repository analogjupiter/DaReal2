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

/++
    Pass all matrices containing blocks the character could land on to this function.
    If there're obstacles the player could hit pass their matrix, too.
 +/
alias collideJumpFalling(MatrixWallsAndJumpThroughBlocks) = collide!(
        ScanProcedure.borderBottomOnly, MatrixWallsAndJumpThroughBlocks);

alias collideWalkLeft(MatrixWallsAndJumpThroughBlocks) = collide!(ScanProcedure.borderLeftOnly);
alias collideWalkRight(MatrixWallsAndJumpThroughBlocks) = collide!(
        ScanProcedure.borderRightOnly, MatrixWallsAndJumpThroughBlocks);

alias canFallThrough(MatrixFallThroughBlocks) = collide!(
        ScanProcedure.borderBottomOnly, MatrixFallThroughBlocks);

/++
    Helper for acceleration and braking
 +/
struct Speed
{
    /++
        Current speed
     +/
    float speedCurrent;

    /++
        Acceleration

        Speed-up factor

        Possible values:
            = 1 ... no acceleration, won't speed up
            > 1 ... accelerate by the given factor
     +/
    float acceleration;

    /++
        Brakeforce

        Slow-down factor

        Possible values:
            = 1 ... no brakes, won't slow down
            < 1 ... brake by the given factor
            = 0 ... instant braking
     +/
    float brakeforce;

    /++
        Minimum speed

        Is not be enforced.
        A misconfigured brakeforce will allow going below this threshold.
     +/
    float speedMin;

    /++
        Maximum speed

        Is not be enforced.
        A misconfigured brakeforce will allow going above this threshold.
     +/
    float speedMax;

    /++
        Returns:
            A copy with acceleration or braking applied
     +/
    Speed next(bool accelerate) const
    {
        if (accelerate)
        {
            if (this.speedCurrent >= this.speedMax)
            {
                return this;
            }

            return Speed((this.speedCurrent * this.acceleration),
                    this.acceleration, this.speedMin, this.speedMax);
        }

        // brake

        if (this.speedCurrent <= this.speedMin)
        {
            return this;
        }

        return Speed((this.speedCurrent * this.brakeforce), this.acceleration,
                this.speedMin, this.speedMax);
    }
}
