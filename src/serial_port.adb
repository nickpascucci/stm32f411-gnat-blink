with Ada.Interrupts.Names;
with Ada.Unchecked_Conversion;
with System.OS_Interface;
with System.STM32F4; use System.STM32F4;

package body Serial_Port is

   pragma Warnings (Off,
                    "*types for unchecked conversion have different sizes");

   function Bits_To_Char is
      new Ada.Unchecked_Conversion (Source => Bits_16, Target => Character);

   function Char_To_Bits is
      new Ada.Unchecked_Conversion (Source => Character, Target => Bits_16);

   -- A thread-safe buffer to store data coming from the serial port.
   protected Serial_Buffer is
      pragma Interrupt_Priority;

   private
      Receive_Buffer : String (1..Receive_Buffer_Size) := (others => ASCII.NUL);
      Buffered_Chars : Natural := 0;

      procedure Interrupt_Handler;
      pragma Attach_Handler
         (Interrupt_Handler,
          Ada.Interrupts.Names.USART2_Interrupt);

      procedure Read_Until(Buffer : out String; End_Char : in Character; Chars_Read : out Natural);

   end Serial_Buffer;

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
      -- Enable clock for USART2
      RCC.APB1ENR := RCC.APB1ENR or RCC_APB1ENR_USART2;
      -- Configure PA2 & 3 as alternate function, for USART2
      GPIOA.MODER(0..4) := (others => GPIO.Mode_AF);
      GPIOA.AFRL(0..4) := (others => GPIO.AF_USART2);
      -- Set the word size and number of stop/parity bits.
      -- We use 8n1 here.
      USART2.CR2 := USART2.CR2 or USART.CR2_STOP_1;
      -- Configure the BRR register to set the baud rate.
      -- The mantissa goes in the leftmost 12 bits, the fraction in the remaining 4.
      USART2.BRR := Divider;
      -- Turn on receiver and transmitter, & enable RX interrupts. This will also send an empty
      -- frame as a side effect of turning on TE.
      USART2.CR1 := USART.CR1_UE or USART.CR1_RE or
                    USART.CR1_RXNEIE or USART.CR1_TE;
   end;

   procedure Read(Buffer : out String; Characters_Read : out Natural) is
   begin
      Serial_Buffer.Read_Until(Buffer, ASCII.NUL, Characters_Read);
   end Read;

   procedure Read_Line(Buffer : out String; Characters_Read : out Natural) is
   begin
      Serial_Buffer.Read_Until(Buffer, ASCII.LF, Characters_Read);
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
      USART2.DR := Char_To_Bits(Message);
   end Write;

   procedure Write_Line(Message : in String) is
   begin
      Write(Message);
      Write(ASCII.LF);
   end Write_Line;

   protected body Serial_Buffer is

      -- Interrupt handler which is called when new data is received by the serial port.
      procedure Interrupt_Handler is
         Received_Char : Character := ' ';
      begin
         -- read from DR clears Interrupt in USART
         Received_Char := Bits_To_Char (USART2.DR);

         -- If the buffer is full, we'll simply drop the read characters until room is available.
         if Buffered_Chars < Receive_Buffer'Length then
            Receive_Buffer(Receive_Buffer'First + Buffered_Chars) := Received_Char;
            Buffered_Chars := Buffered_Chars + 1;
         end if;
      end Interrupt_Handler;

      procedure Read_Until(Buffer : out String; End_Char : in Character; Chars_Read : out Natural)
      is
         Buffered_Char : Character;
         Read_Chars : Natural := 0;
      begin
         -- Read all of the chars into the given buffer until we hit the end char or run out.
         Read_Chars := 0;
         for I in 0..(Buffered_Chars - 1) loop
            Buffered_Char := Receive_Buffer(Receive_Buffer'First + I);
            exit when Buffered_Char = End_Char;
            Buffer(Buffer'First + I) := Buffered_Char;
            Read_Chars := Read_Chars + 1;
         end loop;
         -- Shift the serial buffer so that the remaining characters are at the front.
         for I in Read_Chars..Buffered_Chars loop
            Receive_Buffer(Receive_Buffer'First + I - Read_Chars) :=
              Receive_Buffer(Receive_Buffer'First + I);
         end loop;

         -- Null terminate the buffer.
         Buffered_Chars := Buffered_Chars - Read_Chars;
         Receive_Buffer(Receive_Buffer'First + Buffered_Chars) := ASCII.NUL;
         Chars_Read := Read_Chars;
      end Read_Until;

   end Serial_Buffer;

end Serial_Port;
