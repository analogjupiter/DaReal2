/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
/++
    Memory-intensive matrix-based collision detection

    The idea is to create matrix containing a simplified projection of game world's block data.
    This allows to allows to query the matrix instead of iterating over the blocks every check.
    In order to reduce the memory usage one might consider splitting the whole block data
    into seperate collision domains.

    This does not support negative positions.
 +/
module dareal.platformer.matrixcollider;

import std.container.array : Array;
import std.range : ElementType;
import dareal.platformer.world;

public
{
    import std.range : Chunks;
}

public
{
    alias MatrixBase = Array!bool.Range;
    alias Matrix = Chunks!MatrixBase;
}

/++
    Data and meta data container for matrix-based collision detection
 +/
struct MatrixCollider
{
@safe pure nothrow @nogc:

    /++
        Size of a tile in the matrix
     +/
    size_t tileSize = 1;

    /++
        Width of the world projected onto the matrix
     +/
    size_t realWidth;

    /++
        Height of the world projected onto the matrix
     +/
    size_t realHeight;

    /++
        Width of the matrix projection
     +/
    @property size_t projectionWidth() const
    {
        return (this.realWidth / this.tileSize);
    }

    /++
        Height of the matrix projection
     +/
    @property size_t projectionHeight() const
    {
        return (this.realHeight / this.tileSize);
    }
}

/++
    Creates a new matrix and fills it with blocks data;
 +/
Matrix buildMatrix(Range)(MatrixCollider mxcr, Range blocks)
        if (hasPosition!(ElementType!Range))
{
    auto m = mxcr.newMatrix();
    mxcr.fillMatrix(m, blocks);
    return m;
}

/++
    Fills the collision matrix based on the passed blocks

    See_Also:
        insertMatrix() for single blocks
 +/
void fillMatrix(Matrix2D, Range)(MatrixCollider mxcr, Matrix2D matrix, Range blocks)
        if (isBlockType!(ElementType!Range))
{
    pragma(inline, true);
    foreach (block; blocks)
    {
        mxcr.insertMatrix(matrix, block);
    }
}

/++
    Adds the passed block to the collision matrix

    See_Also:
        fillMatrix() for multiple blocks at once
 +/
void insertMatrix(Matrix2D, Block)(MatrixCollider mxcr, Matrix2D matrix, Block block)
        if (isBlockType!Block)
{
    pragma(inline, true);
    mxcr.insertMatrix(matrix, block.position.x, block.position.y,
            block.size.width, block.size.height);
}

/++
    Adds a block to the collision matrix
 +/
void insertMatrix(Matrix2D)(MatrixCollider mxcr, Matrix2D matrix,
        size_t blockPositionX, size_t blockPositionY, size_t blockWidth, size_t blockHeight)
{

    pragma(inline, true);
    immutable size_t aX = blockPositionX / mxcr.tileSize;
    immutable size_t aY = blockPositionY / mxcr.tileSize;

    immutable size_t bX = blockPositionX - 1 + blockWidth / mxcr.tileSize;
    immutable size_t bY = blockPositionY - 1 + blockHeight / mxcr.tileSize;

    for (size_t y = aY; y < bY; ++y)
    {
        for (size_t x = aX; x < bX; ++x)
        {
            matrix[y][x] = true;
        }
    }
}

/++
    Creates a new matrix with the specified size
 +/
Matrix newMatrix(MatrixCollider mxcr) nothrow
{
    pragma(inline, true);
    return newMatrix(mxcr.projectionWidth, mxcr.projectionHeight);
}

/++ ditto +/
Matrix newMatrix(size_t matrixWidth, size_t matrixHeight) nothrow
{
    import std.range : chunks;

    auto n = matrixWidth * matrixHeight;

    Array!bool m;
    m.reserve(n);

    for (; n > 0; --n)
    {
        m ~= false;
    }

    return chunks(m[], matrixWidth);
}

/++
    Scan procedures for collision detections
 +/
enum ScanProcedure
{
    /++
        Basic "foreach" scanning
        - row by row, one coll after another

        Example:
            [3x3]
            (0/0), (0/1), (0/2), (1/0), (1/1), ...
     +/
    rowByRow,

    /++
        Complex approach checking corners first
        - row by row - from the outside in,
        from left to the center
        and from right to the center

        Overhead: 4 counters

        Odd sizes will result in duplicated checks.
        Results will be slow if the collision happens somewhere in the middle.
        Moreover, this will be rather slow if there's no collision.

        Example:
            [2x5]                       // <-- odd height

            center := (1+0)/2 = 0
            middle := (4+0)/2 = 2

            (0/0), (1/4), (1/0), (0/4)
            (0/1), (1/3), (1/1), (0/3)
            (0/2), (1/2), (1/2), (0/2)  // <-- duplicates

            --> up to 4x3 checks in this example

        -----------------------------------------------------------

            [4x4]                       // <-- both even, best case

            center := (3+0)/2 = 1
            middle := (3+0)/2 = 1

            (0/0), (3/3), (3/0), (0/3)
            (1/0), (2/3), (2/0), (1/3)
            (0/1), (3/2), (3/1), (0/2)
            (1/1), (2/2), (2/1), (1/2)

            --> up to 4x4 checks in this example

        -----------------------------------------------------------

        Example:
            [5x5]                       // <-- both odd, worst case

            center := (4+0)/2 = 2
            middle := (4+0)/2 = 2

            (0/0), (4/4), (4/0), (0/4)
            (1/0), (3/4), (3/0), (1/4)
            (2/0), (2/4), (2/0), (2/4)  // <-- duplicates
            (0/1), (4/3), (4/1), (0/3)
            (1/1), (3/3), (3/1), (1/3)
            (2/1), (2/3), (2/1), (2/3)  // <-- duplicates
            (0/2), (4/2), (4/2), (0/2)  // <-- duplicates
            (1/2), (3/2), (3/2), (1/2)
            (2/2), (2/2), (2/2), (2/2)  // <-- duplicates

            --> up to 9x4 checks in this example
     +/
    topLeftBottomRight,
}

/++
    Calculates if a collision occured for the passed block
 +/
bool collide(ScanProcedure scanProcedure = ScanProcedure.rowByRow, Matrix2D, Block)(
        MatrixCollider mxcr, Matrix2D matrix, Block block) if (isBlockType!Block)
{
    pragma(inline, true);
    return mxcr.collide(matrix, block.position.x, block.position.y,
            block.size.width, block.size.height);
}

/++ ditto +/
bool collide(ScanProcedure scanProcedure = ScanProcedure.rowByRow, Matrix2D)(MatrixCollider mxcr, Matrix2D matrix,
        size_t blockPositionX, size_t blockPositionY, size_t blockWidth, size_t blockHeight)
{
    immutable size_t aX = blockPositionX / mxcr.tileSize;
    immutable size_t aY = blockPositionY / mxcr.tileSize;

    immutable size_t bX = blockPositionX - 1 + blockWidth / mxcr.tileSize;
    immutable size_t bY = blockPositionY - 1 + blockHeight / mxcr.tileSize;

    static if (ScanProcedure == ScanProcedure.rowByRow)
    {
        for (size_t y = aY; y <= bY; ++y)
        {
            for (size_t x = aX; x <= bX; ++x)
            {
                if (matrix[y][x])
                {
                    return true;
                }
            }
        }
    }
    else static if (scanProcedure == ScanProcedure.topLeftBottomRight)
    {
        immutable size_t y05 = (bY + aY) / 2;
        immutable size_t x05 = (bX + aX) / 2;

        size_t x1 = aX;
        size_t x2 = bX;

        size_t y1 = aY;
        size_t y2 = bY;
        while (true)
        {
            if (matrix[y1][x1] || matrix[y2][x2] || matrix[y1][x2] || matrix[y2][x1])
            {
                //return true;
            }

            if (x1 < x05)
            {
                ++x1;
            }
            else if (x1 == x05)
            {
                if (y1 < y05)
                {
                    ++y1;
                }
                else if (y1 == y05)
                {
                    break;
                }

                if (y2 > y05)
                {
                    --y2;
                }

                x1 = aX;
                x2 = bX;
                continue;
            }

            if (x2 > x05)
            {
                --x2;
            }
        }
    }
    else
    {
        static assert("No implementation for scan procedure: " ~ scanProcedure);
    }
    return false;
}

/++
    Collision matrices collection

    See_Also:
        Use .buildMatrices() for construction
 +/
struct WorldMatrices
{
    /++
        Collision matrix for wall blocks
     +/
    Matrix walls;

    /++
        Collision matrix for jump-through blocks
     +/
    Matrix jumpThroughBlocks;
}

/++
    Creates the collision matrices for the passed world
 +/
WorldMatrices buildMatrices(RangeWall, RangeJumpThrough)(MatrixCollider mxcr,
        RangeWall wallBlocks, RangeJumpThrough jumpThroughBlocks)
        if (isBlockType!(ElementType!RangeWall) && isBlockType!(ElementType!RangeJumpThrough))
{
    pragma(inline, true);
    return WorldMatrices(mxcr.buildMatrix(wallBlocks), mxcr.buildMatrix(jumpThroughBlocks));
}
