package Serial_Port is
   pragma Elaborate_Body;

   Receive_Buffer_Size : constant Natural := 128; -- Number of bytes to buffer from RX line

   procedure Enable(Baud_Rate : in Natural);

   -- Read any characters that are available into the provided buffer, stopping when the buffer is
   -- full or all characters are exhausted.
   -- Buffer: a character buffer that will contain the read characters.
   -- Characters_Read: the number of characters that have been added to the buffer.
   procedure Read(Buffer : out String; Characters_Read : out Natural);

   -- Read any characters available into the buffer, stopping when the buffer is full, all
   -- characters are exhausted, or a newline character is read.
   procedure Read_Line(Buffer : out String; Characters_Read : out Natural);

   procedure Write(Message : in String);
   procedure Write(Message : in Character);

   procedure Write_Line(Message : in String);
end Serial_Port;
