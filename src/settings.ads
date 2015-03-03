-- Compile-time settings for Ceph firmware
with Ada.Numerics; use Ada.Numerics;

package Settings is
   -- Maximum platform velocity in mm/s
   Maximum_Linear_Velocity : constant Float := 50.0;
   -- Maximum platform acceleration in mm/s^2
   Maximum_Linear_Acceleration : Constant Float := 20.0;

   -- Maximum actuator velocity in rad/s
   Maximum_Angular_Velocity : constant Float := PI;
   -- Maximum actuator acceleration in rad/s^2
   Maximum_Angular_Acceleration : constant Float := 2.0 * PI;

   -- Number of steps required to turn the stepper motor by one full rotation
   Steps_Per_Revolution : constant Float := 240.0;
   Steps_Per_Radian : constant Float := Steps_Per_Revolution / (2.0 * PI);
end Settings;
