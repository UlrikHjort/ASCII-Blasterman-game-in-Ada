-- ***************************************************************************
--                    Blasterman - Renderer
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
with Game_Types;   use Game_Types;
with Map;
with Terminal;

package body Renderer is

   type Display_Cell is
     (D_Empty, D_Wall, D_Soft, D_Flame,
      D_Bomb, D_Powerup_R, D_Powerup_B, D_Enemy, D_Player);

   type Display_Grid is array (Row_Type, Col_Type) of Display_Cell;

   procedure Draw (State : Game.Game_State) is
      Grid : Display_Grid;
   begin
      Terminal.Move_To_Home;

      --  Base layer: map tiles
      for R in Row_Type loop
         for C in Col_Type loop
            case Map.Tile_At (State.M, (Col => C, Row => R)) is
               when Wall  => Grid (R, C) := D_Wall;
               when Soft  => Grid (R, C) := D_Soft;
               when Empty => Grid (R, C) := D_Empty;
               when Flame => Grid (R, C) := D_Flame;
            end case;
         end loop;
      end loop;

      --  Overlay: power-ups (only on empty tiles so flames take priority)
      for I in State.Powerups'Range loop
         if State.Powerups (I).Active then
            declare
               P : constant Position := State.Powerups (I).Pos;
            begin
               if Grid (P.Row, P.Col) = D_Empty then
                  Grid (P.Row, P.Col) :=
                    (if State.Powerups (I).Kind = Range_Up
                     then D_Powerup_R else D_Powerup_B);
               end if;
            end;
         end if;
      end loop;

      --  Overlay: live bombs
      for I in State.Bombs'Range loop
         if State.Bombs (I).Active then
            declare
               P : constant Position := State.Bombs (I).Pos;
            begin
               Grid (P.Row, P.Col) := D_Bomb;
            end;
         end if;
      end loop;

      --  Overlay: enemies
      for I in State.Enemies'Range loop
         if State.Enemies (I).Alive then
            declare
               P : constant Position := State.Enemies (I).Pos;
            begin
               Grid (P.Row, P.Col) := D_Enemy;
            end;
         end if;
      end loop;

      --  Overlay: player (blink every 4 ticks when invincible)
      if State.Player.Invincible = 0
         or else (State.Player.Invincible mod 4) < 2
      then
         Grid (State.Player.Pos.Row, State.Player.Pos.Col) := D_Player;
      end if;

      --  Render grid
      for R in Row_Type loop
         for C in Col_Type loop
            case Grid (R, C) is
               when D_Wall =>
                  Terminal.Set_Color (Terminal.Fg_White, Bold => True);
                  Put ('#');
               when D_Soft =>
                  Terminal.Set_Color (Terminal.Fg_Yellow);
                  Put ('+');
               when D_Empty =>
                  Terminal.Reset_Color;
                  Put (' ');
               when D_Flame =>
                  Terminal.Set_Color (Terminal.Fg_Red, Bold => True);
                  Put ('*');
               when D_Bomb =>
                  Terminal.Set_Color (Terminal.Fg_Cyan, Bold => True);
                  Put ('O');
               when D_Powerup_R =>
                  Terminal.Set_Color (Terminal.Fg_Magenta, Bold => True);
                  Put ('R');  --  Range power-up
               when D_Powerup_B =>
                  Terminal.Set_Color (Terminal.Fg_Magenta, Bold => True);
                  Put ('B');  --  extra Bomb power-up
               when D_Enemy =>
                  Terminal.Set_Color (Terminal.Fg_Red, Bold => True);
                  Put ('E');
               when D_Player =>
                  Terminal.Set_Color (Terminal.Fg_Green, Bold => True);
                  Put ('@');
            end case;
         end loop;
         Terminal.Reset_Color;
         New_Line;
      end loop;

      --  HUD line 1: lives, score, stats
      Terminal.Reset_Color;
      Put ("Lives:");
      Terminal.Set_Color (Terminal.Fg_Red, Bold => True);
      for L in 1 .. State.Player.Lives loop
         Put ('@');
      end loop;
      Terminal.Reset_Color;
      Put ("  Score:");
      Terminal.Set_Color (Terminal.Fg_Yellow, Bold => True);
      Put (Natural'Image (State.Player.Score));
      Terminal.Reset_Color;
      Put ("  Rng:");
      Put (Positive'Image (State.Player.Bomb_Range));
      Put ("  Bombs:");
      Put (Positive'Image (State.Player.Max_Bombs));
      Put ("            ");  --  clear any trailing chars from previous frame
      New_Line;

      --  HUD line 2: controls / status
      Terminal.Reset_Color;
      case State.Status is
         when Game.Playing =>
            Put ("WASD/Arrows:Move  Space:Bomb  Q:Quit          ");
         when Game.Won =>
            Terminal.Set_Color (Terminal.Fg_Green, Bold => True);
            Put ("*** YOU WIN!  Press R to restart, Q to quit ***");
            Terminal.Reset_Color;
         when Game.Lost =>
            Terminal.Set_Color (Terminal.Fg_Red, Bold => True);
            Put ("*** GAME OVER! Press R to restart, Q to quit **");
            Terminal.Reset_Color;
      end case;
      New_Line;

      Flush;
   end Draw;

end Renderer;
