-- ***************************************************************************
--                        Blasterman - Game 
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
with Game_Types; use Game_Types;
with Map;

package Game is

   --  Array capacity constants
   Bomb_Slots    : constant := 8;
   Flame_Slots   : constant := 80;
   Enemy_Count   : constant := 4;
   Powerup_Slots : constant := 20;

   --  Timing in game ticks (~15 fps  =>  1 tick ≈ 67 ms)
   Bomb_Fuse_Ticks  : constant := 45;  --  ~3 s
   Flame_Life_Ticks : constant := 10;  --  ~0.67 s
   Enemy_Move_Ticks : constant := 8;   --  move every ~0.53 s
   Invincible_Ticks : constant := 45;  --  3 s grace after a hit

   type Game_Status is (Playing, Won, Lost);

   type Bomb_Record is record
      Pos    : Position;
      Ticks  : Natural;
      Rng    : Positive;
      Active : Boolean;
   end record;

   type Flame_Record is record
      Pos    : Position;
      Ticks  : Natural;
      Active : Boolean;
   end record;

   type Enemy_Record is record
      Pos        : Position;
      Alive      : Boolean;
      Move_Timer : Natural;
      DC         : Integer;   --  current heading delta-col
      DR         : Integer;   --  current heading delta-row
   end record;

   type Powerup_Record is record
      Pos    : Position;
      Kind   : Power_Kind;
      Active : Boolean;
   end record;

   type Player_Record is record
      Pos        : Position;
      Lives      : Natural;
      Score      : Natural;
      Bomb_Range : Positive;
      Max_Bombs  : Positive;
      Bombs_Out  : Natural;
      Invincible : Natural;  --  ticks remaining
   end record;

   type Bomb_Array    is array (1 .. Bomb_Slots)    of Bomb_Record;
   type Flame_Array   is array (1 .. Flame_Slots)   of Flame_Record;
   type Enemy_Array   is array (1 .. Enemy_Count)   of Enemy_Record;
   type Powerup_Array is array (1 .. Powerup_Slots) of Powerup_Record;

   type Game_State is record
      M        : Map.Map_Type;
      Player   : Player_Record;
      Bombs    : Bomb_Array;
      Flames   : Flame_Array;
      Enemies  : Enemy_Array;
      Powerups : Powerup_Array;
      Status   : Game_Status;
      Tick     : Natural;
   end record;

   procedure Init          (State : out    Game_State);
   procedure Process_Input (State : in out Game_State; Key : Integer);
   procedure Update        (State : in out Game_State);

end Game;
