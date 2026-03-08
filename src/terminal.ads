-- ***************************************************************************
--                       Blasterman - Terminal         
--
--               Copyright (C) 2026 By Ulrik Hørlyk Hjort
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the
-- "Software"), to deal in the Software without restriction, including
-- without limitation the rights to use, copy, modify, merge, publish,
-- distribute, sublicense, and/or sell copies of the Software, and to
-- permit persons to whom the Software is furnished to do so, subject to
-- the following conditions:
--
-- The above copyright notice and this permission notice shall be
-- included in all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
-- EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
-- MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
-- NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
-- LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
-- OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
-- WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
-- ***************************************************************************           
package Terminal is

   --  Synthetic key codes for multi-byte sequences
   Key_None  : constant Integer := -1;
   Key_Up    : constant Integer := 1000;
   Key_Down  : constant Integer := 1001;
   Key_Right : constant Integer := 1002;
   Key_Left  : constant Integer := 1003;

   procedure Set_Raw;
   procedure Restore;

   --  Non-blocking; assembles ESC sequences for arrow keys.
   --  Returns Key_None when no input is pending.
   function Get_Key return Integer;

   procedure Clear_Screen;
   procedure Move_To_Home;
   procedure Hide_Cursor;
   procedure Show_Cursor;

   --  Emit ANSI SGR color / reset
   procedure Set_Color (Fg : Natural; Bold : Boolean := False);
   procedure Reset_Color;

   --  ANSI foreground color constants
   Fg_Black   : constant Natural := 30;
   Fg_Red     : constant Natural := 31;
   Fg_Green   : constant Natural := 32;
   Fg_Yellow  : constant Natural := 33;
   Fg_Blue    : constant Natural := 34;
   Fg_Magenta : constant Natural := 35;
   Fg_Cyan    : constant Natural := 36;
   Fg_White   : constant Natural := 37;

end Terminal;
