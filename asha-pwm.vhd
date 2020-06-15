library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.AshaTypes.all;

--! @brief ASHA-Modul - PWM-Signale erzeugen
--! @details  Dieses Modul erzeugt die PWM-Signale fuer PWM-Aktoren
entity AshaPWM is
  Port
  (
    Clock                : in  std_logic;                      --! Taktsignal
    Reset                : in  std_logic;                      --! Resetsignal

    EnPWMClock           : in  std_logic;                      --! Enable-Signal fuer die PWM-Abarbeitung

    PWM1FanInsideValue   : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter innen
    PWM2FanOutsideValue  : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter aussen
    PWM3LightValue       : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Licht
    PWM4PeltierValue     : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier

    PWM1FanInsideSignal  : out std_logic;                      --! PWM-Aktorsignal Luefter innen
    PWM2FanOutsideSignal : out std_logic;                      --! PWM-Aktorsignal Luefter aussen
    PWM3LightSignal      : out std_logic;                      --! PWM-Aktorsignal Licht
    PWM4PeltierSignal    : out std_logic                       --! PWM-Aktorsignal Peltier
  );
end entity;

architecture Behavioral of AshaPWM is

  -- PWM clock signals
  signal PWM1 : std_logic := '0';
  signal PWM2 : std_logic := '0';
  signal PWM3 : std_logic := '0';
  signal PWM4 : std_logic := '0';

  -- PWM counter and bound
  signal   Count : unsigned(7 downto 0) := x"00";
  constant Bound : unsigned(7 downto 0) := x"ff";

begin

  -- update output and count
  -- synchronized with EnPWMClock
  process (EnPWMClock)
  begin
    if rising_edge (EnPWMClock) then

      Count <= Count + 1;

      PWM1FanInsideSignal  <= PWM1;
      PWM2FanOutsideSignal <= PWM2;
      PWM3LightSignal      <= PWM3;
      PWM4PeltierSignal    <= PWM4;

    end if;
  end process;

  -- trivial evaluate pwm signals

  PWM1 <= '0' when (PWM1FanInsideValue = x"ff")            else -- trivial accept
          '0' when (Count < unsigned(PWM1FanInsideValue))  else -- get active when count reaches value
          '1';                                                  -- trivial zero

  PWM2 <= '0' when (PWM2FanOutsideValue = x"ff")           else
          '0' when (Count < unsigned(PWM2FanOutsideValue)) else
          '1';

  PWM3 <= '0' when (PWM3LightValue = x"ff")                else
          '0' when (Count < unsigned(PWM3LightValue))      else
          '1';

  PWM4 <= '0' when (PWM4PeltierValue = x"ff")              else
          '0' when (Count < unsigned(PWM4PeltierValue))    else
          '1';

end architecture;
