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

with Ada.Interrupts.Names;
with System.STM32F4; use System.STM32F4;
with Ada.Real_Time; use Ada.Real_Time;

package body Button is

   protected Button is
      pragma Interrupt_Priority;

      function Blink_Speed return Blink_Period;

   private
      procedure Interrupt_Handler;
      pragma Attach_Handler
         (Interrupt_Handler,
          Ada.Interrupts.Names.EXTI15_10_Interrupt);

      Current_Speed : Blink_Period := Short;
      Last_Time : Time := Clock;
   end Button;

   Debounce_Time : constant Time_Span := Milliseconds (500);

   protected body Button is

      function Blink_Speed return Blink_Period is
      begin
         return Current_Speed;
      end Blink_Speed;

      procedure Interrupt_Handler is
         Now : constant Time := Clock;
      begin
         --  Clear interrupt
         EXTI.PR (13) := 1;

         --  Debouncing
         if Now - Last_Time >= Debounce_Time then
            case Current_Speed is
               when Long => Current_Speed := Short;
               when Medium => Current_Speed := Long;
               when Short => Current_Speed := Medium;
            end case;

            Last_Time := Now;
         end if;
      end Interrupt_Handler;

   end Button;

   function Blink_Speed return Blink_Period is
   begin
      return Button.Blink_Speed;
   end Blink_Speed;

   procedure Initialize is
      RCC_AHB1ENR_GPIOC : constant Word := 2**2;
      RCC_APB2ENR_SYSCFG : constant Word := 2**14;
   begin
      --  Enable clock for GPIOC
      RCC.AHB1ENR := RCC.AHB1ENR or RCC_AHB1ENR_GPIOC;
      RCC.APB2ENR := RCC.APB2ENR or RCC_APB2ENR_SYSCFG;

      --  Configure PC13
      GPIOC.MODER (13) := GPIO.Mode_IN;
      GPIOC.PUPDR (13) := GPIO.No_Pull;

      --  Select PC13 for EXTI13
      -- See Page 139 of the RM0383 datasheet
      SYSCFG.EXTICR4 (1) := SYSCFG_Constants.PORTC;

      --  Interrupt on falling edge
      EXTI.FTSR (13) := 1;
      EXTI.RTSR (13) := 0;

      -- Disable all other interrupts but ours
      EXTI.IMR := (13 => 1, others => 0);
   end Initialize;

begin
   Initialize;
end Button;
