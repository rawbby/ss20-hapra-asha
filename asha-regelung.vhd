library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ashatypes.all;

--! @brief ASHA-Modul - Regelung
--! @details Dieses Modul enthaelt die Regelung
entity AshaRegelung is
  port
  (
    Clock                      : in  std_logic;                      --! Taktsignal
    Reset                      : in  std_logic;                      --! Resetsignal
    EnClockLight               : in  std_logic;                      --! Enable-Signal fuer die Lichtregelung
    EnClockTemp                : in  std_logic;                      --! Enable-Signal fuer die Temperaturregelung
    SensordataLight            : in  std_logic_vector (11 downto 0); --! Aktuelle Lichtwerte
    SensordataTempIn           : in  std_logic_vector (11 downto 0); --! (TODO) Aktuelle Innentemperatur
    SensordataTempOut          : in  std_logic_vector (11 downto 0); --! Aktuelle Außentemperatur
    PWM1FanInsideValueControl  : out std_logic_vector ( 7 downto 0); --! (TODO) PWM-Wert innerere Luefter
    PWM2FanOutsideValueControl : out std_logic_vector ( 7 downto 0); --! PWM-Wert aeusserer Luefter
    PWM3LightValueControl      : out std_logic_vector ( 7 downto 0); --! PWM-Wert Licht
    PWM4PeltierValueControl    : out std_logic_vector ( 7 downto 0); --! (TODO) PWM-Wert Peltier
    PeltierDirectionControl    : out std_logic;                      --! Pelier Richtung heizen (=1)/kuehlen(=0)
    ControlLightDiffOut        : out unsigned (12 downto 0);         --! 7Seg Aktuelle Regeldifferenz Licht
    ControlTempDiffOut         : out unsigned (12 downto 0)          --! 7Seg Aktuelle Regeldifferenz Temperatur
  );
end AshaRegelung;

architecture Behavioral of AshaRegelung is

  -- constants for pwms
  constant PwmControl_On      : std_logic_vector ( 7 downto 0) := "11111111";
  constant PwmControl_Half    : std_logic_vector ( 7 downto 0) := "10000000";
  constant PwmControl_Some    : std_logic_vector ( 7 downto 0) := "11000000";
  constant PwmControl_Quarter : std_logic_vector ( 7 downto 0) := "01000000";
  constant PwmControl_Off     : std_logic_vector ( 7 downto 0) := "00000000";

  -- constants for the light readout
  constant Light_10Lux  : std_logic_vector (11 downto 0) := "111111011010"; -- FDA -- 4058
  constant Light_50Lux  : std_logic_vector (11 downto 0) := "111101001000"; -- F48 -- 3912
  constant Light_200Lux : std_logic_vector (11 downto 0) := "110100100100"; -- D24 -- 3364

  -- constants for the temperature readout
  constant Temp_DiffTolerance : unsigned (11 downto 0) := "000000010000"; -- 16 - 2 Grad Celsius
  
  -- clockdiv to enable update every second
  signal   Count          : unsigned(25 downto 0) := "00000000000000000000000000";
  constant Bound          : unsigned(25 downto 0) := "10111110101111000010000000"; -- 50000000

  -- output buffer - set ecery second to output
  signal FanInsideControl_Buffer  : std_logic_vector ( 7 downto 0);
  signal FanOutsideControl_Buffer : std_logic_vector ( 7 downto 0);
  signal PeltierDirection_Buffer  : std_logic;
  signal TempDiff_Buffer          : unsigned (11 downto 0);
  
begin

  process begin
    wait until rising_edge(Clock);

    -- update the outputs every second
    if (Count = (Bound-1)) then
      Count <= "00000000000000000000000000";

      ControlTempDiffOut         <= "0" & TempDiff_Buffer;
      PWM2FanOutsideValueControl <= FanOutsideControl_Buffer;
      PWM1FanInsideValueControl  <= FanInsideControl_Buffer;
      PeltierDirectionControl    <= PeltierDirection_Buffer;

    else
      Count <= Count + 1;
    end if;

  end process;

  -- logic gates for ligth - set directly to output without buffer

  ControlLightDiffOut      <= "0000000010000" when (SensordataLight > Light_10Lux    ) else
                              "0000001010000" when (SensordataLight > Light_50Lux    ) else
                              "0001000000000" when (SensordataLight > Light_200Lux   ) else
                              "0000000000000";

  PWM3LightValueControl    <= -- PwmControl_Off     when (Reset = '1' or EnClockLight = '0') else
                              PwmControl_On      when (SensordataLight > Light_10Lux    ) else
                              PwmControl_Half    when (SensordataLight > Light_50Lux    ) else
                              PwmControl_Quarter when (SensordataLight > Light_200Lux   ) else
                              PwmControl_Off;

  -- buffered logic gatte

  TempDiff_Buffer          <= unsigned(SensordataTempIn)  - unsigned(SensordataTempOut) when (SensordataTempIn > SensordataTempOut) else
                              unsigned(SensordataTempOut) - unsigned(SensordataTempIn);

  PeltierDirection_Buffer  <= '0' when (SensordataTempIn > SensordataTempOut) else
                              '1';

  FanOutsideControl_Buffer <= PwmControl_On when (TempDiff_Buffer >= Temp_DiffTolerance) else
                              PwmControl_Some;

  FanInsideControl_Buffer  <= PwmControl_On when (TempDiff_Buffer >= Temp_DiffTolerance) else
                              PwmControl_Some;

end Behavioral;
