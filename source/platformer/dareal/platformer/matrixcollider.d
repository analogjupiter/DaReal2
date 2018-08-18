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
    Collision matrices collection

    See_Also:
        Use .buildMatrices() for construction
 +/
struct WorldMatrices
{
    /++
        Collision matrix for wall blocks
     +/
    Matrix wallBlocks;

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
