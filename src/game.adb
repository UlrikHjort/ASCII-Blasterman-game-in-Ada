-- ***************************************************************************
--                       Blasterman - Game         
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
with Ada.Numerics.Discrete_Random;
with Game_Types; use Game_Types;
with Map;
with Terminal;

package body Game is

   --  Random generators
   subtype Dir_4 is Integer range 0 .. 3;
   package Rand_Dir  is new Ada.Numerics.Discrete_Random (Dir_4);
   package Rand_Bool is new Ada.Numerics.Discrete_Random (Boolean);

   Dir_Gen  : Rand_Dir.Generator;
   Bool_Gen : Rand_Bool.Generator;

   --  Movement deltas indexed [1..4, 1=DC / 2=DR]
   --  1=North  2=South  3=West  4=East
   type Delta_Array is array (1 .. 4, 1 .. 2) of Integer;
   Deltas : constant Delta_Array :=
     ((0, -1), (0, 1), (-1, 0), (1, 0));

   -- ---------------------------------------------------------------
   --  Internal helpers 
   -- ---------------------------------------------------------------

   procedure Add_Flame (State : in out Game_State; P : Position) is
   begin
      Map.Set_Tile (State.M, P, Flame);
      for I in State.Flames'Range loop
         if not State.Flames (I).Active then
            State.Flames (I) :=
              (Pos => P, Ticks => Flame_Life_Ticks, Active => True);
            return;
         end if;
      end loop;
      --  All slots full: silently drop (shouldn't happen in practice)
   end Add_Flame;

   procedure Try_Drop_Powerup (State : in out Game_State; P : Position) is
   begin
      if not Rand_Bool.Random (Bool_Gen) then
         return;  --  50 % chance: no drop
      end if;
      for I in State.Powerups'Range loop
         if not State.Powerups (I).Active then
            State.Powerups (I) :=
              (Pos    => P,
               Kind   => (if Rand_Bool.Random (Bool_Gen)
                          then Range_Up else Bomb_Up),
               Active => True);
            return;
         end if;
      end loop;
   end Try_Drop_Powerup;

   procedure Explode (State : in out Game_State; B_Idx : Positive) is
      B_Pos : constant Position := State.Bombs (B_Idx).Pos;
      B_Rng : constant Positive := State.Bombs (B_Idx).Rng;
   begin
      Add_Flame (State, B_Pos);

      for D in 1 .. 4 loop
         for Step in 1 .. B_Rng loop
            declare
               NC : constant Integer :=
                  Integer (B_Pos.Col) + Deltas (D, 1) * Step;
               NR : constant Integer :=
                  Integer (B_Pos.Row) + Deltas (D, 2) * Step;
            begin
               exit when NC not in Col_Type or else NR not in Row_Type;
               declare
                  NP : constant Position := (Col => NC, Row => NR);
               begin
                  case Map.Tile_At (State.M, NP) is
                     when Wall =>
                        exit;  --  blocked; stop this arm
                     when Soft =>
                        Add_Flame (State, NP);
                        Try_Drop_Powerup (State, NP);
                        exit;  --  flame doesn't pass through
                     when Empty | Flame =>
                        Add_Flame (State, NP);
                  end case;

                  --  Chain-detonate any other bomb sitting here
                  for J in State.Bombs'Range loop
                     if J /= B_Idx
                        and then State.Bombs (J).Active
                        and then State.Bombs (J).Pos = NP
                        and then State.Bombs (J).Ticks > 1
                     then
                        State.Bombs (J).Ticks := 1;
                     end if;
                  end loop;
               end;
            end;
         end loop;
      end loop;

      if State.Player.Bombs_Out > 0 then
         State.Player.Bombs_Out := State.Player.Bombs_Out - 1;
      end if;
      State.Bombs (B_Idx).Active := False;
   end Explode;

   procedure Move_Player (State : in out Game_State; DC, DR : Integer) is
      NC : constant Integer := Integer (State.Player.Pos.Col) + DC;
      NR : constant Integer := Integer (State.Player.Pos.Row) + DR;
   begin
      if NC not in Col_Type or else NR not in Row_Type then
         return;
      end if;
      declare
         NP : constant Position := (Col => NC, Row => NR);
      begin
         if not Map.Is_Walkable (State.M, NP) then
            return;
         end if;
         for I in State.Bombs'Range loop
            if State.Bombs (I).Active
               and then State.Bombs (I).Pos = NP
            then
               return;  --  bomb blocks passage
            end if;
         end loop;
         State.Player.Pos := NP;
      end;
   end Move_Player;

   procedure Place_Bomb (State : in out Game_State) is
   begin
      if State.Player.Bombs_Out >= State.Player.Max_Bombs then
         return;
      end if;
      for I in State.Bombs'Range loop
         if State.Bombs (I).Active
            and then State.Bombs (I).Pos = State.Player.Pos
         then
            return;  --  already a bomb here
         end if;
      end loop;
      for I in State.Bombs'Range loop
         if not State.Bombs (I).Active then
            State.Bombs (I) :=
              (Pos    => State.Player.Pos,
               Ticks  => Bomb_Fuse_Ticks,
               Rng    => State.Player.Bomb_Range,
               Active => True);
            State.Player.Bombs_Out := State.Player.Bombs_Out + 1;
            return;
         end if;
      end loop;
   end Place_Bomb;

   procedure Update_Bombs (State : in out Game_State) is
   begin
      for I in State.Bombs'Range loop
         if State.Bombs (I).Active then
            if State.Bombs (I).Ticks > 0 then
               State.Bombs (I).Ticks := State.Bombs (I).Ticks - 1;
            else
               Explode (State, I);
            end if;
         end if;
      end loop;
   end Update_Bombs;

   procedure Update_Flames (State : in out Game_State) is
   begin
      for I in State.Flames'Range loop
         if State.Flames (I).Active then
            if State.Flames (I).Ticks > 0 then
               State.Flames (I).Ticks := State.Flames (I).Ticks - 1;
            else
               State.Flames (I).Active := False;
               --  Clear tile only when no other flame covers this cell
               declare
                  P         : constant Position := State.Flames (I).Pos;
                  Still_Hot : Boolean := False;
               begin
                  for J in State.Flames'Range loop
                     if J /= I
                        and then State.Flames (J).Active
                        and then State.Flames (J).Pos = P
                     then
                        Still_Hot := True;
                        exit;
                     end if;
                  end loop;
                  if not Still_Hot
                     and then Map.Tile_At (State.M, P) = Flame
                  then
                     Map.Set_Tile (State.M, P, Empty);
                  end if;
               end;
            end if;
         end if;
      end loop;
   end Update_Flames;

   procedure Update_Enemies (State : in out Game_State) is
   begin
      for I in State.Enemies'Range loop
         if State.Enemies (I).Alive then
            State.Enemies (I).Move_Timer :=
               State.Enemies (I).Move_Timer + 1;

            if State.Enemies (I).Move_Timer >= Enemy_Move_Ticks then
               State.Enemies (I).Move_Timer := 0;

               declare
                  E  : Enemy_Record renames State.Enemies (I);
                  PC : constant Integer := Integer (State.Player.Pos.Col);
                  PR : constant Integer := Integer (State.Player.Pos.Row);
                  EC : constant Integer := Integer (E.Pos.Col);
                  ER : constant Integer := Integer (E.Pos.Row);
                  Dist : constant Integer :=
                     abs (PC - EC) + abs (PR - ER);
                  DC, DR : Integer;
                  NC, NR : Integer;
               begin
                  --  Chase when close, wander otherwise
                  if Dist <= 6 then
                     if abs (PC - EC) >= abs (PR - ER) then
                        DC := (if PC > EC then 1 else -1);
                        DR := 0;
                     else
                        DC := 0;
                        DR := (if PR > ER then 1 else -1);
                     end if;
                  else
                     DC := E.DC;
                     DR := E.DR;
                  end if;

                  NC := EC + DC;
                  NR := ER + DR;

                  if NC in Col_Type and then NR in Row_Type then
                     declare
                        NP           : constant Position :=
                                          (Col => NC, Row => NR);
                        Bomb_Blocked : Boolean := False;
                     begin
                        for J in State.Bombs'Range loop
                           if State.Bombs (J).Active
                              and then State.Bombs (J).Pos = NP
                           then
                              Bomb_Blocked := True;
                              exit;
                           end if;
                        end loop;

                        if Map.Is_Walkable (State.M, NP)
                           and then not Bomb_Blocked
                        then
                           E.Pos := NP;
                           E.DC  := DC;
                           E.DR  := DR;
                        else
                           --  Blocked: pick a random new heading
                           declare
                              R : constant Integer :=
                                 Integer (Rand_Dir.Random (Dir_Gen));
                           begin
                              E.DC := Deltas (R + 1, 1);
                              E.DR := Deltas (R + 1, 2);
                           end;
                        end if;
                     end;
                  else
                     declare
                        R : constant Integer :=
                           Integer (Rand_Dir.Random (Dir_Gen));
                     begin
                        E.DC := Deltas (R + 1, 1);
                        E.DR := Deltas (R + 1, 2);
                     end;
                  end if;
               end;
            end if;
         end if;
      end loop;
   end Update_Enemies;

   procedure Check_Collisions (State : in out Game_State) is
      PP : constant Position := State.Player.Pos;

      procedure Hit_Player is
      begin
         if State.Player.Lives > 0 then
            State.Player.Lives := State.Player.Lives - 1;
         end if;
         State.Player.Invincible := Invincible_Ticks;
         if State.Player.Lives = 0 then
            State.Status := Lost;
         end if;
      end Hit_Player;

   begin
      --  Player vs flames
      if State.Player.Invincible = 0 then
         for I in State.Flames'Range loop
            if State.Flames (I).Active
               and then State.Flames (I).Pos = PP
            then
               Hit_Player;
               exit;
            end if;
         end loop;
      end if;

      if State.Status /= Playing then return; end if;

      --  Player vs enemies
      if State.Player.Invincible = 0 then
         for I in State.Enemies'Range loop
            if State.Enemies (I).Alive
               and then State.Enemies (I).Pos = PP
            then
               Hit_Player;
               exit;
            end if;
         end loop;
      end if;

      if State.Status /= Playing then return; end if;

      --  Player collects power-ups
      for I in State.Powerups'Range loop
         if State.Powerups (I).Active
            and then State.Powerups (I).Pos = PP
         then
            case State.Powerups (I).Kind is
               when Range_Up =>
                  if State.Player.Bomb_Range < 6 then
                     State.Player.Bomb_Range :=
                        State.Player.Bomb_Range + 1;
                  end if;
               when Bomb_Up =>
                  if State.Player.Max_Bombs < Bomb_Slots then
                     State.Player.Max_Bombs :=
                        State.Player.Max_Bombs + 1;
                  end if;
            end case;
            State.Powerups (I).Active := False;
            State.Player.Score := State.Player.Score + 50;
         end if;
      end loop;

      --  Enemies caught in flames
      for I in State.Enemies'Range loop
         if State.Enemies (I).Alive then
            for J in State.Flames'Range loop
               if State.Flames (J).Active
                  and then State.Flames (J).Pos = State.Enemies (I).Pos
               then
                  State.Enemies (I).Alive := False;
                  State.Player.Score := State.Player.Score + 100;
                  exit;
               end if;
            end loop;
         end if;
      end loop;

      --  Win when all enemies are eliminated
      declare
         All_Dead : Boolean := True;
      begin
         for I in State.Enemies'Range loop
            if State.Enemies (I).Alive then
               All_Dead := False;
               exit;
            end if;
         end loop;
         if All_Dead then
            State.Status := Won;
         end if;
      end;
   end Check_Collisions;

   -- ---------------------------------------------------------------
   --  Exported procedures
   -- ---------------------------------------------------------------

   procedure Init (State : out Game_State) is
      procedure Clear_Spawn (C, R : Integer) is
         P : constant Position := (Col => C, Row => R);
      begin
         if Map.Tile_At (State.M, P) = Soft then
            Map.Set_Tile (State.M, P, Empty);
         end if;
      end Clear_Spawn;
   begin
      Map.Generate (State.M);

      --  Guarantee clear spawn corridors for player and enemies
      Clear_Spawn (2, 2);  Clear_Spawn (3, 2);  Clear_Spawn (2, 3);
      Clear_Spawn (4, 2);  Clear_Spawn (2, 4);
      Clear_Spawn (16, 2); Clear_Spawn (15, 2); Clear_Spawn (16, 3);
      Clear_Spawn (2, 12); Clear_Spawn (3, 12); Clear_Spawn (2, 11);
      Clear_Spawn (16, 12);Clear_Spawn (15, 12);Clear_Spawn (16, 11);
      Clear_Spawn (10, 8); Clear_Spawn (9, 8);  Clear_Spawn (10, 7);

      State.Player :=
        (Pos        => (Col => 2, Row => 2),
         Lives      => 3,
         Score      => 0,
         Bomb_Range => 2,
         Max_Bombs  => 1,
         Bombs_Out  => 0,
         Invincible => 0);

      for I in State.Bombs'Range    loop State.Bombs (I).Active    := False; end loop;
      for I in State.Flames'Range   loop State.Flames (I).Active   := False; end loop;
      for I in State.Powerups'Range loop State.Powerups (I).Active := False; end loop;

      State.Enemies (1) :=
        (Pos => (Col => 16, Row =>  2), Alive => True,
         Move_Timer => 0, DC => -1, DR =>  0);
      State.Enemies (2) :=
        (Pos => (Col =>  2, Row => 12), Alive => True,
         Move_Timer => 0, DC =>  1, DR =>  0);
      State.Enemies (3) :=
        (Pos => (Col => 16, Row => 12), Alive => True,
         Move_Timer => 0, DC =>  0, DR => -1);
      State.Enemies (4) :=
        (Pos => (Col => 10, Row =>  8), Alive => True,
         Move_Timer => 0, DC =>  1, DR =>  1);

      State.Status := Playing;
      State.Tick   := 0;
   end Init;

   procedure Process_Input (State : in out Game_State; Key : Integer) is
   begin
      if State.Status /= Playing then return; end if;

      case Key is
         when Terminal.Key_Up    | 87 | 119 => Move_Player (State,  0, -1);  --  W/w
         when Terminal.Key_Down  | 83 | 115 => Move_Player (State,  0,  1);  --  S/s
         when Terminal.Key_Left  | 65 | 97  => Move_Player (State, -1,  0);  --  A/a
         when Terminal.Key_Right | 68 | 100 => Move_Player (State,  1,  0);  --  D/d
         when 32                            => Place_Bomb (State);            --  Space
         when others                        => null;
      end case;
   end Process_Input;

   procedure Update (State : in out Game_State) is
   begin
      if State.Status /= Playing then return; end if;

      State.Tick := State.Tick + 1;
      if State.Player.Invincible > 0 then
         State.Player.Invincible := State.Player.Invincible - 1;
      end if;

      Update_Bombs     (State);
      Update_Flames    (State);
      Update_Enemies   (State);
      Check_Collisions (State);
   end Update;

begin
   --  Seed random generators once at package elaboration
   Rand_Dir.Reset  (Dir_Gen);
   Rand_Bool.Reset (Bool_Gen);
end Game;
