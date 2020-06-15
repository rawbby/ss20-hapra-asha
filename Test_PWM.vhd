LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY Test_PWM IS
END Test_PWM;

ARCHITECTURE behavior OF Test_PWM IS 

    COMPONENT AshaPWM
    PORT(
         Clock : IN  std_logic;
         Reset : IN  std_logic;
         EnPWMClock : IN  std_logic;
         PWM1FanInsideValue : IN  std_logic_vector(7 downto 0);
         PWM2FanOutsideValue : IN  std_logic_vector(7 downto 0);
         PWM3LightValue : IN  std_logic_vector(7 downto 0);
         PWM4PeltierValue : IN  std_logic_vector(7 downto 0);
         PWM1FanInsideSignal : OUT  std_logic;
         PWM2FanOutsideSignal : OUT  std_logic;
         PWM3LightSignal : OUT  std_logic;
         PWM4PeltierSignal : OUT  std_logic
        );
    END COMPONENT;

  --Inputs
  signal Clock               : std_logic := '0';
  signal Reset               : std_logic := '0';
  signal EnPWMClock          : std_logic := '0';
  signal PWM1FanInsideValue  : std_logic_vector (7 downto 0) := x"00"; -- test all zero
  signal PWM2FanOutsideValue : std_logic_vector (7 downto 0) := x"0f"; -- test custom value 1
  signal PWM3LightValue      : std_logic_vector (7 downto 0) := x"f0"; -- test custom value 2
  signal PWM4PeltierValue    : std_logic_vector (7 downto 0) := x"ff"; -- test all one

  --Outputs
  signal PWM1FanInsideSignal  : std_logic;
  signal PWM2FanOutsideSignal : std_logic;
  signal PWM3LightSignal      : std_logic;
  signal PWM4PeltierSignal    : std_logic;

  -- Clock period definitions
  constant EnPWMClock_period : time := 166.666666 ns; --! ~6 MHz

begin

  uut: AshaPWM PORT MAP
  (
    Clock => Clock,
    Reset => Reset,
    EnPWMClock => EnPWMClock,
    PWM1FanInsideValue => PWM1FanInsideValue,
    PWM2FanOutsideValue => PWM2FanOutsideValue,
    PWM3LightValue => PWM3LightValue,
    PWM4PeltierValue => PWM4PeltierValue,
    PWM1FanInsideSignal => PWM1FanInsideSignal,
    PWM2FanOutsideSignal => PWM2FanOutsideSignal,
    PWM3LightSignal => PWM3LightSignal,
    PWM4PeltierSignal => PWM4PeltierSignal
  );

  -- emulate the 3Hz clock
  process
  begin
    EnPWMClock <= '0';
    wait for EnPWMClock_period/2;
    EnPWMClock <= '1';
    wait for EnPWMClock_period/2;
  end process;

  -- wait to enable simulation
  process
  begin
    wait;
  end process;
end;
