#NoEnv

/*
Copyright 2012 Anthony Zhang <azhang9@gmail.com>

This file is part of Canvas-AHK. Source code is available at <https://github.com/Uberi/Canvas-AHK>.

Canvas-AHK is free software: you can redistribute it and/or modify
it under the terms of the GNU Affero General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU Affero General Public License for more details.

You should have received a copy of the GNU Affero General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

;wip: combine the draw* and fill* functions: DrawPie(Pen) and FillPie(Brush) -> Pie(Pen) and Pie(Brush)
;wip: fold pens into brushes; allow brushes to define widths, fills, etc.
;wip: finish surface API as per http://msdn.microsoft.com/en-us/library/windows/desktop/ms534038(v=vs.85).aspx
;wip: add hatch brush, texture brush, and linear/radial gradient brush capabilities to Brush class
;wip: use CachedBitmap for animations: http://msdn.microsoft.com/en-us/library/ms533975(v=vs.85).aspx
;wip: see methods here: http://www.w3schools.com/html5/html5_ref_canvas.asp
;wip: automatically scale surface to viewport

#Warn All
#Warn LocalSameAsGlobal, Off

Gui, +LastFound

s := new Canvas.Surface(200,200)

v := new Canvas.Viewport(WinExist())
v.Attach(s)

s.Clear(0xFFFFFF00)

p := new Canvas.Pen(0x80FF0000,10)
t := new Canvas.Pen(0xFF00FF00,3)
b := new Canvas.Brush(0xAA0000FF)

s.FillRectangle(b,50,50,50,50)
 .DrawEllipse(p,70,70,100,100)
 .DrawCurve(t,[[10,10],[50,10],[10,50]],True)

Gui, Show, w200 h200, Canvas Demo
Return

GuiClose:
ExitApp

Space::
s.FillPie(b,100,100,50,50,0,270)
v.Refresh()
Return

class Canvas
{
    static _ := Canvas.Initialize()

    Initialize()
    {
        this.hModule := DllCall("LoadLibrary","Str","gdiplus","UPtr")

        ;initialize the GDI+ library
        VarSetCapacity(StartupInformation,A_PtrSize + 12)
        NumPut(1,StartupInformation,0,"UInt") ;GDI+ version (version 1)
        NumPut(0,StartupInformation,4) ;debug callback (disabled)
        NumPut(0,StartupInformation,A_PtrSize + 4) ;suppress background thread (disabled)
        NumPut(0,StartupInformation,A_PtrSize + 8) ;suppress external image codecs (disabled)
        Token := 0, Result := DllCall("gdiplus\GdiplusStartup","UPtr*",Token,"UPtr",&StartupInformation,"UPtr",0)
        If Result != 0 ;Status.Ok
            throw Exception("INTERNAL_ERROR",A_ThisFunc,"Could not initialize the GDI+ library (GDI+ error " . Result . ").")
        this.Token := Token
    }

    __Delete()
    {
        ;shut down the GDI+ library
        DllCall("gdiplus\GdiplusShutdown","UPtr",this.Token)
    }

    #Include Viewport.ahk
    #Include Surface.ahk
    #Include Pen.ahk
    #Include Brush.ahk
}