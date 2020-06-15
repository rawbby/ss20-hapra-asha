library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ashatypes.all;

entity actor is
  port
  (
    Clock               : in  std_logic;                      --! Taktsignal
    En3Hz               : in  std_logic;
    Reset               : in  std_logic;                      --! Resetsignal
    Switches            : in  std_logic_vector ( 7 downto 0); --! Die 8 Schalter
    ButtonsIn           : in  std_logic_vector ( 3 downto 0); --! Die 4 Buttons
    SensorVibe          : in  std_logic;                      --! Vibrationssensor vom Haus
    SensorDoor          : in  std_logic;                      --! Eingang Tuersensor
    ADCRegister         : in  ADCRegisterType;                --! Datenregister -> ADC-Werte
    
    LEDsOut             : out std_logic_vector ( 7 downto 0); --! Die 8 LEDs
    SevenSegmentValue   : out std_logic_vector (15 downto 0); --! Eingang der Siebensegmentanzeigen
    PWM1FanInsideValue  : out std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter Innen
    PWM2FanOutsideValue : out std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter Aussen
    PWM3LightValue      : out std_logic_vector ( 7 downto 0); --! Signalquellwert Licht
    PWM4PeltierValue    : out std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier
    PeltierDirection    : out std_logic;                      --! Peltier Richtung (1 = Heizen/ 0 = Kuehlen)

    ----- Werte von Bluetooth
    LEDsBT                : in std_logic_vector ( 7 downto 0); --! Die 8 LEDs des Bluetooth Modules
    SevenSegmentValueBT   : in std_logic_vector (15 downto 0); --! Eingang der Siebensegmentanzeigen des Bluetooth Modules
    PWM1FanInsideValueBT  : in std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter Innen des Bluetooth Modules
    PWM2FanOutsideValueBT : in std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter Aussen des Bluetooth Modules
    PWM3LightValueBT      : in std_logic_vector ( 7 downto 0); --! Signalquellwert Licht des Bluetooth Modules
    PWM4PeltierValueBT    : in std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier des Bluetooth Modules
    PeltierDirectionBT    : in std_logic;                      --! Peltier Richtung (1 = Heizen/ 0 = Kuehlen) des Bluetooth Modules

    ----- Werte von Regelung
    PWM1FanInsideValueControl  : in std_logic_vector (7 downto 0); --! PWM Wert Innerer Luefter
    PWM2FanOutsideValueControl : in std_logic_vector (7 downto 0); --! PWM Wert Ausserer Luefter
    PWM3LightValueControl      : in std_logic_vector (7 downto 0); --! PWM Wert Licht
    PWM4PeltierValueControl    : in std_logic_vector (7 downto 0); --! PWM Wert Peltier
    PeltierDirectionControl    : in std_logic;                     --! Peltier Richtung (1 = Heizen/ 0 = Kuehlen)
    ControlLightDiffOut        : in unsigned (12 downto 0);        --! Aktuelle Regeldifferenz Licht
    ControlTempDiffOut         : in unsigned (12 downto 0)         --! Aktuelle Regeldifferenz Temperatur
  );
end entity;

architecture Behavioral of actor is

  type state_t is (DiffTemp, DiffLight, Light, TempIn, TempOut, Vibe); -- DiffTemp is the new init (c) 2020

  -- current state and next state:
  -- used to determine the output values
  signal State          : state_t                        := DiffTemp;
  signal State_Next     : state_t                        := DiffTemp;

  -- next pwm outputs
  signal PWM1_Next      : std_logic_vector ( 7 downto 0) := x"00";
  signal PWM2_Next      : std_logic_vector ( 7 downto 0) := x"00";
  signal PWM3_Next      : std_logic_vector ( 7 downto 0) := x"00";
  signal PWM4_Next      : std_logic_vector ( 7 downto 0) := x"00";
  signal PWM4_Direction : std_logic                      := '0';

  -- next visual outputs
  signal SevSeg_Next    : std_logic_vector (15 downto 0) := x"FFFF";
  signal Leds_Next      : std_logic_vector ( 7 downto 0) := x"00";

begin

  -- update output
  -- synchronized with En3Hz
  process (En3Hz)
  begin
    if rising_edge (En3Hz) then

      State               <= State_Next;

      SevenSegmentValue   <= SevSeg_Next;
      LEDsOut             <= Leds_Next;
      
      PWM1FanInsideValue  <= PWM1_Next;
      PWM2FanOutsideValue <= PWM2_Next;
      PWM3LightValue      <= PWM3_Next;
      PWM4PeltierValue    <= PWM4_Next;
      PeltierDirection    <= PWM4_Direction;
      
    end if;
  end process;

  -- trivial evaluate next values

  PWM1_Next      <= PWM1FanInsideValueControl  when (Switches = "-010001-") else
                    x"ff"                      when (Switches = "-10----1") else
                    x"00";

  PWM2_Next      <= PWM2FanOutsideValueControl when (Switches = "-010001-") else
                    x"ff"                      when (Switches = "-10---1-") else
                    x"00";
                   
  PWM3_Next      <= PWM3LightValueControl      when (Switches = "-01000-1") else
                    x"ff"                      when (Switches = "-10--1--") else
                    x"00";                     

  PWM4_Next      <= PWM4PeltierValueControl    when (Switches = "-010001-") else
                    x"ff"                      when (Switches = "-10-1---") else
                    x"00";                     

  PWM4_Direction <= PeltierDirectionControl    when (Switches = "-010001-") else
                    '1'                        when (Switches = "-10-1---") else 
                    '0';
  
  SevSeg_Next    <= "0000" & ADCRegister(3)                                                              when (State = Light    ) else
                    "0000" & ADCRegister(1)                                                              when (State = TempIn   ) else
                    "0000" & ADCRegister(0)                                                              when (State = TempOut  ) else
                    "000000000000000" & SensorVibe                                                       when (State = Vibe     ) else
                    "000" & PeltierDirectionControl & std_logic_vector(ControlTempDiffOut(11 downto 0))  when (State = DiffTemp ) else
                    "000" & std_logic_vector(ControlLightDiffOut)                                        when (State = DiffLight) else
                    x"ffff";

  Leds_Next      <= "10000000"                     when (State = Light  ) else
                    "01000000"                     when (State = TempIn ) else
                    "00100000"                     when (State = TempOut) else
                    "00010000"                     when (State = Vibe   ) else
                    "00000000";

  -- non trivial state behavior
  process begin
  
    if (Reset = '1') then

      State_Next <= DiffTemp;
      
    elsif (Switches(7) = '0') then
    
      if rising_edge (ButtonsIn(0)) then
        
        if (State_Next = DiffTemp) then
          State_Next <= DiffLight;
        else
          State_Next <= DiffTemp;
        end if;
        
      end if;
      
    elsif (Switches(7) = '1') then
    
      if rising_edge (ButtonsIn(0)) then
        case State is

          when DiffTemp  => State_Next <= Light;
          when DiffLight => State_Next <= Light;

          when Light     => State_Next <= TempIn;
          when TempIn    => State_Next <= TempOut;
          when TempOut   => State_Next <= Vibe;
          when Vibe      => State_Next <= Light;
        end case;
      end if;
    
    end if;

  end process;

end;
