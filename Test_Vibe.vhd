library ieee;
use ieee.std_logic_1164.all;

entity Test_Vibe is
end Test_Vibe;

architecture behavior of Test_Vibe is 

  component AshaVibe
  port
  (
    Clock             : in  std_logic;
    Reset             : in  std_logic;
    SensorVibe        : in  std_logic;
    SensorVibeHouseOn : out std_logic
  );
  end component;

  --Inputs
  signal Clock      : std_logic := '0';
  signal Reset      : std_logic := '0';
  signal SensorVibe : std_logic := '0';

  --Outputs
  signal SensorVibeHouseOn : std_logic;

  -- Clock period definitions
  constant Clock_period : time := 10 ns;

begin

  uut: AshaVibe port map
  (
    Clock => Clock,
    Reset => Reset,
    SensorVibe => SensorVibe,
    SensorVibeHouseOn => SensorVibeHouseOn
  );

  process
  begin
    Clock <= '0';
    wait for Clock_period/2;
    Clock <= '1';
    wait for Clock_period/2;
  end process;

  process
  begin
    wait for 15 ms;
    loop
      SensorVibe <= '1';
      wait for 27 ms;
      SensorVibe <= '0';
      wait for 3 ms;
    end loop;
  end process;

  -- Input Process
  process
  begin
    wait for 30 ms;
    loop
      Reset <= '0';
      wait for 17 ms;
      Reset <= '1';
      wait for 6 ms;
    end loop;

    wait;
  end process;

end;
