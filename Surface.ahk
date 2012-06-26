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

class Surface
{
    __New(Width,Height)
    {
        If Width Is Not Integer
            throw Exception("Invalid width: " . Width,-1)
        If Height Is Not Integer
            throw Exception("Invalid height: " . Height,-1)

        this.Width := Width
        this.Height := Height

        ;create a memory device context for double buffering use
        this.hMemoryDC := DllCall("CreateCompatibleDC","UPtr",0,"UPtr")
        If !this.hMemoryDC
            throw Exception("Could not create memory device context.")

        ;set up BITMAPINFO structure
        VarSetCapacity(BitmapInfo,40)
        NumPut(40,BitmapInfo,0,"UInt") ;structure size
        NumPut(Width,BitmapInfo,4,"UInt") ;bitmap width
        NumPut(Height,BitmapInfo,8,"UInt") ;bitmap height
        NumPut(1,BitmapInfo,12,"UShort") ;target device plane count
        NumPut(32,BitmapInfo,14,"UInt") ;bits per pixel
        NumPut(0,BitmapInfo,16,"UInt") ;BI_RGB: compression type
        NumPut(0,BitmapInfo,20,"UInt") ;image size
        NumPut(0,BitmapInfo,24,"UInt") ;horizontal resolution of target device
        NumPut(0,BitmapInfo,28,"UInt") ;vertical resolution of target device
        NumPut(0,BitmapInfo,32,"UInt") ;color index used count
        NumPut(0,BitmapInfo,36,"UInt") ;color index required count

        ;create the device independent bitmap
        pBits := 0
        this.hBitmap := DllCall("CreateDIBSection","UPtr",0,"UPtr",&BitmapInfo,"UInt",0,"UPtr*",pBits,"UPtr",0,"UInt",0) ;DIB_RGB_COLORS
        If !this.hBitmap
            throw Exception("Could not create bitmap.")

        ;select the bitmap into the memory device context
        this.hOriginalBitmap := DllCall("SelectObject","UPtr",this.hMemoryDC,"UPtr",this.hBitmap,"UPtr")
        If !this.hOriginalBitmap
            throw Exception("Could not select bitmap into memory device context.")

        ;create a graphics object
        pGraphics := 0, Result := DllCall("gdiplus\GdipCreateFromHDC","UPtr",this.hMemoryDC,"UPtr*",pGraphics)
        If Result != 0 ;Status.Ok
            throw Exception("Could not create graphics object from memory device context (GDI+ error " . Result . ").")
        this.pGraphics := pGraphics

        ;wip: set smoothing mode and other modifiable properties as listed here: http://msdn.microsoft.com/en-us/library/windows/desktop/ms534038(v=vs.85).aspx
    }

    __Delete()
    {
        ;delete the graphics object
        Result := DllCall("gdiplus\GdipDeleteGraphics","UPtr",this.pGraphics)
        If (Result != 0 && !e) ;Status.Ok
            e := Exception("Could not delete graphics object (GDI+ error " . Result . ").")

        ;deselect the bitmap if present
        If !DllCall("SelectObject","UPtr",this.hMemoryDC,"UPtr",this.hOriginalBitmap,"UPtr")
            throw Exception("Could not deselect bitmap from memory device context.")

        ;delete the bitmap
        If !DllCall("DeleteObject","UPtr",this.hBitmap)
            throw Exception("Could not delete bitmap.")

        ;delete the memory device context
        If !DllCall("DeleteDC","UPtr",this.hMemoryDC)
            throw Exception("Could not delete memory device context.")
    }

    Clear(Color = 0x00000000)
    {
        If Color Is Not Integer
            throw Exception("Invalid color: " . Color . ".",-1)
        Result := DllCall("gdiplus\GdipGraphicsClear","UPtr",this.pGraphics,"UInt",Color)
        If Result != 0 ;Status.Ok
            throw Exception("Could not clear graphics (GDI+ error " . Result . ").")
    }

    DrawLine(Pen,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipDrawLine","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"FLoat",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw line (GDI+ error " . Result . ").")
    }

    DrawLines(Pen,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipDrawLines","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw lines (GDI+ error " . Result . ").")
    }

    DrawArc(Pen,X,Y,W,H,Start,Sweep)
    {
        this.CheckSector(X,Y,W,H,Start,Sweep)

        Result := DllCall("gdiplus\GdipDrawArc","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw arc (GDI+ error " . Result . ").")
    }

    DrawCurve(Pen,Points,Closed = False)
    {
        Length := this.CheckPoints(Points,PointArray)

        If Closed
            Result := DllCall("gdiplus\GdipDrawClosedCurve","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        Else
            Result := DllCall("gdiplus\GdipDrawCurve","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw curve (GDI+ error " . Result . ").")
    }

    DrawEllipse(Pen,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipDrawEllipse","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw ellipse (GDI+ error " . Result . ").")
    }

    DrawPie(Pen,X,Y,W,H,Start,Sweep)
    {
        this.CheckSector(X,Y,W,H,Start,Sweep)

        Result := DllCall("gdiplus\GdipDrawPie","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw pie (GDI+ error " . Result . ").")
    }

    DrawPolygon(Pen,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipDrawPolygon","UPtr",this.pGraphics,"UPtr",Pen.pPen,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw polygon (GDI+ error " . Result . ").")
    }

    DrawRectangle(Pen,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipDrawRectangle","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("Could not draw rectangle (GDI+ error " . Result . ").")
    }

    FillCurve(Brush,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipFillClosedCurve","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("Could not fill curve (GDI+ error " . Result . ").")
    }

    FillEllipse(Brush,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipFillEllipse","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("Could not fill ellipse (GDI+ error " . Result . ").")
    }

    FillPie(Brush,X,Y,W,H,Start,Sweep)
    {
        this.CheckSector(X,Y,W,H,Start,Sweep)

        Result := DllCall("gdiplus\GdipFillPie","UPtr",this.pGraphics,"UPtr",Pen.pPen,"Float",X,"Float",Y,"Float",W,"Float",H,"Float",Start - 90,"Float",Sweep)
        If Result != 0 ;Status.Ok
            throw Exception("Could not fill pie (GDI+ error " . Result . ").")
    }

    FillPolygon(Brush,Points)
    {
        Length := this.CheckPoints(Points,PointArray)

        Result := DllCall("gdiplus\GdipFillPolygon","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"UPtr",&PointArray,"Int",Length)
        If Result != 0 ;Status.Ok
            throw Exception("Could not fill polygon (GDI+ error " . Result . ").")
    }

    FillRectangle(Brush,X,Y,W,H)
    {
        this.CheckRectangle(X,Y,W,H)

        Result := DllCall("gdiplus\GdipFillRectangle","UPtr",this.pGraphics,"UPtr",Brush.pBrush,"Float",X,"Float",Y,"Float",W,"Float",H)
        If Result != 0 ;Status.Ok
            throw Exception("Could not fill rectangle (GDI+ error " . Result . ").")
    }

    CheckSector(X,Y,W,H,Start,Sweep)
    {
        If X Is Not Number
            throw Exception("Invalid X-axis coordinate: " . X,-2)
        If Y Is Not Number
            throw Exception("Invalid Y-axis coordinate: " . Y,-2)
        If W Is Not Number
            throw Exception("Invalid width: " . W,-2)
        If H Is Not Number
            throw Exception("Invalid height: " . H,-2)
        If Start Is Not Number
            throw Exception("Invalid start angle: " . Start,-2)
        If Sweep Is Not Number
            throw Exception("Invalid sweep angle: " . Sweep,-2)
    }

    CheckRectangle(X,Y,W,H)
    {
        If X Is Not Number
            throw Exception("Invalid X-axis coordinate: " . X,-2)
        If Y Is Not Number
            throw Exception("Invalid Y-axis coordinate: " . Y,-2)
        If W Is Not Number
            throw Exception("Invalid width: " . W,-2)
        If H Is Not Number
            throw Exception("Invalid height: " . H,-2)
    }

    CheckPoints(Points,ByRef PointArray)
    {
        Length := Points.MaxIndex()
        If !Length
            throw Exception("Invalid point set: " . Points,-2)
        VarSetCapacity(PointArray,Length << 3)
        Offset := 0
        Loop, %Length%
        {
            Point := Points[A_Index]
            If !IsObject(Point)
                throw Exception("Invalid point: " . Point,-2)
            PointX := Point[1]
            PointY := Point[2]
            If PointX Is Not Number
                throw Exception("Invalid X-axis coordinate: " . PointX,-2)
            If PointY Is Not Number
                throw Exception("Invalid X-axis coordinate: " . PointX,-2)

            NumPut(PointX,PointArray,Offset,"Float"), Offset += 4
            NumPut(PointY,PointArray,Offset,"Float"), Offset += 4
        }
        Return, Length
    }
}