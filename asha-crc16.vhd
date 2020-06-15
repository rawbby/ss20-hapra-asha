library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.AshaTypes.all;

--! @brief 8bit CRC-16 CCITT MCRF4XX (Cyclic Redundancy Check)
--! @details
--! Features:
--!  - CRC-16 mit CCITT-Polynom (x^16+x^12+x^5+1)
--!  - LSB-First (0x1021-Polynom, nicht 0x8408), reflected/reversed
--!  - Initialisierung: 0xFFFF
--!  - Byteweise CRC-Berechnung
entity AshaCRC16 is
    Port ( Clock : in std_logic; --! Taktsignal
           Reset : in  std_logic; --! Resetsignal
           NextData : in  std_logic; --! Sendeanweisung (1 Takt)
           InByte  : in  std_logic_vector (7 downto 0); --! Dateneingang
           CRCOut : out  std_logic_vector (15 downto 0)); --! CRC-Ausgang
end AshaCRC16;

--! @brief 8bit CRC-16 CCITT MCRF4XX (Cyclic Redundancy Check)
--! @details Nach dem Reset wird ein im Quelltext festgelegter Startwert
--! angenommen (im CRCOut), welcher z.B. den Startdelimiter schon enthalten
--! kann. Bei jedem High von NextData wird nun
--! der Wert von InByte dem CRCOut hinzugefuegt. Dies geschieht vom
--! niederwertigsten Bit aus (LSB-first) in 8 Takten.
architecture Behavioral of AshaCRC16 is

signal Data : std_logic_vector(7 downto 0); -- interner Datenpuffer
signal CRC : std_logic_vector(0 to 15);     -- internes CRC-Register
signal Counter : unsigned( 2 downto 0);     -- Zähler
signal Old15 : std_logic;                     -- Zwischenspeicher 16.Bit
signal Running : std_logic;                 -- Anzeige ob CRC Verarbeitung läuft; zum Puffern des NextData

begin

  CRCOut<=CRC;

  --! CRC Behandlung per Schieberegister
  process (Clock)
  begin
    if rising_edge(Clock) then
      if (Reset='1') then
        -- Startwert: 0xFFFF xor (CRC-16 des verdrehten Startdelimiters)
        CRC<="1101001111111101";

        -- TODO


      -- Neue Daten annehmen, wenn diese kommen, waehrend man nicht gerade
      -- alte bearbeitet
      -- TODO: elsif ...


      --TODO: elsif ....
        -- Register shiften
        -- Bit 0,5 und 12 werden mit Bit 16 (dem alten Bit 15)
        -- "verentwederodert".


      end if;
    end if;
  end process;

end Behavioral;

