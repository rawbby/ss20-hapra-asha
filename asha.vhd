library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.ashatypes.all;

entity asha is
  port
  (
    --! Taktsignal direkt vom Quarz des Digilent Starterboards.
    ClockIn : in  std_logic;

    -- Auf dem digilent Starterboard vorhandene Elemente
    ButtonsIn            : in  std_logic_vector ( 3 downto 0); --! Die vier Taster
    Switches             : in  std_logic_vector ( 7 downto 0); --! Die acht Schalter
    AN                   : out std_logic_vector ( 3 downto 0); --! Enable-Signale der einzelnen Siebensegmentanzeigen
    LEDsOut              : out std_logic_vector ( 7 downto 0); --! Die acht LEDs
    SevenSegmentOut      : out std_logic_vector ( 6 downto 0); --! Das Signal aller acht Siebensignemtanzeigen

    -- Bluetooth
    BTRXD                : in  std_logic; --! Eingang vom Bluetooth-Adapter
    BTTXD                : out std_logic; --! Ausgang zum Bluetooth-Adapter

    -- Analog Digital Converter
    ADCReceive           : in  std_logic; --! SPI-Signal vom ADC
    ADCClock             : out std_logic; --! Taktsignal des ADC
    ADCSend              : out std_logic; --! SPI-Signal zum ADC
    ADCChipSelect        : out std_logic; --! Enable-Signal fuer den ADC

    -- digitale Sensoren
    SensorVibe           : in  std_logic; --! Eingang: Virbationssensor
    SensorDoor           : in  std_logic; --! Eingang: Tuersensor

    -- Haus-Aktoren
    PWM1FanInsideSignal  : out std_logic; --! Signalausgang (PWM) des inneren Luefters
    PWM2FanOutsideSignal : out std_logic; --! Signalausgang (PWM) des aeusseren Luefters
    PWM3LightSignal      : out std_logic; --! Signalausgang (PWM) der LED (Hausbelaeuchtung)
    PWM4PeltierSignal    : out std_logic; --! Signalausgang (PWM) des Peltiers
    PeltierDirectionOut  : out std_logic; --! Steuerung der Richtung des Peltiers (Heizen/Kuehlen)
    HouseOnOff           : out std_logic  --! Haus-Aktoren komplett an oder aus schalten
  );
end entity;

architecture Behavioral of asha is

  -- General Signals
  signal Reset        : std_logic;
  signal InitialReset : std_logic := '1';

  -- Clock Divider
  signal En3Hz        : std_logic; --!      3Hz-Enable
  signal En195Hz      : std_logic; --!    195Hz-Enable
  signal En6kHz       : std_logic; --!     6kHz-Enable
  signal EnPWMClock   : std_logic; --! PWMClock-Enable
  signal EnADCClock   : std_logic; --! ADCClock-Enable

  -- Debounce
  signal Buttons      : std_logic_vector ( 3 downto 0); --! debounced buttons

  -- ADC
  signal ADCRegister  : ADCRegisterType;                --! Datenregister aller ADC-Werte

  -- SevenSegment
  signal SevenSegmentValue   : std_logic_vector (15 downto 0); --! Eingang der 7SegAnzeige
  signal SevenSegmentValueBT : std_logic_vector (15 downto 0); --! 7Segment von BT

  -- Einsynchronisation fuer UART
  signal BTRXDInternal : std_logic;
  signal BTRXDsync2    : std_logic;
  signal BTTXDInternal : std_logic;

  -- Memory Access - DI=DeviceInfo DN=DeviceName
  signal DIMemAddr : std_logic_vector ( 5 downto 0); --! Adresse ganzes Payload
  signal DIMemData : std_logic_vector (82 downto 0); --! Payload 5-13 + 11 i2c-Addr.bits
  signal DNMemAddr : std_logic_vector (11 downto 0); --! 64 Bytes pro Sensor (4bit Offset plus 8Bit Sensoren)
  signal DNMemData : std_logic_vector ( 7 downto 0); --! Ein Byte des Namens

  -- Bluetooth
  signal Ready2Send : std_logic; --! ready to send new char
  signal DoWrite    : std_logic; --! set to send new char

  signal RxFin  : std_logic;                      --! char received
  signal RXData : std_logic_vector ( 7 downto 0); --! received char
  signal TXData : std_logic_vector ( 7 downto 0); --! char to send

  -- CRC Generierung
  signal DoCRCIn          : std_logic;
  signal DoCRCOut         : std_logic;
  signal CRCInReset       : std_logic;
  signal CRCOutReset      : std_logic;
  signal CRCIn            : std_logic_vector (15 downto 0);
  signal CRCOut           : std_logic_vector (15 downto 0);
  signal CRCValueReceived : std_logic_vector (15 downto 0);

  -- Actors
  signal PWM1FanInsideValue         : std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter innen
  signal PWM2FanOutsideValue        : std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter aussen
  signal PWM3LightValue             : std_logic_vector ( 7 downto 0); --! Signalquellwert Licht
  signal PWM4PeltierValue           : std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier
  signal PeltierDirection           : std_logic;
  signal PWM1FanInsideValueBT       : std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter innen
  signal PWM2FanOutsideValueBT      : std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter aussen
  signal PWM3LightValueBT           : std_logic_vector ( 7 downto 0); --! Signalquellwert Licht
  signal PWM4PeltierValueBT         : std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier
  signal PeltierDirectionBT         : std_logic;
  signal PWM1FanInsideValueControl  : std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter innen
  signal PWM2FanOutsideValueControl : std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter aussen
  signal PWM3LightValueControl      : std_logic_vector ( 7 downto 0); --! Signalquellwert Licht
  signal PWM4PeltierValueControl    : std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier
  signal PeltierDirectionControl    : std_logic;
  signal LEDs                       : std_logic_vector ( 7 downto 0); --! Die acht LEDs
  signal BTHouseOn                  : std_logic;
  signal SensorHouseOnOff           : std_logic;

  -- Regelungswerte
  signal ControlTempDiff       : unsigned (12 downto 0);
  signal ControlLightDiff      : unsigned (12 downto 0);
  signal ControlTempTarget     : unsigned (11 downto 0);
  signal ControlLightTarget    : unsigned (11 downto 0);
  signal ControlTempTargetAct  : unsigned (11 downto 0);
  signal ControlLightTargetAct : unsigned (11 downto 0);
  signal ControlTempTargetBT   : unsigned (11 downto 0);
  signal ControlLightTargetBT  : unsigned (11 downto 0);
  signal ControlTemp           : std_logic;
  signal ControlLight          : std_logic;
  signal ControlTempAct        : std_logic;
  signal ControlLightAct       : std_logic;
  signal ControlTempBT         : std_logic;
  signal ControlLightBT        : std_logic;

  -- Clock Divider
  component clockdiv is
    port
    (
      Clock      : in  std_logic; --! clock signal
      Reset      : in  std_logic; --! reset signal
      En3Hz      : out std_logic; --! 3Hz-Enable
      En195Hz    : out std_logic; --! 195Hz-Enable
      En6kHz     : out std_logic; --! 6kHz-Enable
      EnPWMClock : out std_logic; --! PWMClock-Enable
      EnADCClock : out std_logic  --! ADCClock-Enable
    );
  end component;

  -- Entprellung
  component Debounce is
    port
    (
      clk    : in  std_logic;                      --! Taktsignal
      keyin  : in  std_logic_vector ( 3 downto 0); --! bouncing input
      keyout : out std_logic_vector ( 3 downto 0)  --! debounced output
    );
  end component;

  -- ADC
  component AshaADC is
    port
    (
      Clock         : in  std_logic;       --! Taktsignal
      Reset         : in  std_logic;       --! Resetsignal
      ADCClockIn    : in  std_logic;       --! Taktsignal fuer den ADC
      ADCReceive    : in  std_logic;       --! Datenleitung vom externen ADC
      ADCSend       : out std_logic;       --! Datenleitung zum externen ADC
      ADCChipSelect : out std_logic;       --! Chipselect-Leitung zum externen ADC
      ADCRegister   : out ADCRegisterType; --! Datenregister aller ADC-Werte
      ADCClockOut   : out std_logic        --! Taktsignal fuer den ADC
    );
  end component;

  -- 7Segment
  component AshaSiebensegment is
    port
    (
      Clock               : in  std_logic;                      --! Taktsignal
      Reset               : in  std_logic;                      --! Resetsignal
      EnSevenSegmentClock : in  std_logic;                      --! Enable-Signal des Treiberprozesses
      SevenSegmentValue   : in  std_logic_vector (15 downto 0); --! der Wert, der auf der Anzeige erscheinen soll
      AN                  : out std_logic_vector ( 3 downto 0); --! Enable-Signale der einzelnen 7-Segment-Anzeigen
      SevenSegment        : out std_logic_vector ( 6 downto 0)  --! treibt die 7-Segment-Anzeigen; alle, bei denen AN aktiviert ist
    );
  end component;

  -- Actor Module for 7Segment, LEDs and others actors
  component actor is
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
      PWM1FanInsideValueControl  : in std_logic_vector ( 7 downto 0); --! PWM Wert Innerer Luefter
      PWM2FanOutsideValueControl : in std_logic_vector ( 7 downto 0); --! PWM Wert Ausserer Luefter
      PWM3LightValueControl      : in std_logic_vector ( 7 downto 0); --! PWM Wert Licht
      PWM4PeltierValueControl    : in std_logic_vector ( 7 downto 0); --! PWM Wert Peltier
      PeltierDirectionControl    : in std_logic;                      --! Peltier Richtung (1 = Heizen/ 0 = Kuehlen)
      ControlLightDiffOut        : in unsigned (12 downto 0);         --! Aktuelle Regeldifferenz Licht
      ControlTempDiffOut         : in unsigned (12 downto 0)          --! Aktuelle Regeldifferenz Temperatur
    );
  end component;

  -- UART Module for Bluetooth
  component AshaUART is
    port
    (
      Clock      : in  std_logic;                      --! Taktsignal
      Reset      : in  std_logic;                      --! Resetsignal
      RXD        : in  std_logic;                      --! Serieller Eingang
      DoWrite    : in  std_logic;                      --! Signalisiert, dass DataIn gesendet werden soll
      DataIn     : in  std_logic_vector ( 7 downto 0); --! Dateneingang des Moduls
      DataOut    : out std_logic_vector ( 7 downto 0); --! Datenausgang des Moduls
      TXD        : out std_logic;                      --! Serieller Ausgang
      Ready2Send : out std_logic;                      --! Signalisiert, dass die UART sendebereit ist
      RxFin      : out std_logic                       --! Signalisiert, dass DataOut neue Daten enthaelt
    );
  end component;

  --bluetooth Paketverwaltung
  component bluetooth is
    port
    (
      -- Memory Access - DI=DeviceInfo DN=DeviceName
      RXData                 : in  std_logic_vector ( 7 downto 0); --! received char
      Ready2Send             : in  std_logic;                      --! ready to send new char
      DIMemData              : in  std_logic_vector (82 downto 0); --! Payload 5-13 + 11 i2c-Addr.bits
      DNMemData              : in  std_logic_vector ( 7 downto 0); --! Ein Byte des Namens
      ClockIn                : in  std_logic;
      RxFin                  : in  std_logic;
      Reset                  : in  std_logic;
      Buttons                : in  std_logic_vector ( 3 downto 0); --! debounced buttons
      Switches               : in  std_logic_vector ( 7 downto 0); --! Die acht Schalter
      ADCRegister            : in  ADCRegisterType;                --! Datenregister aller ADC-Werte
      SensorDoor             : in  std_logic;                      --! Eingang: Tuersensor
      PWM1FanInsideValue     : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter innen
      PWM2FanOutsideValue    : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter aussen
      PWM3LightValue         : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Licht
      PWM4PeltierValue       : in  std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier
      PeltierDirection       : in  std_logic;
      ControlTempDiff        : in  unsigned (12 downto 0);
      ControlLightDiff       : in  unsigned (12 downto 0);
      TXData                 : out std_logic_vector ( 7 downto 0); --! char to send
      DoWrite                : out std_logic;                      --! set to send new char
      DIMemAddr              : out std_logic_vector ( 5 downto 0); --! Adresse ganzes Payload
      DNMemAddr              : out std_logic_vector (11 downto 0);
      CRCInReset             : out std_logic;
      CRCOutReset            : out std_logic;
      DoCRCIn                : out std_logic;
      DoCRCOut               : out std_logic;
      LEDsOut                : out std_logic_vector ( 7 downto 0); --! Die acht LEDs
      SevenSegmentValueOut   : out std_logic_vector (15 downto 0); --! Eingang der 7SegAnzeige
      PWM1FanInsideValueOut  : out std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter innen, von BT
      PWM2FanOutsideValueOut : out std_logic_vector ( 7 downto 0); --! Signalquellwert Luefter aussen, von BT
      PWM3LightValueOut      : out std_logic_vector ( 7 downto 0); --! Signalquellwert Licht, von BT
      PWM4PeltierValueOut    : out std_logic_vector ( 7 downto 0); --! Signalquellwert Peltier, von BT
      PeltierDirectionOut    : out std_logic;
      BTHouseOn              : out std_logic;
      ControlTempTargetOut   : out unsigned (11 downto 0);
      ControlLightTargetOut  : out unsigned (11 downto 0);
      ControlTemp            : out std_logic;
      ControlLight           : out std_logic;
      CRCIn                  :     std_logic_vector (15 downto 0);
      CRCOut                 :     std_logic_vector (15 downto 0)
    );
  end component;

  -- CRC-Modul
  component AshaCRC16
    port
    (
      Clock    : in  std_logic;
      Reset    : in  std_logic;
      NextData : in  std_logic;
      InByte   : in  std_logic_vector ( 7 downto 0);
      CRCOut   : out std_logic_vector (15 downto 0)
    );
  end component;

   -- Das deviceinfo enthaelt moch Platz fuer die angedachte i2c-Adresse (11 bit)
   -- der wird aber zurzeit nicht genutzt und produziert eine compiler-warnung.
  component deviceinfo
    port
    (
      clka  : IN  std_logic;
      addra : IN  std_logic_vector( 5 downto 0);
      douta : OUT std_logic_vector(82 downto 0)
    );
  end component;

  component devicename
    port
    (
      clka  : IN  std_logic;
      addra : IN  std_logic_vector (11 downto 0);
      douta : OUT std_logic_vector ( 7 downto 0)
    );
  end component;

  component AshaPWM
    port
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
  end component;

  -- Vibrationssensor
  component AshaVibe is
    port
    (
      Clock             : in  std_logic; --! Taktsignal
      Reset             : in  std_logic; --! Resetsignal
      SensorVibe        : in  std_logic; --! Vibrationssensorsignal direkt vom Haus
      SensorVibeHouseOn : out std_logic  --! Haus an/aus-Signal des Vibe-Moduls
    );
  end component;

  --Regelung
  component AshaRegelung is
    port
    (
      Clock                      : in  std_logic;                      --! Taktsignal
      Reset                      : in  std_logic;                      --! Resetsignal
      EnClockLight               : in  std_logic;                      --! Enable-Signal fuer die Lichtregelung
      EnClockTemp                : in  std_logic;                      --! Enable-Signal fuer die Temperaturregelung
      SensordataLight            : in  std_logic_vector (11 downto 0); --! Aktuelle Lichtwerte
      SensordataTempIn           : in  std_logic_vector (11 downto 0); --! Aktuelle Innentemperatur
      SensordataTempOut          : in  std_logic_vector (11 downto 0); --! Aktuelle Auentemperatur
      PWM1FanInsideValueControl  : out std_logic_vector ( 7 downto 0); --! PWM-Wert innerere Luefter
      PWM2FanOutsideValueControl : out std_logic_vector ( 7 downto 0); --! PWM-Wert aeusserer Luefter
      PWM3LightValueControl      : out std_logic_vector ( 7 downto 0); --! PWM-Wert Licht
      PWM4PeltierValueControl    : out std_logic_vector ( 7 downto 0); --! PWM-Wert Peltier
      PeltierDirectionControl    : out std_logic;                      --! Pelier Richtung heizen (=1)/kuehlen(=0)
      ControlLightDiffOut        : out unsigned (12 downto 0);         --! Aktuelle Regeldifferenz Licht
      ControlTempDiffOut         : out unsigned (12 downto 0)          --! Aktuelle Regeldifferenz Temperatur
    );
  end component;

begin

  -- Clock Divider
  ClockDivider : clockdiv
  port map
  (
    Clock      => ClockIn,    --! clock signal
    Reset      => Reset,      --! reset signal
    En3Hz      => En3Hz,      --! 3Hz-Enable
    En195Hz    => En195Hz,    --! 195Hz-Enable
    En6kHz     => En6kHz,     --! 6kHz-Enable
    EnPWMClock => EnPWMClock, --! PWMClock-Enable
    EnADCClock => EnADCClock  --! PWMClock-Enable
  );

  -- Entprellung
  Debouncing : Debounce
  port map
  (
    clk    => ClockIn,   --! Taktsignal
    keyin  => ButtonsIn, --! bouncing buttons
    keyout => Buttons    --! debounced buttons
  );

  -- ADC
  ADC : AshaADC
  port map
  (
    Clock         => ClockIn,    --! Taktsignal
    Reset         => Reset,      --! Resetsignal
    ADCClockIn    => EnADCClock, --! debounced buttons
    ADCReceive    => ADCReceive,
    ADCSend       => ADCSend,
    ADCChipSelect => ADCChipSelect,
    ADCRegister   => ADCRegister,
    ADCClockOut   => ADCClock
  );

  -- 7Segment
  SevenSegment : AshaSiebensegment
  port map
  (
    Clock              => ClockIn,           --! Taktsignal
    Reset              => Reset,             --! Resetsignal
    EnSevenSegmentClock=> En6kHz,            --! Enable-Signal des Treiberprozesses
    SevenSegmentValue  => SevenSegmentValue, --! der Wert, der auf der Anzeige erscheinen soll
    AN                 => AN,                --! Enable-Signale der einzelnen 7-Segment-Anzeigen
    SevenSegment       => SevenSegmentOut    --! treibt die 7-Segment-Anzeigen; alle, bei denen AN aktiviert ist
  );

  -- Actor
  ActorModule : actor
  port map
  (
    Clock               => ClockIn,
    En3Hz               => En3Hz,
    Reset               => Reset,
    Switches            => Switches,
    ButtonsIn           => Buttons,
    SensorVibe          => SensorVibe,
    SensorDoor          => SensorDoor,
    ADCRegister         => ADCRegister,
    LEDsOut             => LEDsOut,
    SevenSegmentValue   => SevenSegmentValue,
    PWM1FanInsideValue  => PWM1FanInsideValue,
    PWM2FanOutsideValue => PWM2FanOutsideValue,
    PWM3LightValue      => PWM3LightValue,
    PWM4PeltierValue    => PWM4PeltierValue,
    PeltierDirection    => PeltierDirection,

    ----- Werte von Bluetooth
    LEDsBT                => LEDs,
    SevenSegmentValueBT   => SevenSegmentValueBT,
    PWM1FanInsideValueBT  => PWM1FanInsideValueBT,
    PWM2FanOutsideValueBT => PWM2FanOutsideValueBT,
    PWM3LightValueBT      => PWM3LightValueBT,
    PWM4PeltierValueBT    => PWM4PeltierValueBT,
    PeltierDirectionBT    => PeltierDirectionBT,

    ----- Werte von Regelung
    PWM1FanInsideValueControl  => PWM1FanInsideValueControl,
    PWM2FanOutsideValueControl => PWM2FanOutsideValueControl,
    PWM3LightValueControl      => PWM3LightValueControl,
    PWM4PeltierValueControl    => PWM4PeltierValueControl,
    PeltierDirectionControl    => PeltierDirectionControl,
    ControlLightDiffOut        => ControlLightDiff,
    ControlTempDiffOut          => ControlTempDiff
  );

  -- UART
  UART : AshaUART
  port map
  (
    Clock      => ClockIn,       --! Taktsignal
    Reset      => Reset,         --! Resetsignal
    DataIn     => TXData,        --! Dateneingang des Moduls
    DataOut    => RXData,        --! Datenausgang des Moduls
    RXD        => BTRXDInternal, --! Serieller Eingang
    TXD        => BTTXDInternal, --! Serieller Ausgang
    DoWrite    => DoWrite,       --! Signalisiert, dass DataIn gesendet werden soll
    Ready2Send => Ready2Send,    --! Signalisiert, dass die UART sendebereit ist
    RxFin      => RxFin          --! Signalisiert, dass DataOut neue Daten enthaelt
  );

  -- Bluetooth Paketverwaltung
  BluetoothModule : bluetooth
  port map
  (
    -- Memory Access - DI=DeviceInfo DN=DeviceName
    RXData                 => RXData,     --! received char
    TXData                 => TXData,     --! char to send
    Ready2Send             => Ready2Send, --! ready to send new char
    DoWrite                => DoWrite,    --! set to send new char
    DIMemAddr              => DIMemAddr,  --! Adresse ganzes Payload
    DIMemData              => DIMemData,  --! Payload 5-13 + 11 i2c-Addr.bits
    DNMemAddr              => DNMemAddr,
    DNMemData              => DNMemData,  --! Ein Byte des Namens
    ClockIn                => ClockIn,
    RxFin                  => RxFin,
    Reset                  => Reset,
    CRCInReset             => CRCInReset,
    CRCOutReset            => CRCOutReset,
    DoCRCIn                => DoCRCIn,
    DoCRCOut               => DoCRCOut,
    LEDsOut                => LEDs,                  --! Die acht LEDs
    Buttons                => Buttons,               --! debounced buttons
    Switches               => Switches,              --! Die acht Schalter
    SevenSegmentValueOut   => SevenSegmentValueBT,   --! Eingang der 7SegAnzeige
    ADCRegister            => ADCRegister,           --! Datenregister aller ADC-Werte
    SensorDoor             => SensorDoor,            --! Eingang: Tuersensor
    PWM1FanInsideValue     => PWM1FanInsideValue,    --! Signalquellwert Luefter innen
    PWM2FanOutsideValue    => PWM2FanOutsideValue,   --! Signalquellwert Luefter aussen
    PWM3LightValue         => PWM3LightValue,        --! Signalquellwert Licht
    PWM4PeltierValue       => PWM4PeltierValue,      --! Signalquellwert Peltier
    PeltierDirection       => PeltierDirection,
    PWM1FanInsideValueOut  => PWM1FanInsideValueBT,  --! Signalquellwert Luefter innen, von BT
    PWM2FanOutsideValueOut => PWM2FanOutsideValueBT, --! Signalquellwert Luefter aussen, von BT
    PWM3LightValueOut      => PWM3LightValueBT,      --! Signalquellwert Licht, von BT
    PWM4PeltierValueOut    => PWM4PeltierValueBT,    --! Signalquellwert Peltier, von BT
    PeltierDirectionOut    => PeltierDirectionBT,    --! Signalquellwert Peltier Richtung, von BT
    BTHouseOn              => BTHouseOn,
    ControlTempDiff        => ControlTempDiff,
    ControlLightDiff       => ControlLightDiff,
    ControlTempTargetOut   => ControlTempTargetBT,
    ControlLightTargetOut  => ControlLightTargetBT,
    ControlTemp            => ControlTempBT,
    ControlLight           => ControlLightBT,
    CRCIn                  => CRCIn,
    CRCOut                 => CRCOut
  );

  ModuleCRCIn : AshaCRC16
  port map
  (
    Clock    => ClockIn,
    Reset    => CRCInReset,
    NextData => DoCRCIn,
    InByte   => RXData,
    CRCOut   => CRCIn
  );

  ModuleCRCOut : AshaCRC16
  port map
  (
    Clock    => ClockIn,
    Reset    => CRCOutReset,
    NextData => DoCRCOut,
    InByte   => TXData,
    CRCOut   => CRCOut
  );

  CoreModuleDeviceInfo : deviceinfo
  port map
  (
    clka  => ClockIn,
    addra => DIMemAddr,
    douta => DIMemData
  );

  CoreModuleDeviceName : devicename
  port map
  (
    clka  => ClockIn,
    addra => DNMemAddr,
    douta => DNMemData
  );

  PWMControl : AshaPWM
  port map
  (
    Clock                => ClockIn,              --! Taktsignal
    Reset                => Reset,                --! Resetsignal
    EnPWMClock           => EnPWMClock,           --! Enable-Signal fuer die PWM-Abarbeitung
    PWM1FanInsideValue   => PWM1FanInsideValue,   --! Signalquellwert Luefter innen
    PWM2FanOutsideValue  => PWM2FanOutsideValue,  --! Signalquellwert Luefter aussen
    PWM3LightValue       => PWM3LightValue,       --! Signalquellwert Licht
    PWM4PeltierValue     => PWM4PeltierValue,     --! Signalquellwert Peltier
    PWM1FanInsideSignal  => PWM1FanInsideSignal,  --! PWM-Aktorsignal Luefter innen
    PWM2FanOutsideSignal => PWM2FanOutsideSignal, --! PWM-Aktorsignal Luefter aussen
    PWM3LightSignal      => PWM3LightSignal,      --! PWM-Aktorsignal Licht
    PWM4PeltierSignal    => PWM4PeltierSignal     --! PWM-Aktorsignal Peltier
  );

  -- Vibrationssensor
  VibeSens : AshaVibe
  port map
  (
      Clock             => ClockIn,         --! Taktsignal
      Reset             => Reset,           --! Resetsignal
      SensorVibe        => SensorVibe,      --! Vibrationssensorsignal direkt vom Haus
      SensorVibeHouseOn => SensorHouseOnOff --! Haus an/aus-Signal des Vibe-Moduls
  );

  -- Regelung
  Regelung : AshaRegelung
  port map
  (
    Clock                      => ClockIn,                    --! Taktsignal
    Reset                      => Reset,                      --! Resetsignal
    EnClockLight               => En195Hz,                    --! Enable-Signal fuer die Lichtregelung
    EnClockTemp                => En3Hz,                      --! Enable-Signal fuer die Temperaturregelung
    SensordataLight            => ADCRegister(3),             --! Aktuelle Lichtwerte
    SensordataTempIn           => ADCRegister(0),             --! Aktuelle Innentemperatur
    SensordataTempOut          => ADCRegister(1),             --! Aktuelle Auentemperatur
    PWM1FanInsideValueControl  => PWM1FanInsideValueControl,  --! PWM-Wert innerer Luefter
    PWM2FanOutsideValueControl => PWM2FanOutsideValueControl, --! PWM-Wert aeusserer Luefter
    PWM3LightValueControl      => PWM3LightValueControl,      --! PWM-Wert Licht
    PWM4PeltierValueControl    => PWM4PeltierValueControl,    --! PWM-Wert Peltier
    PeltierDirectionControl    => PeltierDirectionControl,    --! Pelier Richtung heizen (=1)/kuehlen(=0)
    ControlLightDiffOut        => ControlLightDiff,           --! Aktuelle Regeldifferenz Licht
    ControlTempDiffOut         => ControlTempDiff             --! Aktuelle Regeldifferenz Temperatur
  );

  -- nebenlaeufige Anweisungen: Zuweisungen Reset, HouseOnOff, PeltierDirection
  Reset               <= (Buttons(3) or InitialReset);
  HouseOnOff          <= (BTHouseOn and SensorHouseOnOff);
  PeltierDirectionOut <= PeltierDirection;

  -- TXD kann so vom internen ins aeussere uebergeben werden
  BTTXD               <= BTTXDInternal;

  --! Initiales Reset
  -- Loest nach der Programmierung einen Reset aller Signale aus,
  -- bis er sich selber abschaltet.
  process (ClockIn)
  begin
    if rising_edge(ClockIn) then
      if (InitialReset='1') then
        InitialReset<='0';
      end if;
    end if;
  end process;

  --! Einsynchronisierung RXD
  process (ClockIn)
  begin
    if rising_edge(ClockIn) then
      BTRXDsync2    <= BTRXD;
      BTRXDInternal <= BTRXDsync2;
    end if;
  end process;

end;
