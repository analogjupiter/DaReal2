/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.layereddrawing;

import std.algorithm.mutation : remove;
import std.algorithm.searching : canFind;

import dareal.legacy.graphics : darealNVGContext;
import dareal.legacy.interfaces;
import tinyevent;

/++
    Camera-like object that provides a point of view
 +/
final class Camera
{
    alias CameraOffsetChangedEvent = Event!(Camera, Point);

    private
    {
        CameraOffsetChangedEvent _cameraOffsetChanged;
        Point _position;
    }

    public
    {
        @property
        {
            /++
                Event that triggers when the camera's offset changes
             +/
            ref CameraOffsetChangedEvent cameraOffsetChanged()
            {
                return this._cameraOffsetChanged;
            }
        }

        @property
        {
            /++
                Camera position offset (top left corner)
             +/
            Point position()
            {
                return this._position;
            }

            /++ ditto +/
            void position(Point value)
            {
                auto old = this._position;
                this._position = value;
                this.cameraOffsetChanged.emit(this, old);
            }
        }
    }
}

private final class CameraLockHelper
{
    private static
    {
        CameraLockHelper _instance;
    }

    private this()
    {
    }

    public static @property CameraLockHelper instance()
    {
        if (this._instance is null)
        {
            this._instance = new CameraLockHelper();
        }

        return this._instance;
    }

    public void lockX(Camera c, Point old)
    {
        c._position.x = old.x;
    }

    public void lockY(Camera c, Point old)
    {
        c._position.y = old.y;
    }
}

/++
    Locks a camera to its current height
 +/
void lockCameraY(Camera c)
in
{
    assert(!c.cameraOffsetChanged.canFind(&CameraLockHelper.instance.lockY),
            "camera is already height-locked");
}
do
{
    c._cameraOffsetChanged = &CameraLockHelper.instance.lockY ~ c._cameraOffsetChanged;
}

/++
    Relocks a camera's height setting to a new y value
 +/
void relockCameraY(Camera c, int newY)
in
{
    assert(c.cameraOffsetChanged.canFind(&CameraLockHelper.instance.lockY));
}
do
{
    c._position.y = newY;
}

/++
    Unlocks a camera's height setting
 +/
void unlockCameraY(Camera c)
in
{
    assert(c.cameraOffsetChanged.canFind(&CameraLockHelper.instance.lockY));
}
do
{
    c._cameraOffsetChanged.remove!(q => (q == &CameraLockHelper.instance.lockY));
}

/++
    Locks a camera to its current x position
 +/
void lockCameraX(Camera c)
in
{
    assert(!c.cameraOffsetChanged.canFind(&CameraLockHelper.instance.lockX),
            "camera is already height-locked");
}
do
{
    c._cameraOffsetChanged = &CameraLockHelper.instance.lockX ~ c._cameraOffsetChanged;
}

/++
    Relocks a camera's height setting to a new y value
 +/
void relockCameraX(Camera c, int newX)
in
{
    assert(c.cameraOffsetChanged.canFind(&CameraLockHelper.instance.lockX));
}
do
{
    c._position.x = newX;
}

/++
    Unlocks a camera's x-position
 +/
void unlockCameraX(Camera c)
in
{
    assert(c.cameraOffsetChanged.canFind(&CameraLockHelper.instance.lockY));
}
do
{
    c._cameraOffsetChanged.remove!(q => (q == &CameraLockHelper.instance.lockX));
}

/++
    A layer of the whole view

    Basically a collection of drawings that can be drawn itself.
 +/
final class Layer : IDrawable
{
    private
    {
        IDrawable[] _drawings;
    }

    public alias _drawings this;

    public
    {
        /++
            Draws the layer
            by drawing all drawings on it
         +/
        void draw()
        {
            foreach (IDrawable d; this._drawings)
            {
                d.draw();
            }
        }
    }
}

/++
    View managing class

    Usually used with layers
 +/
final class View : IDrawable
{
    private
    {
        Camera _camera = new Camera();

        IDrawable _background;
        IDrawable _HUD;
        IDrawable[] _layers;
    }

    public
    {
        @property
        {
            /++
                Background layer

                Independent from camera
             +/
            IDrawable background()
            {
                return this._HUD;
            }

            /++ ditto +/
            void background(IDrawable value)
            {
                this._background = value;
            }
        }

        @property
        {
            /++
                Camera representing the point of view
             +/
            Camera camera()
            {
                return this._camera;
            }

            /++ ditto +/
            void camera(Camera value)
            {
                this._camera = value;
            }
        }

        @property
        {
            /++
                HUD layer

                Independent from camera
             +/
            IDrawable HUD()
            {
                return this._HUD;
            }

            /++ ditto +/
            void HUD(IDrawable value)
            {
                this._HUD = value;
            }
        }

        @property
        {
            /++
                Main layers

                Viewed by camera
             +/
            ref IDrawable[] layers()
            {
                return this._layers;
            }
        }
    }

    public
    {
        /++
            Draws to whole view
         +/
        void draw()
        {
            import arsd.nanovega : translate;

            // Draw background first
            if (this._background !is null)
            {
                this._background.draw();
            }

            // Translate to camera position
            darealNVGContext.translate(this._camera.position.x, this._camera.position.y);

            foreach (IDrawable l; this._layers)
            {
                l.draw();
            }

            darealNVGContext.translate(-this._camera.position.x, -this._camera.position.y);

            // Finally, draw HUD
            if (this._HUD !is null)
            {
                this._HUD.draw();
            }
        }
    }
}
