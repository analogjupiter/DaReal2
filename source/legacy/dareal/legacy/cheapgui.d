/+
    This file is part of DaReal².
    Copyright (c) 2018  0xEAB

    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
 +/
/++
    Very basic GUI components
    based on dareal.legacy.graphics

    Everything is meant to be used as-is.
    If you need something that is not possible with it, try not to hack it in and use something else instead.
    That said, this toolkit does *not* support your favorite feature for sure.

    See_Also:
        drug007/nanogui might be an alternative.
 +/
module dareal.legacy.cheapgui;

import std.conv : to;

import dareal.legacy.graphics;
import dareal.legacy.math;

/++
    Text-based menu item
 +/
struct MenuItem
{
    alias Action = void delegate();

    private
    {
        TextLine _textLine;
    }

    /++
        Action mapped to the control
     +/
    Action action;

    @property
    {
        /++
            Display text
         +/
        string label()
        {
            return this._textLine.text;
        }

        /++ ditto +/
        void label(string value)
        {
            this._textLine.text = value;
        }
    }
}

/++
    Selection menu

    This can be used e.g. for a classic main menu with a play and an exit button.
 +/
final class Menu : PositionedDrawing
{
    private
    {
        MenuItem[] _items;
        size_t _current;
        FontFace _fontFace;
        int _fontSize;
        int _itemMargin;
        Color _normal;
        Color _selected;
    }

    public
    {
        @property
        {
            /++
                The menu item selected at the moment

                See_Also:
                    .currentSelectionIndex
             +/
            MenuItem currentSelection()
            {
                return this._items[this._current];
            }
        }

        @property
        {
            /++
                The index of the MenuItem selected at the moment
             +/
            size_t currentSelectionIndex()
            {
                return this._current;
            }

            /++ ditto +/
            void currentSelectionIndex(size_t value)
            in
            {
                assert(value >= 0);
                assert(value < this._items.length);
            }
            do
            {
                this.currentSelection._textLine.color = this._normal;
                this._current = value;
                this.currentSelection._textLine.color = this._selected;
            }
        }

        @property
        {
            /++
                Color of the menu items that aren't selected
             +/
            Color fontColorNormal()
            {
                return this._normal;
            }

            /++ ditto +/
            void fontColorNormal(Color value)
            {
                this._normal = value;
                foreach (mi; this._items)
                {
                    mi._textLine.color = this._normal;
                }
                // probably faster to set the color of the selected item back to the right one
                // than to check for selection foreach item
                this.currentSelection._textLine.color = this._selected;
            }
        }

        @property
        {
            /++
                Color of the selected menu item
             +/
            Color fontColorSelection()
            {
                return this._selected;
            }

            /++ ditto +/
            void fontColorSelection(Color value)
            {
                this._selected = value;
                this.currentSelection._textLine.color = this._selected;
            }
        }

        @property
        {
            /++
                Font-face used to display the menu items
             +/
            FontFace fontFace()
            {
                return this._fontFace;
            }

            /++ ditto +/
            void fontFace(FontFace value)
            {
                this._fontFace = value;
                foreach (mi; this._items)
                {
                    mi._textLine.fontFace = this._fontFace;
                }
            }
        }

        @property
        {
            /++
                Font size of the menu items
             +/
            int fontSize()
            {
                return this._fontSize;
            }

            /++ ditto +/
            void fontSize(int value)
            {
                this._fontSize = value;
                foreach (idx, mi; this._items)
                {
                    mi._textLine.fontSize = this._fontSize;
                    mi._textLine.position = this.calcItemPosition(idx);
                }
            }
        }

        @property
        {
            /++
                Margin between the menu items
             +/
            int itemMargin()
            {
                return this._itemMargin;
            }

            /++ ditto +/
            void itemMargin(int value)
            {
                this._itemMargin = value;
                foreach (idx, mi; this._items)
                {
                    mi._textLine.position = this.calcItemPosition(idx);
                }
            }
        }

        override @property
        {
            Point position()
            {
                return super.position;
            }

            void position(Point value)
            {
                super.position = value;
                foreach (idx, mi; this._items)
                {
                    mi._textLine.position = this.calcItemPosition(idx);
                }
            }
        }
    }

    /++
        ctor
     +/
    public this(FontFace fontFace, int fontSize = 64, int itemMargin = 16,
            Color normal = Color.black, Color selected = Color.blue)
    {
        this._fontFace = fontFace;
        this._fontSize = fontSize;
        this._itemMargin = itemMargin;
        this._normal = normal;
        this._selected = selected;
    }

    public
    {
        /++
            Adds a new MenuItem
         +/
        void addItem(bool selected = false)(string label, MenuItem.Action action = null)
        {
            auto mi = MenuItem();
            mi.action = action;
            mi._textLine = new TextLine(label, this._fontFace, this._fontSize,
                    this._normal, this.calcItemPosition(this._items.length));
            this._items ~= mi;

            static if (selected)
            {
                mi._textLine.color = this._selected;
                this._current = (this._items.length - 1); // stfu
            }
        }

        /++
            Selects the next element
         +/
        void selectNext(bool up, bool circular = true)()
        in
        {
            assert(this._items.length > 0, "Cannot call selectNext() on an empty menu");
        }
        do
        {
            immutable old = this._current;
            static if (up)
            {
                if (this._current == 0)
                {
                    static if (circular)
                    {
                        this._current = (this._items.length - 1); // stfu
                    }
                    else
                    {
                        return;
                    }
                }
                else
                {
                    this._current--;
                }
            }
            else // down
            {
                if (this._current == (this._items.length - 1)) // stfu
                {
                    static if (circular)
                    {
                        this._current = 0;
                    }
                    else
                    {
                        return;
                    }
                }
                else
                {
                    this._current++;
                }
            }

            this._items[old]._textLine.color = this._normal;
            this.currentSelection._textLine.color = this._selected;
        }

        /++
            Null-check and execute the action mapped to the selected menu item
         +/
        void enter()
        {
            immutable a = this._items[this._current].action;
            if (a)
            {
                a();
            }
        }

        override void draw()
        {
            foreach (MenuItem mi; this._items)
            {
                mi._textLine.draw();
            }
        }
    }

    private
    {
        Point calcItemPosition(size_t idx)
        {
            // dfmt off
            return Point(
                this.position.x,
                this.position.y + this._fontSize + idx.to!int * (this._fontSize + this._itemMargin)
            );
            // dfmt on
        }
    }
}
