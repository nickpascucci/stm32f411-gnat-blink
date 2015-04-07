with System.OS_Interface;
with System.STM32F4; use System.STM32F4;

package body Serial_Port is
   -- Calculates the whole portion of the divider value.
   function USART_Mantissa(Baud_Rate : in Natural) return Bits_16 is
   begin
      return Bits_16(System.OS_Interface.Ticks_Per_Second / (4 * 16 * Baud_Rate));
   end USART_Mantissa;

   -- Calculates the fractional part of the divider value. This is 16 times the fractional
   -- component, encoded into 4 bits.
   function USART_Fraction(Baud_Rate : in Natural) return Bits_16 is
      Remainder : constant Natural := (System.OS_Interface.Ticks_Per_Second / 4)
        mod (16 * Baud_Rate);
   begin
      return Bits_16(Remainder / Baud_Rate);
   end USART_Fraction;

   -- Combine the mantissa and fractional baud rate components in the format the BRR register
   -- expects.
   function USART_Divider(Baud_Rate : in Natural) return Bits_16 is
      Mantissa : constant Bits_16 := USART_Mantissa(Baud_Rate);
      Fraction : constant Bits_16 := USART_Fraction(Baud_Rate);
   begin
      return (Mantissa * 2**4) or Fraction;
   end USART_Divider;

   procedure Enable(Baud_Rate : in Natural) is
      Divider : constant Bits_16 := USART_Divider(Baud_Rate);
   begin
      -- Step 0: Enable clock for USART2
      RCC.APB1ENR := RCC.APB1ENR or RCC_APB1ENR_USART2;
      -- Configure PA2 & 3 as alternate function, for USART2
      GPIOA.MODER(0..4) := (others => GPIO.Mode_AF);
      GPIOA.AFRL(0..4) := (others => GPIO.AF_USART2);
      -- Step 1: Enable the USART by writing UE bit.
      USART2.CR1 := USART2.CR1 or USART.CR1_UE;
      -- Step 2: Set the word size and number of stop/parity bits.
      -- We use 8n1 here.
      USART2.CR2 := USART2.CR2 or USART.CR2_STOP_1;
      -- Step 3: Configure the BRR register to set the baud rate.
      -- The mantissa goes in the leftmost 12 bits, the fraction in the remaining 4.
      USART2.BRR := Divider;
      -- Step 4: Set the TE bit to send an empty frame.
      USART2.CR1 := USART2.CR1 or USART.CR1_TE;
   end;

   procedure Read(Buffer : out String; Characters_Read : out Natural) is
   begin
      Characters_Read := 0;
      null; -- TODO
   end Read;

   procedure Read_Line(Buffer : out String; Characters_Read : out Natural) is
   begin
      Characters_Read := 0;
      null; -- TODO
   end Read_Line;

   procedure Write(Message : in String) is
   begin
      for Char of Message loop
         Write(Char);
      end loop;
   end Write;

   procedure Write(Message : in Character) is
   begin
      -- Step 1: Wait until TXE bit is clear. This indicates that the previous frame has been
      -- transmitted and we can safely write our data to the data register.
      loop
         exit when (USART2.SR and USART.SR_TXE) > 0;
      end loop;
      -- Step 2: Write the character to the data register to transmit it.
      USART2.DR := Bits_16(Character'Pos(Message));
   end Write;

   procedure Write_Line(Message : in String) is
   begin
      Write(Message);
      Write(ASCII.LF);
   end Write_Line;

end Serial_Port;
