/++
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.graphics;

import std.conv : to;
import std.math : floor, PI;

import arsd.nanovega;
import dareal.legacy.math;
import dareal.legacy.interfaces;
import tinyevent;

public
{
    alias Image = NVGImage;
    alias Paint = NVGPaint;
    alias Context = NVGContext;
}

__gshared private
{
    Context _darealNVGContext;
}

/++
    DaReal's drawing context

    Use daRealInit to supply your own context.

    See_Also:
        darealInit()
 +/
Context darealNVGContext()
{
    return _darealNVGContext;
}

/++
    Drawing angle 180/PI
 +/
enum float fullDrawingAngle = (180 / PI);

/++
    Specify a custom drawing context

    This must be called before anything else of dareal.legacy.graphics.
 +/
void darealInit(NVGContext context)
{
    _darealNVGContext = context;
}

void drawImage(Paint image, Point point, Size size)
{
    darealNVGContext.beginPath();
    darealNVGContext.rect(point.x, point.y, size.width, size.height);
    darealNVGContext.fillPaint = image;
    darealNVGContext.fill();
}

/++
    Camera-like object that provides the point of view
 +/
class Camera
{
    alias CameraOffsetChangedEvent = Event!(Camera, Point);

    private
    {
        CameraOffsetChangedEvent _cameraOffsetChanged;
        Point _offset;
    }

    public
    {
        @property
        {
            /++
                Event that triggers when the camera's offset changes
             +/
            CameraOffsetChangedEvent cameraOffsetChanged()
            {
                return this._cameraOffsetChanged;
            }
        }

        @property
        {
            /++
                Camera offset
             +/
            Point offset()
            {
                return this._offset;
            }

            /++ ditto +/
            void offset(Point value)
            {
                auto old = this._offset;
                this._offset = value;
                this.cameraOffsetChanged.emit(this, old);
            }
        }
    }
}

/++
    Picture
 +/
deprecated("Wouldn't use that anymore. dareal.legacy also got rid of it :) ") class Picture
    : IDrawable
{
    private
    {
        Image _image;
        Paint _paint;
    }

    public
    {
        @property
        {
            /++
                Internal image
             +/
            Image image()
            {
                return this._image;
            }

            /++ ditto +/
            void image(Image value)
            {
                this._image = value;
                this._paint = darealNVGContext.imagePattern(0, 0, this.naturalSize.width,
                        this.naturalSize.height, fullDrawingAngle, this._image);
            }

            /++
                Paint created of the stored image
             +/
            Paint paint()
            {
                return this._paint;
            }
        }

        @property
        {
            /++
                Natural size of the loaded image
             +/
            Size naturalSize()
            {
                return Size(this._image.width, this._image.height);
            }
        }
    }

    /++
        ctor
     +/
    public this(Image image)
    {
        this.image = image;
    }

    /++ ditto +/
    public this(string file)
    {
        Image image = darealNVGContext.createImage(file);
        if (image == Image.init)
        {
            throw new Exception("Loading of image failed: " ~ file);
        }
        this.image = image;
    }

    ~this()
    {
        darealNVGContext.deleteImage(this._image);
    }

    public
    {
        void draw()
        {
            this._paint.drawImage(Point(0, 0), Size(this.naturalSize.width,
                    this.naturalSize.height));
        }
    }
}

/++
    Base class for drawings with a position
 +/
abstract class PositionedDrawing : IDrawable, IPositioned
{
    protected
    {
        Point _position;
    }

    public
    {
        @property
        {
            /++
                Position of the drawing
             +/
            Point position()
            {
                return this._position;
            }

            /++ ditto +/
            void position(Point value)
            {
                this._position = value;
            }
        }
    }

    public
    {
        /++
            Draws the object
         +/
        abstract void draw();
    }
}

/++
    SpriteMap
 +/
class SpriteMap : PositionedDrawing
{
    private
    {
        Point _currentSprite;
        Size _frameSize;
        Image _spriteSheet;
        Paint _paint;
    }

    public
    {
        @property
        {
            /++
                Center point
             +/
            Point center()
            {
                return (this.position + (this.frameSize / 2));
            }
        }

        @property
        {
            /++
                Position of the current sprite on the sprite sheet
             +/
            Point currentSprite()
            {
                return this._currentSprite;
            }

            /++ ditto +/
            void currentSprite(Point value)
            in
            {
                assert(value.x < (this._spriteSheet.width / this._frameSize.width));
                assert(value.y < (this._spriteSheet.height / this._frameSize.height));
            }
            do
            {
                this._currentSprite = value;
            }
        }

        @property
        {
            /++
                Returns:
                    Count of frames of this sprite map
             +/
            uint frameCount()
            {
                return ((1f * this._spriteSheet.width / this._frameSize.width)
                        .floor.to!uint * (1f * this._spriteSheet.width / this._frameSize.height)
                        .floor.to!uint);
            }
        }

        @property
        {
            /++
                Size of a single sprite on the sprite sheet
             +/
            Size frameSize()
            {
                return this._frameSize;
            }

            /++ ditto +/
            void frameSize(Size value)
            in
            {
                assert(this._spriteSheet.width % value.width == 0);
                assert(this._spriteSheet.height % value.height == 0);
            }
            do
            {
                this._frameSize = value;
                this.updatePaint();
            }
        }

        @property
        {
            /++
                Internal image used as sprite sheet
             +/
            Image spriteSheet()
            {
                return this._spriteSheet;
            }

            /++ ditto +/
            void spriteSheet(Image value)
            {
                this._spriteSheet = value;
                this.updatePaint();
            }
        }
    }

    /++
        ctor for single-sprite sprite sheets
     +/
    public this(Image spriteSheet)
    {
        this._frameSize = Size(spriteSheet.width, spriteSheet.height);
        this.spriteSheet = spriteSheet;
    }

    /++
        ctor
     +/
    public this(Image spriteSheet, Size frameSize)
    {
        this._frameSize = frameSize;
        this.spriteSheet = spriteSheet;
    }

    public
    {
        /++
            Draws the current frame
         +/
        override void draw()
        {
            this._paint.drawImage(this._position, this._frameSize);
        }

        /++
            Moves to the next frame of the sprite sheet
         +/
        void nextFrame()
        {
            // Row end?
            if (((this._currentSprite.y + 1) * this._frameSize.width) >= this._spriteSheet.width)
            {
                ++this._currentSprite.y;

                // Last row?
                if (((this._currentSprite.y) * this.frameSize.height) >= this._spriteSheet.height)
                {
                    this._currentSprite.x = 0;
                    this._currentSprite.y = 0;
                }
            }
            else
            {
                ++this._currentSprite.x;
            }

            this.updatePaint();
        }
    }

    protected
    {
        void updatePaint()
        {
            this._paint = darealNVGContext.imagePattern(this._currentSprite.x, this._currentSprite.y,
                    this._frameSize.width, this._frameSize.height,
                    fullDrawingAngle, this._spriteSheet);
        }
    }
}

/++
    SpriteMap-based animation
 +/
class Animation : PositionedDrawing, IResetable
{
    private
    {
        SpriteMap _spriteMap;
        bool _flipHorizontal;
    }

    public
    {
        @property
        {
            /++
                Flip the drawing horizontal?
             +/
            bool flipHorizontal()
            {
                return this._flipHorizontal;
            }

            /++ ditto +/
            void flipHorizontal(bool value)
            {
                this._flipHorizontal = value;
            }
        }

        @property
        {
            /++
                Sprite map on which the animation is based
             +/
            SpriteMap spriteMap()
            {
                return this._spriteMap;
            }
        }
    }

    /++
        ctor
     +/
    public this(SpriteMap spriteMap)
    {
        this._spriteMap = spriteMap;
    }

    public
    {
        override void draw()
        {
            if (this._flipHorizontal)
            {
                darealNVGContext.save();
                darealNVGContext.scale(-1, 1);
                darealNVGContext.translate(((this._position.x * -2) - this._spriteMap._frameSize.width),
                        0);
                this._spriteMap.draw();
                darealNVGContext.restore();
            }
            else
            {
                this._spriteMap.draw();
            }
        }

        /++
            Moves to the next animation frame
         +/
        void nextAnimationFrame()
        {
            this._spriteMap.nextFrame();
        }

        /++
            Resets the animation to its first frame
         +/
        void reset()
        {
            this._spriteMap.currentSprite = Point(0, 0);
        }
    }
}

/++
    Animation that implements IClocked
 +/
class ClockedAnimation : Animation, IClocked
{
    /++
        ctor
     +/
    public this(SpriteMap spriteMap)
    {
        super(spriteMap);
    }

    public
    {
        /++
            Moves to the next animation frame
         +/
        void nextTick()
        {
            this.nextAnimationFrame();
        }
    }
}
