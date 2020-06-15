library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

library work;
use work.ashatypes.all;

--! @brief ASHA-Modul - Signale des Vibrationssensors aufbereiten
--! @details Dieses Modul Empfaengt das Signal des Vibrationssensors im Haus
--! und wertet es aus. Ueber das Signal SensorVibeHouseOn kann dieses Modul
--! dem Hauptmodul signalisieren, wenn es das Haus auschalten soll.

entity AshaVibe is
  Port
  (
    Clock             : in  std_logic; --! Taktsignal
    Reset             : in  std_logic; --! Resetsignal
    SensorVibe        : in  std_logic; --! Vibrationssensorsignal direkt vom Haus
    SensorVibeHouseOn : out std_logic  --! Haus an/aus-Signal des Vibe-Moduls
  );
end;

architecture Behavioral of AshaVibe is

  signal SensorState : std_logic := '1';

begin

  -- update output
  -- synchronized with Clock
  process (Clock)
  begin
    if rising_edge (Clock) then
      SensorVibeHouseOn <= SensorState;
    end if;
  end process;

  SensorState <= '0' when (SensorVibe = '0') else -- make inactive if sensor vibe occured
                 '1' when (Reset      = '1') else -- make active   if reset       occured
                 SensorState;                     -- keep current state

end;
