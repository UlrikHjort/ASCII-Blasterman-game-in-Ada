-- ***************************************************************************
--                         Blasterman - Map
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

package body Map is

   package Rand_Bool is new Ada.Numerics.Discrete_Random (Boolean);
   Gen : Rand_Bool.Generator;

   procedure Generate (M : out Map_Type) is
   begin
      Rand_Bool.Reset (Gen);

      --  Fill interior with empty
      M.Tiles := (others => (others => Empty));

      --  Solid border
      for C in Col_Type loop
         M.Tiles (1,          C) := Wall;
         M.Tiles (Map_Height, C) := Wall;
      end loop;
      for R in Row_Type loop
         M.Tiles (R, 1)         := Wall;
         M.Tiles (R, Map_Width) := Wall;
      end loop;

      --  Indestructible pillars at (odd row, odd col) inside border
      --  (same checkerboard as classic Bomberman)
      for R in Row_Type range 2 .. Map_Height - 1 loop
         for C in Col_Type range 2 .. Map_Width - 1 loop
            if R mod 2 = 1 and then C mod 2 = 1 then
               M.Tiles (R, C) := Wall;
            end if;
         end loop;
      end loop;

      --  Random soft blocks on empty interior cells (~50 %)
      --  Skip safe zone around player spawn at (col=2, row=2)
      for R in Row_Type range 2 .. Map_Height - 1 loop
         for C in Col_Type range 2 .. Map_Width - 1 loop
            if M.Tiles (R, C) = Empty then
               if not ((R <= 3 and then C <= 4)
                  or else (R <= 4 and then C <= 3))
               then
                  if Rand_Bool.Random (Gen) then
                     M.Tiles (R, C) := Soft;
                  end if;
               end if;
            end if;
         end loop;
      end loop;
   end Generate;

   function Is_Walkable (M : Map_Type; P : Position) return Boolean is
   begin
      return M.Tiles (P.Row, P.Col) = Empty
         or else M.Tiles (P.Row, P.Col) = Flame;
   end Is_Walkable;

   function Tile_At (M : Map_Type; P : Position) return Tile_Kind is
   begin
      return M.Tiles (P.Row, P.Col);
   end Tile_At;

   procedure Set_Tile (M : in out Map_Type; P : Position; T : Tile_Kind) is
   begin
      M.Tiles (P.Row, P.Col) := T;
   end Set_Tile;

end Map;
