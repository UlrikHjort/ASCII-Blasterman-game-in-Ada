-- ***************************************************************************
--                       Blasterman - TErminal
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
with Ada.Text_IO; use Ada.Text_IO;
with Interfaces.C; use Interfaces.C;

package body Terminal is

   --  C bindings
   procedure C_Set_Raw;
   pragma Import (C, C_Set_Raw, "terminal_set_raw");

   procedure C_Restore;
   pragma Import (C, C_Restore, "terminal_restore");

   function C_Get_Char return int;
   pragma Import (C, C_Get_Char, "terminal_get_char");

   function C_Get_Char_Timeout (Usec : int) return int;
   pragma Import (C, C_Get_Char_Timeout, "terminal_get_char_timeout");

   ESC : constant Character := Character'Val (27);

   procedure Set_Raw is
   begin
      C_Set_Raw;
   end Set_Raw;

   procedure Restore is
   begin
      C_Restore;
   end Restore;

   function Get_Key return Integer is
      C  : constant Integer := Integer (C_Get_Char);
      C2 : Integer;
      C3 : Integer;
   begin
      if C = -1 then
         return Key_None;
      end if;
      --  Start of an ESC sequence?
      if C = 27 then
         C2 := Integer (C_Get_Char_Timeout (10_000));  --  wait 10 ms
         if C2 = 91 then  --  '['
            C3 := Integer (C_Get_Char_Timeout (10_000));
            case C3 is
               when 65 => return Key_Up;
               when 66 => return Key_Down;
               when 67 => return Key_Right;
               when 68 => return Key_Left;
               when others => null;
            end case;
         end if;
         return 27;
      end if;
      return C;
   end Get_Key;

   procedure Put_Seq (S : String) is
   begin
      Put (ESC & S);
   end Put_Seq;

   procedure Clear_Screen is
   begin
      Put_Seq ("[2J");
      Put_Seq ("[H");
   end Clear_Screen;

   procedure Move_To_Home is
   begin
      Put_Seq ("[H");
   end Move_To_Home;

   procedure Hide_Cursor is
   begin
      Put_Seq ("[?25l");
   end Hide_Cursor;

   procedure Show_Cursor is
   begin
      Put_Seq ("[?25h");
   end Show_Cursor;

   procedure Set_Color (Fg : Natural; Bold : Boolean := False) is
      S : constant String := Natural'Image (Fg);
      N : constant String := S (2 .. S'Last);  --  strip leading space
   begin
      if Bold then
         Put_Seq ("[1;" & N & "m");
      else
         Put_Seq ("[0;" & N & "m");
      end if;
   end Set_Color;

   procedure Reset_Color is
   begin
      Put_Seq ("[0m");
   end Reset_Color;

end Terminal;
