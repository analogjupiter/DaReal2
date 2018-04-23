/++
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
module dareal.legacy.graphics;

import arsd.nanovega;
import dareal.legacy.math;
import tinyevent;

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
public class Picture
{
}