-- ***************************************************************************
--                       Blasterman - Main
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
with Ada.Text_IO;  use Ada.Text_IO;
with Ada.Exceptions;
with Terminal;
with Game;         use Game;
with Renderer;

procedure Main is
   State : Game.Game_State;
   Key   : Integer;
begin
   Terminal.Set_Raw;
   Terminal.Hide_Cursor;
   Terminal.Clear_Screen;

   Game.Init (State);
   Renderer.Draw (State);

   loop
      Key := Terminal.Get_Key;

      if Key = Character'Pos ('q') or else Key = Character'Pos ('Q') then
         exit;
      end if;

      if Key = Character'Pos ('r') or else Key = Character'Pos ('R') then
         if State.Status /= Game.Playing then
            Game.Init (State);
            Terminal.Clear_Screen;
         end if;
      end if;

      Game.Process_Input (State, Key);
      Game.Update (State);
      Renderer.Draw (State);

      delay 0.067;  --  ~15 fps
   end loop;

   Terminal.Show_Cursor;
   Terminal.Restore;
   Terminal.Clear_Screen;
   Put_Line ("Thanks for playing Blasterman!");

exception
   when E : others =>
      Terminal.Show_Cursor;
      Terminal.Restore;
      New_Line;
      Put_Line ("Fatal: " & Ada.Exceptions.Exception_Message (E));
end Main;
