/++
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.graphics;

import std.math : PI;

import arsd.nanovega;
import dareal.legacy.math;
import dareal.legacy.interfaces;
import tinyevent;

/++
    DaReal's drawing context

    Use daRealInit to supply your own context.

    See_Also:
        darealInit()
 +/
__gshared NVGContext darealNVGContext;

/++
    Drawing angle 180/PI
 +/
enum fullDrawingAngle = (180 / PI);

/++
    Specify a custom drawing context

    This must be called before anything else.
 +/
void darealInit(NVGContext context)
{
    darealNVGContext = context;
}

/++
    Camera-like object that provides the point of view
 +/
public class Camera
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
public class Picture : IDrawable
{
    private
    {
        NVGImage _image;
        NVGPaint _paint;
    }

    public
    {
        @property
        {
            /++
                Internal image
             +/
            NVGImage image()
            {
                return this._image;
            }

            /++ ditto +/
            void image(NVGImage value)
            {
                this._image = value;
                this._paint = imagePattern(this._image, this.naturalSize.width,
                        this.naturalSize.height, 0f, fullDrawingAngle, this._image);

            }

            /++
                Paint created of the stored image
             +/
            NVGPaint paint()
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
    public this(NVGImage image)
    {
        this._image = image;
    }

    /++ ditto +/
    public this(string file)
    {
        if ((this._image = createImage(darealNVGContext, file)) == NVGImage.init)
        {
            throw new Exception("Loading of image failed: " ~ file);
        }
    }

    ~this()
    {
        deleteImage(darealNVGContext, this._image);
    }

    public
    {
        void draw(NVGContext ctx)
        {
            ctx.beginPath();
            ctx.rect(0, 0, this.naturalSize.width, this.naturalSize.height);
            ctx.fillPaint = this._paint;
        }
    }
}
