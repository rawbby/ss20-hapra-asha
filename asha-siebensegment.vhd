library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.AshaTypes.all;

--! @brief Ansteuerung der Siebensegmentanzeige
--! @details Dieses Modul uebernimmt Daten in Form eines 16-bit Wortes und
--! zeigt dieses in Form des Hex-Wertes auf der Siebensegmentanzeige an
entity AshaSiebensegment is
  Port
  (
    Clock               : in  std_logic;                     --! Taktsignal
    Reset               : in  std_logic;                     --! Resetsignal
    EnSevenSegmentClock : in  std_logic;                     --! Enable-Signal des Treiberprozesses
    SevenSegmentValue   : in  std_logic_vector(15 downto 0); --! der Wert, der auf der Anzeige erscheinen soll
    AN                  : out std_logic_vector(3  downto 0); --! Enable-Signale der einzelnen 7-Segment-Anzeigen
    SevenSegment        : out std_logic_vector(6  downto 0)  --! treibt die 7-Segment-Anzeigen; alle, bei denen AN aktiviert ist
  );
end AshaSiebensegment;

--! Ansteuerung der Siebensegmentanzeige
architecture Behavioral of AshaSiebensegment is

  signal ANint : std_logic_vector(3 downto 0);

  type SevenSegmentset_type is array (0 to 15) of std_logic_vector(6 downto 0);
  constant SevenSegmentset : SevenSegmentset_type :=
  (
    -- Versuch 6:
    -- Die Zeichen 1 bis F muessen hier noch richtig definert werden.
    --gfedcba
     "1000000", -- 0
     "1111001", -- 1
     "0100100", -- 2
     "0110000", -- 3
     "0011001", -- 4
     "0010010", -- 5
     "0000010", -- 6
     "1111000", -- 7
     "0000000", -- 8
     "0010000", -- 9
     "0001000", -- A
     "0000011", -- b
     "1000110", -- C
     "0100001", -- d
     "0000110", -- E
     "0001110"  -- F
  );

begin

  AN<=ANint;

  SetSevenSegment: process (Clock, Reset) -- 7-Segment-Prozess
  begin
    if (Reset = '1') then
      SevenSegment <= b"0000000";
      ANint <= "1110";
    elsif rising_edge(Clock) then

      if EnSevenSegmentClock = '1' then

        
        if (SevenSegmentValue = x"FFFF") then -- Zur Darstellung "ASHA" bei dem eigentlichen Wert von "FFFF"

          if    (ANint(2)='0') then SevenSegment <= b"0001000";
                                    ANint(2)     <=  '1';
                                    ANint(3)     <=  '0';

          elsif (ANint(1)='0') then SevenSegment <= b"0010010";
                                    ANint(1)     <=  '1';
                                    ANint(2)     <=  '0';

          elsif (ANint(0)='0') then SevenSegment <= b"0001001";
                                    ANint(0)     <=  '1';
                                    ANint(1)     <=  '0';

          elsif (ANint(3)='0') then SevenSegment <= b"0001000";
                                    ANint(3)     <=  '1';
                                    ANint(0)     <=  '0';

          end if;

        else -- Darstellung der Zeichen

          if    (ANint(2)='0') then SevenSegment <= SevenSegmentset(to_integer(unsigned(SevenSegmentValue(15 downto 12))));
                                    ANint(2)     <= '1';
                                    ANint(3)     <= '0';

          elsif (ANint(1)='0') then SevenSegment <= SevenSegmentset(to_integer(unsigned(SevenSegmentValue(11 downto 8))));
                                    ANint(1)     <= '1';
                                    ANint(2)     <= '0';

          elsif (ANint(0)='0') then SevenSegment <= SevenSegmentset(to_integer(unsigned(SevenSegmentValue(7 downto 4))));
                                    ANint(0)     <= '1';
                                    ANint(1)     <= '0';

          elsif (ANint(3)='0') then SevenSegment <= SevenSegmentset(to_integer(unsigned(SevenSegmentValue(3 downto 0))));
                                    ANint(3)     <= '1';
                                    ANint(0)     <= '0';

          end if;
        end if;
      end if;
    end if;
  end process;
end;
