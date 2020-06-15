library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ashatypes.all;

entity Test_Actor_Mod1 is
end entity;

architecture behavior of Test_Actor_Mod1 is

  component actor
  port
  (
    Clock                      : in  std_logic;
    En3Hz                      : in  std_logic;       
    Reset                      : in  std_logic;
    Switches                   : in  std_logic_vector( 7 downto 0);
    ButtonsIn                  : in  std_logic_vector( 3 downto 0);
    SensorVibe                 : in  std_logic;
    SensorDoor                 : in  std_logic;
    ADCRegister                : in  ADCRegisterType;
    LEDsOut                    : out std_logic_vector( 7 downto 0);
    SevenSegmentValue          : out std_logic_vector(15 downto 0);
    PWM1FanInsideValue         : out std_logic_vector( 7 downto 0);
    PWM2FanOutsideValue        : out std_logic_vector( 7 downto 0);
    PWM3LightValue             : out std_logic_vector( 7 downto 0);
    PWM4PeltierValue           : out std_logic_vector( 7 downto 0);
    PeltierDirection           : out std_logic;
    LEDsBT                     : in  std_logic_vector( 7 downto 0);
    SevenSegmentValueBT        : in  std_logic_vector(15 downto 0);
    PWM1FanInsideValueBT       : in  std_logic_vector( 7 downto 0);
    PWM2FanOutsideValueBT      : in  std_logic_vector( 7 downto 0);
    PWM3LightValueBT           : in  std_logic_vector( 7 downto 0);
    PWM4PeltierValueBT         : in  std_logic_vector( 7 downto 0);
    PeltierDirectionBT         : in  std_logic;
    PWM1FanInsideValueControl  : in  std_logic_vector( 7 downto 0);
    PWM2FanOutsideValueControl : in  std_logic_vector( 7 downto 0);
    PWM3LightValueControl      : in  std_logic_vector( 7 downto 0);
    PWM4PeltierValueControl    : in  std_logic_vector( 7 downto 0);
    PeltierDirectionControl    : in  std_logic;
    ControlLightDiffOut        : in  unsigned(12 downto 0);
    ControlTempDiffOut         : in  unsigned(12 downto 0)
  );
  end component;

  --Inputs
  signal Clock                      : std_logic                     := '0';
  signal En3Hz                      : std_logic                     := '0';
  signal Reset                      : std_logic                     := '0';
  signal Switches                   : std_logic_vector( 7 downto 0) := (others => '0');
  signal ButtonsIn                  : std_logic_vector( 3 downto 0) := (others => '0');
  signal SensorVibe                 : std_logic                     := '0';
  signal SensorDoor                 : std_logic                     := '0';
  signal ADCRegister                : ADCRegisterType               :=
  (
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0'),
    (others => '0')
  );
  signal LEDsBT                     : std_logic_vector( 7 downto 0) := (others => '0');
  signal SevenSegmentValueBT        : std_logic_vector(15 downto 0) := (others => '0');
  signal PWM1FanInsideValueBT       : std_logic_vector( 7 downto 0) := (others => '0');
  signal PWM2FanOutsideValueBT      : std_logic_vector( 7 downto 0) := (others => '0');
  signal PWM3LightValueBT           : std_logic_vector( 7 downto 0) := (others => '0');
  signal PWM4PeltierValueBT         : std_logic_vector( 7 downto 0) := (others => '0');
  signal PeltierDirectionBT         : std_logic                     := '0';
  signal PWM1FanInsideValueControl  : std_logic_vector( 7 downto 0) := (others => '0');
  signal PWM2FanOutsideValueControl : std_logic_vector( 7 downto 0) := (others => '0');
  signal PWM3LightValueControl      : std_logic_vector( 7 downto 0) := (others => '0');
  signal PWM4PeltierValueControl    : std_logic_vector( 7 downto 0) := (others => '0');
  signal PeltierDirectionControl    : std_logic                     := '0';
  signal ControlLightDiffOut        : unsigned(12 downto 0)         := (others => '0');
  signal ControlTempDiffOut         : unsigned(12 downto 0)         := (others => '0');

  --Outputs
  signal LEDsOut             : std_logic_vector( 7 downto 0);
  signal SevenSegmentValue   : std_logic_vector(15 downto 0);
  signal PWM1FanInsideValue  : std_logic_vector( 7 downto 0);
  signal PWM2FanOutsideValue : std_logic_vector( 7 downto 0);
  signal PWM3LightValue      : std_logic_vector( 7 downto 0);
  signal PWM4PeltierValue    : std_logic_vector( 7 downto 0);
  signal PeltierDirection    : std_logic;

  -- Clock period definitions
  constant Clock_period      : time := 10 ns;
  constant En3Hz_period      : time := 333.333333333333 ms;

begin

  -- Instantiate the Unit Under Test (UUT)
  uut: actor port map
  (
    Clock                      => Clock,
    En3Hz                      => En3Hz,
    Reset                      => Reset,
    Switches                   => Switches,
    ButtonsIn                  => ButtonsIn,
    SensorVibe                 => SensorVibe,
    SensorDoor                 => SensorDoor,
    ADCRegister                => ADCRegister,
    LEDsOut                    => LEDsOut,
    SevenSegmentValue          => SevenSegmentValue,
    PWM1FanInsideValue         => PWM1FanInsideValue,
    PWM2FanOutsideValue        => PWM2FanOutsideValue,
    PWM3LightValue             => PWM3LightValue,
    PWM4PeltierValue           => PWM4PeltierValue,
    PeltierDirection           => PeltierDirection,
    LEDsBT                     => LEDsBT,
    SevenSegmentValueBT        => SevenSegmentValueBT,
    PWM1FanInsideValueBT       => PWM1FanInsideValueBT,
    PWM2FanOutsideValueBT      => PWM2FanOutsideValueBT,
    PWM3LightValueBT           => PWM3LightValueBT,
    PWM4PeltierValueBT         => PWM4PeltierValueBT,
    PeltierDirectionBT         => PeltierDirectionBT,
    PWM1FanInsideValueControl  => PWM1FanInsideValueControl,
    PWM2FanOutsideValueControl => PWM2FanOutsideValueControl,
    PWM3LightValueControl      => PWM3LightValueControl,
    PWM4PeltierValueControl    => PWM4PeltierValueControl,
    PeltierDirectionControl    => PeltierDirectionControl,
    ControlLightDiffOut        => ControlLightDiffOut,
    ControlTempDiffOut         => ControlTempDiffOut
  );

  -- emulate the default clock
  process
  begin
    Clock <= '0';
    wait for Clock_period/2;
    Clock <= '1';
    wait for Clock_period/2;
  end process;

  -- emulate the 3Hz clock
  process
  begin
    En3Hz <= '0';
    wait for En3Hz_period/2;
    En3Hz <= '1';
    wait for En3Hz_period/2;
  end process;

  process
  begin

    Switches(7) <= '1';

    Reset <= '1';
    wait for 2 ms;
    Reset <= '0';
    wait for 8 ms;

    -- press button(0) every 10 ms
    loop
      ButtonsIn(0) <= '1';
      wait for 2 ms;
      ButtonsIn(0) <= '0';
      wait for 8 ms;
    end loop;

    wait;
  end process;

end architecture;
