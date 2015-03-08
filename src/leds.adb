------------------------------------------------------------------------------
--                                                                          --
--                             GNAT EXAMPLE                                 --
--                                                                          --
--             Copyright (C) 2014, Free Software Foundation, Inc.           --
--                                                                          --
-- GNAT is free software;  you can  redistribute it  and/or modify it under --
-- terms of the  GNU General Public License as published  by the Free Soft- --
-- ware  Foundation;  either version 3,  or (at your option) any later ver- --
-- sion.  GNAT is distributed in the hope that it will be useful, but WITH- --
-- OUT ANY WARRANTY;  without even the  implied warranty of MERCHANTABILITY --
-- or FITNESS FOR A PARTICULAR PURPOSE.                                     --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
--                                                                          --
-- You should have received a copy of the GNU General Public License and    --
-- a copy of the GCC Runtime Library Exception along with this program;     --
-- see the files COPYING3 and COPYING.RUNTIME respectively.  If not, see    --
-- <http://www.gnu.org/licenses/>.                                          --
--                                                                          --
-- GNAT was originally developed  by the GNAT team at  New York University. --
-- Extensive contributions were provided by Ada Core Technologies Inc.      --
--                                                                          --
------------------------------------------------------------------------------

with Ada.Unchecked_Conversion;

package body LEDs is


   function As_Word is new Ada.Unchecked_Conversion
     (Source => User_LED, Target => Word);


   procedure On (This : User_LED) is
   begin
      GPIOA.BSRR := As_Word (This);
   end On;


   procedure Off (This : User_LED) is
   begin
      GPIOA.BSRR := Shift_Left (As_Word (This), 16);
   end Off;


   All_LEDs_On  : constant Word := Green'Enum_Rep or Red'Enum_Rep or
                                   Blue'Enum_Rep  or Orange'Enum_Rep;

   pragma Compile_Time_Error
     (All_LEDs_On /= 16#F000#,
      "Invalid representation for All_LEDs_On");

   All_LEDs_Off : constant Word := Shift_Left (All_LEDs_On, 16);


   procedure All_Off is
   begin
      GPIOA.BSRR := All_LEDs_Off;
   end All_Off;


   procedure All_On is
   begin
      GPIOA.BSRR := All_LEDs_On;
   end All_On;


   procedure Initialize is
      RCC_AHB1ENR_GPIOA : constant Word := 16#08#;
   begin
      --  Enable clock for GPIO-D
      RCC.AHB1ENR := RCC.AHB1ENR or RCC_AHB1ENR_GPIOA;

      --  Configure PD12-15
      GPIOA.MODER   (12 .. 15) := (others => GPIO.Mode_OUT);
      GPIOA.OTYPER  (12 .. 15) := (others => GPIO.Type_PP);
      GPIOA.OSPEEDR (12 .. 15) := (others => GPIO.Speed_100MHz);
      GPIOA.PUPDR   (12 .. 15) := (others => GPIO.No_Pull);
   end Initialize;


begin
   Initialize;
end LEDs;
