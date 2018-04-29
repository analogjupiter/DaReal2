/++
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.graphics;

import std.algorithm.searching : canFind;
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
    Base class for drawings with a specific position
 +/
abstract class PositionedDrawing : IDrawable, IPositioned
{
    private
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
            Draws the object at its position

            See_Also:
                position
         +/
        abstract void draw();
    }
}

/++
    Base class for horizontally flippable drawings with a specific position
 +/
abstract class HorizontallyFlippablePositionedDrawing : PositionedDrawing
{
    private
    {
        bool _flipHorizontally;
    }

    public
    {
        @property
        {
            /++
                Flip the drawing horizontal?
             +/
            bool flipHorizontally()
            {
                return this._flipHorizontally;
            }

            /++ ditto +/
            void flipHorizontally(bool value)
            {
                this._flipHorizontally = value;
            }
        }
    }

    protected
    {
        /++
            Helper function that simplifies drawing horizontally flipped objects

            Also checks for .flipHorizontally().
         +/
        void drawHelperFlipHorizontally(int width, void function() doDrawing)
        {
            if (this.flipHorizontally)
            {
                darealNVGContext.save();
                darealNVGContext.translate(width, 0);
                darealNVGContext.scale(-1, 1);
                doDrawing();
                darealNVGContext.restore();
            }
            else
            {
                doDrawing();
            }
        }

        /++ ditto +/
        void drawHelperFlipHorizontally(int width, void delegate() doDrawing)
        {
            this.drawHelperFlipHorizontally(width, doDrawing.funcptr);
        }
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
class Animation : HorizontallyFlippablePositionedDrawing, IResetable
{
    private
    {
        SpriteMap _spriteMap;
    }

    public
    {
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
            /+if (this._flipHorizontally)
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
            }+/
            this.drawHelperFlipHorizontally(this._spriteMap.frameSize.width,
                    &this._spriteMap.draw);
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

/++
    Drawing based on multiple animations
 +/
class MultiAnimationDrawing : HorizontallyFlippablePositionedDrawing
{
    /++
        Default name of the default animation
     +/
    enum defaultAnimationName = "default";

    private
    {
        Animation[string] _animations;
        Animation _currentAnimation;
    }

    public
    {
        @property
        {
            /++
                Available animations
             +/
            auto animations()
            {
                return this._animations.byKeyValue;
            }
        }

        @property
        {
            /++
                Currently used animation
             +/
            Animation currentAnimation()
            {
                return this._currentAnimation;
            }

            /++ ditto +/
            void currentAnimation(Animation value)
            in
            {
                assert(this._animations.values.canFind(value));
            }
            do
            {
                // save old drawing data
                bool flipHorizontally = this._currentAnimation.flipHorizontally;
                Point position = this._currentAnimation.position;

                // switch animation
                this._currentAnimation = value;

                // restore/apply old drawing data
                this._currentAnimation.flipHorizontally = flipHorizontally;
                this._currentAnimation.position = position;

            }
        }

        @property
        {
            /++
                Name of the currently used animation
             +/
            string currentAnimationName()
            {
                foreach (akvp; this._animations.byKeyValue)
                {
                    if (akvp.value == this._currentAnimation)
                    {
                        return akvp.key;
                    }
                }

                // not found
                assert(0);
            }

            /++ ditto +/
            void currentAnimationName(string value)
            {
                Animation* a = (value in this._animations);
                assert(a);
                this.currentAnimation = *a;
            }
        }

        override @property
        {
            bool flipHorizontally()
            {
                return this._currentAnimation.flipHorizontally;
            }

            void flipHorizontally(bool value)
            {
                this._currentAnimation.flipHorizontally = value;
            }
        }

        override @property
        {
            Point position()
            {
                return this._currentAnimation.position;
            }

            void position(Point value)
            {
                this._currentAnimation.position = value;
            }
        }
    }

    /++
        ctor
     +/
    public this(Animation defaultAnimation, string defaultAnimationName = defaultAnimationName)
    {
        this._animations[defaultAnimationName] = defaultAnimation;
        this._currentAnimation = defaultAnimation;
    }

    public
    {
        /++
            Draws the current animation
         +/
        override void draw()
        {
            this._currentAnimation.draw();
        }

        final
        {
            /++
                Adds a new animation
             +/
            void addAnimation(string name, Animation animation)
            in
            {
                assert((name in this._animations) == null);
            }
            do
            {
                this._animations[name] = animation;
            }

            /++
                Removes the specified animation from the collection
             +/
            void removeAnimation(string name)
            in
            {
                assert(name in this._animations);
            }
            do
            {
                this._animations.remove(name);
            }

            /++ ditto +/
            void removeAnimation(Animation animation)
            {
                foreach (akvp; this._animations.byKeyValue)
                {
                    if (akvp.value == animation)
                    {
                        this.removeAnimation(akvp.key);
                    }
                }

                // not found
                assert(0);
            }
        }
    }
}
