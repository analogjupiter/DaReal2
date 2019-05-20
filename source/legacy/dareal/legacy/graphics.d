/+
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

public import arsd.nanovega : createImage;

/++
    Initializes dareal.legacy.graphics

    This must be called before anything else of dareal.legacy.graphics!
 +/
NVGContext darealInit()
{
    _darealNVGContext = nvgCreateContext();
    return _darealNVGContext;
}

/++ ditto +/
void darealInit(NVGContext context)
{
    _darealNVGContext = context;
}

public
{
    alias Context = NVGContext;
    alias Color = NVGColor;
    alias Image = NVGImage;
    alias Paint = NVGPaint;
}

__gshared private
{
    Context _darealNVGContext;
}

/++
    DaReal's drawing context

    Use daRealInit to supply one.

    See_Also:
        darealInit()
 +/
Context darealNVGContext()
{
    return _darealNVGContext;
}

/++
    Drawing angle
 +/
enum float fullDrawingAngle = 0;

/++
    Simplified image drawing function
 +/
void drawImage(Paint image, Point position, Size size)
{
    darealNVGContext.beginPath();
    darealNVGContext.rect(position.x, position.y, size.width, size.height);
    darealNVGContext.fillPaint = image;
    darealNVGContext.fill();
}

/++
    Picture
 +/
deprecated("Wouldn't use that anymore. dareal.legacy also got rid of it :) ") class Picture
    : IDrawable
{
    private
    {
        Image _image = void;
        Paint _paint = void;
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
                Flip the drawing horizontally?
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
        void drawHelperFlipHorizontally(int width, void delegate() doDrawing)
        {
            if (this._flipHorizontally)
            {
                darealNVGContext.save();
                darealNVGContext.scale(-1, 1);
                darealNVGContext.translate(-((this.position.x * 2) + width), 0);
                doDrawing();
                darealNVGContext.restore();
            }
            else
            {
                doDrawing();
            }
        }
    }
}

/++
    SpriteMap
 +/
final class SpriteMap : PositionedDrawing
{
    private
    {
        Point _currentSprite;
        Size _frameSize = void;
        Image _spriteSheet = void;
        Paint _paint = void;
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
                enum msg = "invalid frame selection";
                assert(value.x < (this._spriteSheet.width / this._frameSize.width), msg ~ " (x)");
                assert(value.y < (this._spriteSheet.height / this._frameSize.height), msg ~ " (y)");
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
                enum msg = "bad frameSize";
                assert(this._spriteSheet.width % value.width == 0, msg ~ " (width)");
                assert(this._spriteSheet.height % value.height == 0, msg ~ " (height)");
            }
            do
            {
                this._frameSize = value;
                this.updatePaint();
            }
        }

        override @property
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
    public this(Image spriteSheet, Point position = Point(0, 0))
    {
        this._position = position;
        this._spriteSheet = spriteSheet;
        this.frameSize = Size(spriteSheet.width, spriteSheet.height);
    }

    /++
        ctor
     +/
    public this(Image spriteSheet, Size frameSize, Point position = Point(0, 0))
    {
        this._position = position;
        this._spriteSheet = spriteSheet;
        this.frameSize = frameSize;
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
        out
        {
            enum msg = "moved to bad sprite sheet frame";
            assert((this._currentSprite.x * this._frameSize.width) <= this._spriteSheet.width, msg);
            assert((this._currentSprite.y * this._frameSize.height) <= this._spriteSheet.height,
                    msg);
        }
        do
        {
            // Row end?
            if (((this._currentSprite.x + 1) * this._frameSize.width) >= this._spriteSheet.width)
            {
                this._currentSprite.x = 0;
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

    private
    {
        void updatePaint()
        {
            this._paint = darealNVGContext.imagePattern(
                    ((this._currentSprite.x * this._frameSize.width * -1) + this._position.x),
                    ((this._currentSprite.y * this._frameSize.height * -1) + this._position.y),
                    this._spriteSheet.width, this._spriteSheet.height,
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

        override @property
        {
            Point position()
            {
                return this._spriteMap.position;
            }

            void position(Point value)
            {
                this._spriteMap.position = value;
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

        /++ ditto +/
        alias nextFrame = nextAnimationFrame;

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
                assert(a, "cannot activate unknow animation");
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
                assert((name in this._animations) == null, "animation name is already in use");
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
                assert(name in this._animations, "cannot remove unknown animation");
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
                assert(0, "cannot remove unknown animation");
            }
        }
    }
}

/++
    Multi-animation software sprite
 +/
class Sprite : MultiAnimationDrawing
{
    public
    {
        @property
        {
            /++
                Size of the drawn sprite
             +/
            Size size()
            {
                return this._currentAnimation.spriteMap.frameSize;
            }
        }
    }

    /++
        ctor
     +/
    public this(Animation defaultAnimation, string defaultAnimationName = defaultAnimationName)
    {
        super(defaultAnimation, defaultAnimationName);
    }

    /++
        convenience ctor
     +/
    public this(SpriteMap spriteMap, string defaultAnimationName = defaultAnimationName)
    {
        this(new Animation(spriteMap), defaultAnimationName);
    }
}

/++
    Decorator for drawings that can be hidden
 +/
final class OptionallyInvisibleDrawing : IDrawable
{
    private
    {
        bool _invisible = void;
        IDrawable _drawing = void;
    }

    public
    {
        @property
        {
            /++
                Is the drawing hidden?
             +/
            bool invisible()
            {
                return this._invisible;
            }

            /++ ditto +/
            void invisible(bool value)
            {
                this._invisible = value;
            }
        }

        @property
        {
            /++
                Is the drawing visible?
             +/
            bool visible()
            {
                return (!this._invisible);
            }

            /++ ditto +/
            void visible(bool value)
            {
                this._invisible = (!value);
            }
        }
    }

    /++
        ctor
     +/
    public this(IDrawable drawing, bool invisible = true)
    {
        this._drawing = drawing;
        this._invisible = invisible;
    }

    public
    {
        /++
            Toggles visibility state
         +/
        void toggleVisibility()
        {
            this._invisible = (!this._invisible);
        }

        /++
            Draws the decorated drawing if not invisible
         +/
        void draw()
        {
            if (this._invisible)
            {
                return;
            }

            this._drawing.draw();
        }
    }
}

/++
    Font face wrapper
 +/
final class FontFace
{
    /++
        Font face ID
     +/
    int id;

    /++
        Friendly alias name
     +/
    string aliasName;

    /++
        ctor for loading new fonts
     +/
    this(string aliasName, string ttfPath)
    out
    {
        assert(this.id != FONS_INVALID, "Failed to load font `" ~ ttfPath ~ "`");
    }
    do
    {
        this.aliasName = aliasName;
        this.id = darealNVGContext.createFont(aliasName, ttfPath);
    }

    /++
        ctor for already loaded fonts
     +/
    this(int fontFaceID, string aliasName)
    in
    {
        assert(fontFaceID != FONS_INVALID);
    }
    do
    {
        this.id = fontFaceID;
        this.aliasName = aliasName;
    }

    /++
        ctor for already loaded fonts
     +/
    this(int fontFaceID)
    in
    {
        assert(fontFaceID != FONS_INVALID);
    }
    do
    {
        this.id = fontFaceID;
    }
}

/++
    Drawable text
 +/
final class Text(bool multilineBlock) : PositionedDrawing
{
    private
    {
        Color _color;
        FontFace _fontFace;
        float _fontSize;
        string _text;
    }

    public
    {
        @property
        {
            /++
                Text color
             +/
            Color color()
            {
                return this._color;
            }

            /++ ditto +/
            void color(Color value)
            {
                this._color = value;
            }
        }

        @property
        {
            /++
                Font face to use
             +/
            FontFace fontFace()
            {
                return this._fontFace;
            }

            /++ ditto +/
            void fontFace(FontFace value)
            {
                this._fontFace = value;
            }
        }

        @property
        {
            /++
                Display size of text
             +/
            float fontSize()
            {
                return this._fontSize;
            }

            /++ ditto +/
            void fontSize(float value)
            {
                this.fontSize = value;
            }
        }

        @property
        {
            /++
                Text to display
             +/
            string text()
            {
                return this._text;
            }

            /++ ditto +/
            void text(string value)
            {
                this._text = value;
            }
        }
    }

    static if (multilineBlock)
    {
        /++
            multi-line text ctor
         +/
        public this(string text, FontFace fontFace, float fontSize, Color color,
                float lineWidth, Point position)
        {
            this._text = text;
            this._fontFace = fontFace;
            this._fontSize = fontSize;
            this._color = color;
            this._lineWidth = lineWidth;
            this._position = position;
        }

        private float _lineWidth;

        public @property
        {
            /++
                Max width of a text line
             +/
            float lineWidth()
            {
                return this._lineWidth;
            }

            /++ ditto +/
            void lineWidth(float value)
            {
                this._lineWidth = value;
            }
        }

    }
    else
    {
        /++
            single-line text ctor
         +/
        public this(string text, FontFace fontFace, float fontSize, Color color, Point position)
        {
            this._text = text;
            this._fontFace = fontFace;
            this._fontSize = fontSize;
            this._color = color;
            this._position = position;
        }
    }

    public override
    {
        void draw()
        {
            darealNVGContext.fillColor = this._color;
            darealNVGContext.fontFaceId = this._fontFace.id;
            darealNVGContext.fontSize = this._fontSize;

            static if (multilineBlock)
            {
                darealNVGContext.textBox(this._position.x, this._position.y,
                        this._lineWidth, this._text);
            }
            else
            {
                darealNVGContext.text(this._position.x, this._position.y, this._text);
            }
        }
    }
}

public
{
    /++
        Single-line text
     +/
    alias TextLine = Text!false;

    /++
        Multi-line text
     +/
    alias TextBlock = Text!true;
}

/++
    Simple rectangle shape
 +/
final class Rectangle : PositionedDrawing
{
    private
    {
        Color _color;
        Size _size;
    }

    public
    {
        @property
        {
            /++
                Background color
             +/
            Color color()
            {
                return this._color;
            }

            /++ ditto +/
            void color(Color value)
            {
                this._color = value;
            }
        }

        @property
        {
            /++
                Size of the rectangle
             +/
            Size size()
            {
                return this._size;
            }

            /++ ditto +/
            void size(Size value)
            {
                this._size = value;
            }
        }
    }

    /++
        ctor
     +/
    public this(Color color, Point position, Size size)
    {
        this._color = color;
        this._size = size;
        this._position = position;
    }

    public override
    {
        void draw()
        {
            darealNVGContext.beginPath();
            darealNVGContext.rect(this.position.x, this.position.y,
                    this.size.width, this.size.height);
            darealNVGContext.fillColor = this._color;
            darealNVGContext.fill();
        }
    }
}
