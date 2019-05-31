library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fixed_pkg.all;
use work.float_pkg.all;
use work.constantspackage.all;
use work.vpfrecords.all;
use work.portspackage.all;
entity ImageKernel is
generic (
    SHARP_FRAME   : boolean := false;
    BLURE_FRAME   : boolean := false;
    EMBOS_FRAME   : boolean := false;
    YCBCR_FRAME   : boolean := false;
    SOBEL_FRAME   : boolean := false;
    CGAIN_FRAME   : boolean := false;
    img_width     : integer := 4096;
    i_data_width  : integer := 8);
port (
    clk                   : in std_logic;
    rst_l                 : in std_logic;
    iRgb                  : in channel;
    als                   : in coefficient;
    oEdgeValid            : out std_logic;
    oRgb                  : out colors);
end ImageKernel;
architecture arch of ImageKernel is
    signal threshold      : sfixed(9 downto 0) := "0100000000";
    signal fract          : float32;
    signal thresholdFl    : float32;
    signal sobel_pax      : std_logic_vector(7 downto 0)  := x"00";
    signal sobel_pay      : std_logic_vector(7 downto 0)  := x"00";
    signal rgbMac1        : tpToFloatRecord;
    signal rgbMac2        : tpToFloatRecord;
    signal rgbMac3        : tpToFloatRecord;
    signal rgbMac         : tpToFloatRecord;
    signal rgbHsv         : channel;
    signal hsv            : hsvChannel;
begin
    ---------------------------------------------------------
    thresholdFl         <= to_float ((threshold), thresholdFl);
    fract               <= to_float ((0.001), fract);
    ---------------------------------------------------------
hsvInst: hsv_c
generic map(
    i_data_width       => i_data_width)
port map(   
    clk                => clk,
    reset              => rst_l,
    iRgb               => iRgb,
    oHsv               => hsv);
    oRgb.hsv.red       <= hsv.h;
    oRgb.hsv.green     <= hsv.s;
    oRgb.hsv.blue      <= hsv.v;
    oRgb.hsv.valid     <= hsv.valid;
TPDATAWIDTH3_ENABLED: if ((SHARP_FRAME = TRUE) or (BLURE_FRAME = TRUE) or (EMBOS_FRAME = TRUE)) generate
    signal tp0        : std_logic_vector(23 downto 0) := (others => '0');
    signal tp1        : std_logic_vector(23 downto 0) := (others => '0');
    signal tp2        : std_logic_vector(23 downto 0) := (others => '0');
    signal tpValid    : std_logic  := lo;
begin
TapsControllerInst: TapsController
generic map(
    img_width    => img_width,
    tpDataWidth  => 24)
port map(
    clk          => clk,
    rst_l        => rst_l,
    iRgb         => iRgb,
    tpValid      => tpValid,
    tp0          => tp0,
    tp1          => tp1,
    tp2          => tp2);
process (clk,rst_l) begin
    if (rst_l = lo) then
        rgbMac1.red   <= (others => '0');
        rgbMac1.green <= (others => '0');
        rgbMac1.blue  <= (others => '0');
        rgbMac1.valid <= lo;
    elsif rising_edge(clk) then 
        rgbMac1.red   <= to_float(unsigned(tp0(23 downto 16)), rgbMac1.red);
        rgbMac1.green <= to_float(unsigned(tp1(23 downto 16)), rgbMac1.green);
        rgbMac1.blue  <= to_float(unsigned(tp2(23 downto 16)), rgbMac1.blue);
        rgbMac1.valid <= tpValid;
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        rgbMac2.red   <= (others => '0');
        rgbMac2.green <= (others => '0');
        rgbMac2.blue  <= (others => '0');
        rgbMac2.valid <= lo;
    elsif rising_edge(clk) then 
        rgbMac2.red   <= to_float(unsigned(tp0(15 downto 8)), rgbMac2.red);
        rgbMac2.green <= to_float(unsigned(tp1(15 downto 8)), rgbMac2.green);
        rgbMac2.blue  <= to_float(unsigned(tp2(15 downto 8)), rgbMac2.blue);
        rgbMac2.valid <= tpValid;
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        rgbMac3.red   <= (others => '0');
        rgbMac3.green <= (others => '0');
        rgbMac3.blue  <= (others => '0');
        rgbMac3.valid <= lo;
    elsif rising_edge(clk) then 
        rgbMac3.red   <= to_float(unsigned(tp0(7 downto 0)), rgbMac3.red);
        rgbMac3.green <= to_float(unsigned(tp1(7 downto 0)), rgbMac3.green);
        rgbMac3.blue  <= to_float(unsigned(tp2(7 downto 0)), rgbMac3.blue);
        rgbMac3.valid <= tpValid;
    end if; 
end process;
end generate TPDATAWIDTH3_ENABLED;
TPDATAWIDTH1_ENABLED: if ((SOBEL_FRAME = TRUE)) generate
    signal tp0        : std_logic_vector(7 downto 0) := (others => '0');
    signal tp1        : std_logic_vector(7 downto 0) := (others => '0');
    signal tp2        : std_logic_vector(7 downto 0) := (others => '0');
    signal tpValid    : std_logic  := lo;
begin
TapsControllerInst: TapsController
generic map(
    img_width    => img_width,
    tpDataWidth  => 8)
port map(
    clk          => clk,
    rst_l        => rst_l,
    iRgb         => iRgb,
    tpValid      => tpValid,
    tp0          => tp0,
    tp1          => tp1,
    tp2          => tp2);
process (clk,rst_l) begin
    if (rst_l = lo) then
        rgbMac.red   <= (others => '0');
        rgbMac.green <= (others => '0');
        rgbMac.blue  <= (others => '0');
        rgbMac.valid <= lo;
    elsif rising_edge(clk) then 
        rgbMac.red   <= to_float(unsigned(tp0), rgbMac.red);
        rgbMac.green <= to_float(unsigned(tp1), rgbMac.green);
        rgbMac.blue  <= to_float(unsigned(tp2), rgbMac.blue);
        rgbMac.valid <= tpValid;
    end if; 
end process;
end generate TPDATAWIDTH1_ENABLED;
----------------------------------------------------------------------------------------
--                                SOBELX_FRAME
----------------------------------------------------------------------------------------
SOBELX_FRAME_ENABLED: if (SOBEL_FRAME = true) generate
----------------------------------------------------------------------------------------
--  SobelX
--  |----------------|
--  | -1   +0   +1   |
--  | -2   +0   +2   |
--  | -1   +0   +1   |
--  |----------------|
    signal kSx1            : std_logic_vector(15 downto 0) := x"FC18";--  [-1]
    signal kSx2            : std_logic_vector(15 downto 0) := x"0000";--  [+0]
    signal kSx3            : std_logic_vector(15 downto 0) := x"03E8";--  [+1]
    signal kSx4            : std_logic_vector(15 downto 0) := x"F830";--  [-2]
    signal kSx5            : std_logic_vector(15 downto 0) := x"0000";--  [+0]
    signal kSx6            : std_logic_vector(15 downto 0) := x"07D0";--  [+2]
    signal kSx7            : std_logic_vector(15 downto 0) := x"FC18";--  [-1]
    signal kSx8            : std_logic_vector(15 downto 0) := x"0000";--  [+0]
    signal kSx9            : std_logic_vector(15 downto 0) := x"03E8";--  [+1]
----------------------------------------------------------------------------------------
    signal sobelx          : SobelRecord;
begin
    sobelx.flCoef.k1 <= to_float((signed(kSx1)),sobelx.flCoef.k1);
    sobelx.flCoef.k2 <= to_float((signed(kSx2)),sobelx.flCoef.k2);
    sobelx.flCoef.k3 <= to_float((signed(kSx3)),sobelx.flCoef.k3);
    sobelx.flCoef.k4 <= to_float((signed(kSx4)),sobelx.flCoef.k4);
    sobelx.flCoef.k5 <= to_float((signed(kSx5)),sobelx.flCoef.k5);
    sobelx.flCoef.k6 <= to_float((signed(kSx6)),sobelx.flCoef.k6);
    sobelx.flCoef.k7 <= to_float((signed(kSx7)),sobelx.flCoef.k7);
    sobelx.flCoef.k8 <= to_float((signed(kSx8)),sobelx.flCoef.k8);
    sobelx.flCoef.k9 <= to_float((signed(kSx9)),sobelx.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then
        sobelx.flCoefFract.k1 <= (sobelx.flCoef.k1 * fract * thresholdFl);
        sobelx.flCoefFract.k2 <= (sobelx.flCoef.k2 * fract * thresholdFl);
        sobelx.flCoefFract.k3 <= (sobelx.flCoef.k3 * fract * thresholdFl);
        sobelx.flCoefFract.k4 <= (sobelx.flCoef.k4 * fract * thresholdFl);
        sobelx.flCoefFract.k5 <= (sobelx.flCoef.k5 * fract * thresholdFl);
        sobelx.flCoefFract.k6 <= (sobelx.flCoef.k6 * fract * thresholdFl);
        sobelx.flCoefFract.k7 <= (sobelx.flCoef.k7 * fract * thresholdFl);
        sobelx.flCoefFract.k8 <= (sobelx.flCoef.k8 * fract * thresholdFl);
        sobelx.flCoefFract.k9 <= (sobelx.flCoef.k9 * fract * thresholdFl);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        sobelx.tpd1.vTap0x <= rgbMac.red;
        sobelx.tpd2.vTap0x <= sobelx.tpd1.vTap0x;
        sobelx.tpd3.vTap0x <= sobelx.tpd2.vTap0x;
        sobelx.tpd1.vTap1x <= rgbMac.green;
        sobelx.tpd2.vTap1x <= sobelx.tpd1.vTap1x;
        sobelx.tpd3.vTap1x <= sobelx.tpd2.vTap1x;
        sobelx.tpd1.vTap2x <= rgbMac.blue;
        sobelx.tpd2.vTap2x <= sobelx.tpd1.vTap2x;
        sobelx.tpd3.vTap2x <= sobelx.tpd2.vTap2x;
    end if;
end process;
process (clk) begin 
    if rising_edge(clk) then 
        sobelx.flProd.k1 <= (sobelx.flCoefFract.k1 * sobelx.tpd3.vTap2x);
        sobelx.flProd.k2 <= (sobelx.flCoefFract.k2 * sobelx.tpd2.vTap2x);
        sobelx.flProd.k3 <= (sobelx.flCoefFract.k3 * sobelx.tpd1.vTap2x);
        sobelx.flProd.k4 <= (sobelx.flCoefFract.k4 * sobelx.tpd3.vTap1x);
        sobelx.flProd.k5 <= (sobelx.flCoefFract.k5 * sobelx.tpd2.vTap1x);
        sobelx.flProd.k6 <= (sobelx.flCoefFract.k6 * sobelx.tpd1.vTap1x);
        sobelx.flProd.k7 <= (sobelx.flCoefFract.k7 * sobelx.tpd3.vTap0x);
        sobelx.flProd.k8 <= (sobelx.flCoefFract.k8 * sobelx.tpd2.vTap0x);
        sobelx.flProd.k9 <= (sobelx.flCoefFract.k9 * sobelx.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobelx.flToSnFxProd.k1 <= to_sfixed((sobelx.flProd.k1), sobelx.flToSnFxProd.k1);
        sobelx.flToSnFxProd.k2 <= to_sfixed((sobelx.flProd.k2), sobelx.flToSnFxProd.k2);
        sobelx.flToSnFxProd.k3 <= to_sfixed((sobelx.flProd.k3), sobelx.flToSnFxProd.k3);
        sobelx.flToSnFxProd.k4 <= to_sfixed((sobelx.flProd.k4), sobelx.flToSnFxProd.k4);
        sobelx.flToSnFxProd.k5 <= to_sfixed((sobelx.flProd.k5), sobelx.flToSnFxProd.k5);
        sobelx.flToSnFxProd.k6 <= to_sfixed((sobelx.flProd.k6), sobelx.flToSnFxProd.k6);
        sobelx.flToSnFxProd.k7 <= to_sfixed((sobelx.flProd.k7), sobelx.flToSnFxProd.k7);
        sobelx.flToSnFxProd.k8 <= to_sfixed((sobelx.flProd.k8), sobelx.flToSnFxProd.k8);
        sobelx.flToSnFxProd.k9 <= to_sfixed((sobelx.flProd.k9), sobelx.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobelx.snFxToSnProd.k1 <= to_signed(sobelx.flToSnFxProd.k1(19 downto 0), 20);
        sobelx.snFxToSnProd.k2 <= to_signed(sobelx.flToSnFxProd.k2(19 downto 0), 20);
        sobelx.snFxToSnProd.k3 <= to_signed(sobelx.flToSnFxProd.k3(19 downto 0), 20);
        sobelx.snFxToSnProd.k4 <= to_signed(sobelx.flToSnFxProd.k4(19 downto 0), 20);
        sobelx.snFxToSnProd.k5 <= to_signed(sobelx.flToSnFxProd.k5(19 downto 0), 20);
        sobelx.snFxToSnProd.k6 <= to_signed(sobelx.flToSnFxProd.k6(19 downto 0), 20);
        sobelx.snFxToSnProd.k7 <= to_signed(sobelx.flToSnFxProd.k7(19 downto 0), 20);
        sobelx.snFxToSnProd.k8 <= to_signed(sobelx.flToSnFxProd.k8(19 downto 0), 20);
        sobelx.snFxToSnProd.k9 <= to_signed(sobelx.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobelx.snToTrimProd.k1 <= sobelx.snFxToSnProd.k1(19 downto 5);
        sobelx.snToTrimProd.k2 <= sobelx.snFxToSnProd.k2(19 downto 5);
        sobelx.snToTrimProd.k3 <= sobelx.snFxToSnProd.k3(19 downto 5);
        sobelx.snToTrimProd.k4 <= sobelx.snFxToSnProd.k4(19 downto 5);
        sobelx.snToTrimProd.k5 <= sobelx.snFxToSnProd.k5(19 downto 5);
        sobelx.snToTrimProd.k6 <= sobelx.snFxToSnProd.k6(19 downto 5);
        sobelx.snToTrimProd.k7 <= sobelx.snFxToSnProd.k7(19 downto 5);
        sobelx.snToTrimProd.k8 <= sobelx.snFxToSnProd.k8(19 downto 5);
        sobelx.snToTrimProd.k9 <= sobelx.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        sobelx.snSum.red            <= (others => '0');
        sobelx.snSum.green          <= (others => '0');
        sobelx.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        sobelx.snSum.red   <= resize(sobelx.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                              resize(sobelx.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                              resize(sobelx.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        sobelx.snSum.green <= resize(sobelx.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                              resize(sobelx.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                              resize(sobelx.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        sobelx.snSum.blue  <= resize(sobelx.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                              resize(sobelx.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                              resize(sobelx.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobelx.snToTrimSum.red    <= sobelx.snSum.red(sobelx.snSum.red'left downto FRAC_BITS_TO_KEEP);
        sobelx.snToTrimSum.green  <= sobelx.snSum.green(sobelx.snSum.green'left downto FRAC_BITS_TO_KEEP);
        sobelx.snToTrimSum.blue   <= sobelx.snSum.blue(sobelx.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then
        sobelx.rgbSum            <= (sobelx.snToTrimSum.red + sobelx.snToTrimSum.green + sobelx.snToTrimSum.blue);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        if (sobelx.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
            sobel_pax <= black;
        elsif (unsigned(sobelx.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
            sobel_pax <= white;
        else
            sobel_pax <= std_logic_vector(sobelx.rgbSum(i_data_width-1 downto 0));
        end if;
    end if; 
end process;
end generate SOBELX_FRAME_ENABLED;
----------------------------------------------------------------------------------------
--                                SOBELY_FRAME
----------------------------------------------------------------------------------------
SOBELY_FRAME_ENABLED: if (SOBEL_FRAME = true) generate
----------------------------------------------------------------------------------------
--  SobelY
--  |----------------|
--  | +1   +2   +1   |
--  | +0   +0   +0   |
--  | -1   -2   -1   |
--  |----------------|
    signal kSy1            : std_logic_vector(15 downto 0) := x"03E8";--  +1
    signal kSy2            : std_logic_vector(15 downto 0) := x"07D0";--  +2
    signal kSy3            : std_logic_vector(15 downto 0) := x"03E8";--  +1
    signal kSy4            : std_logic_vector(15 downto 0) := x"0000";--  -2
    signal kSy5            : std_logic_vector(15 downto 0) := x"0000";--  +0
    signal kSy6            : std_logic_vector(15 downto 0) := x"0000";--  +2
    signal kSy7            : std_logic_vector(15 downto 0) := x"FC18";--  -1
    signal kSy8            : std_logic_vector(15 downto 0) := x"F830";--  -2
    signal kSy9            : std_logic_vector(15 downto 0) := x"FC18";--  -1
----------------------------------------------------------------------------------------
    signal sobely          : SobelRecord;
begin
    sobely.flCoef.k1 <= to_float((signed(kSy1)),sobely.flCoef.k1);
    sobely.flCoef.k2 <= to_float((signed(kSy2)),sobely.flCoef.k2);
    sobely.flCoef.k3 <= to_float((signed(kSy3)),sobely.flCoef.k3);
    sobely.flCoef.k4 <= to_float((signed(kSy4)),sobely.flCoef.k4);
    sobely.flCoef.k5 <= to_float((signed(kSy5)),sobely.flCoef.k5);
    sobely.flCoef.k6 <= to_float((signed(kSy6)),sobely.flCoef.k6);
    sobely.flCoef.k7 <= to_float((signed(kSy7)),sobely.flCoef.k7);
    sobely.flCoef.k8 <= to_float((signed(kSy8)),sobely.flCoef.k8);
    sobely.flCoef.k9 <= to_float((signed(kSy9)),sobely.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then
        sobely.flCoefFract.k1 <= (sobely.flCoef.k1 * fract * thresholdFl);
        sobely.flCoefFract.k2 <= (sobely.flCoef.k2 * fract * thresholdFl);
        sobely.flCoefFract.k3 <= (sobely.flCoef.k3 * fract * thresholdFl);
        sobely.flCoefFract.k4 <= (sobely.flCoef.k4 * fract * thresholdFl);
        sobely.flCoefFract.k5 <= (sobely.flCoef.k5 * fract * thresholdFl);
        sobely.flCoefFract.k6 <= (sobely.flCoef.k6 * fract * thresholdFl);
        sobely.flCoefFract.k7 <= (sobely.flCoef.k7 * fract * thresholdFl);
        sobely.flCoefFract.k8 <= (sobely.flCoef.k8 * fract * thresholdFl);
        sobely.flCoefFract.k9 <= (sobely.flCoef.k9 * fract * thresholdFl);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        ------------------------------------------------
        sobely.tpd1.vTap0x <= rgbMac.red;
        sobely.tpd2.vTap0x <= sobely.tpd1.vTap0x;
        sobely.tpd3.vTap0x <= sobely.tpd2.vTap0x;
        ------------------------------------------------
        sobely.tpd1.vTap1x <= rgbMac.green;
        sobely.tpd2.vTap1x <= sobely.tpd1.vTap1x;
        sobely.tpd3.vTap1x <= sobely.tpd2.vTap1x;
        ------------------------------------------------
        sobely.tpd1.vTap2x <= rgbMac.blue;
        sobely.tpd2.vTap2x <= sobely.tpd1.vTap2x;
        sobely.tpd3.vTap2x <= sobely.tpd2.vTap2x;
        ------------------------------------------------
    end if;
end process;
process (clk) begin 
    if rising_edge(clk) then 
        sobely.flProd.k1 <= (sobely.flCoefFract.k1 * sobely.tpd3.vTap2x);
        sobely.flProd.k2 <= (sobely.flCoefFract.k2 * sobely.tpd2.vTap2x);
        sobely.flProd.k3 <= (sobely.flCoefFract.k3 * sobely.tpd1.vTap2x);
        sobely.flProd.k4 <= (sobely.flCoefFract.k4 * sobely.tpd3.vTap1x);
        sobely.flProd.k5 <= (sobely.flCoefFract.k5 * sobely.tpd2.vTap1x);
        sobely.flProd.k6 <= (sobely.flCoefFract.k6 * sobely.tpd1.vTap1x);
        sobely.flProd.k7 <= (sobely.flCoefFract.k7 * sobely.tpd3.vTap0x);
        sobely.flProd.k8 <= (sobely.flCoefFract.k8 * sobely.tpd2.vTap0x);
        sobely.flProd.k9 <= (sobely.flCoefFract.k9 * sobely.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobely.flToSnFxProd.k1 <= to_sfixed((sobely.flProd.k1), sobely.flToSnFxProd.k1);
        sobely.flToSnFxProd.k2 <= to_sfixed((sobely.flProd.k2), sobely.flToSnFxProd.k2);
        sobely.flToSnFxProd.k3 <= to_sfixed((sobely.flProd.k3), sobely.flToSnFxProd.k3);
        sobely.flToSnFxProd.k4 <= to_sfixed((sobely.flProd.k4), sobely.flToSnFxProd.k4);
        sobely.flToSnFxProd.k5 <= to_sfixed((sobely.flProd.k5), sobely.flToSnFxProd.k5);
        sobely.flToSnFxProd.k6 <= to_sfixed((sobely.flProd.k6), sobely.flToSnFxProd.k6);
        sobely.flToSnFxProd.k7 <= to_sfixed((sobely.flProd.k7), sobely.flToSnFxProd.k7);
        sobely.flToSnFxProd.k8 <= to_sfixed((sobely.flProd.k8), sobely.flToSnFxProd.k8);
        sobely.flToSnFxProd.k9 <= to_sfixed((sobely.flProd.k9), sobely.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobely.snFxToSnProd.k1 <= to_signed(sobely.flToSnFxProd.k1(19 downto 0), 20);
        sobely.snFxToSnProd.k2 <= to_signed(sobely.flToSnFxProd.k2(19 downto 0), 20);
        sobely.snFxToSnProd.k3 <= to_signed(sobely.flToSnFxProd.k3(19 downto 0), 20);
        sobely.snFxToSnProd.k4 <= to_signed(sobely.flToSnFxProd.k4(19 downto 0), 20);
        sobely.snFxToSnProd.k5 <= to_signed(sobely.flToSnFxProd.k5(19 downto 0), 20);
        sobely.snFxToSnProd.k6 <= to_signed(sobely.flToSnFxProd.k6(19 downto 0), 20);
        sobely.snFxToSnProd.k7 <= to_signed(sobely.flToSnFxProd.k7(19 downto 0), 20);
        sobely.snFxToSnProd.k8 <= to_signed(sobely.flToSnFxProd.k8(19 downto 0), 20);
        sobely.snFxToSnProd.k9 <= to_signed(sobely.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobely.snToTrimProd.k1 <= sobely.snFxToSnProd.k1(19 downto 5);
        sobely.snToTrimProd.k2 <= sobely.snFxToSnProd.k2(19 downto 5);
        sobely.snToTrimProd.k3 <= sobely.snFxToSnProd.k3(19 downto 5);
        sobely.snToTrimProd.k4 <= sobely.snFxToSnProd.k4(19 downto 5);
        sobely.snToTrimProd.k5 <= sobely.snFxToSnProd.k5(19 downto 5);
        sobely.snToTrimProd.k6 <= sobely.snFxToSnProd.k6(19 downto 5);
        sobely.snToTrimProd.k7 <= sobely.snFxToSnProd.k7(19 downto 5);
        sobely.snToTrimProd.k8 <= sobely.snFxToSnProd.k8(19 downto 5);
        sobely.snToTrimProd.k9 <= sobely.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        sobely.snSum.red            <= (others => '0');
        sobely.snSum.green          <= (others => '0');
        sobely.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        sobely.snSum.red   <= resize(sobely.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                              resize(sobely.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                              resize(sobely.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        sobely.snSum.green <= resize(sobely.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                              resize(sobely.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                              resize(sobely.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        sobely.snSum.blue  <= resize(sobely.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                              resize(sobely.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                              resize(sobely.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sobely.snToTrimSum.red    <= sobely.snSum.red(sobely.snSum.red'left downto FRAC_BITS_TO_KEEP);
        sobely.snToTrimSum.green  <= sobely.snSum.green(sobely.snSum.green'left downto FRAC_BITS_TO_KEEP);
        sobely.snToTrimSum.blue   <= sobely.snSum.blue(sobely.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then
        sobely.rgbSum         <= (sobely.snToTrimSum.red + sobely.snToTrimSum.green + sobely.snToTrimSum.blue);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        if (sobely.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
            sobel_pay <= black;
        elsif (unsigned(sobely.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
            sobel_pay <= white;
        else
            sobel_pay <= std_logic_vector(sobely.rgbSum(i_data_width-1 downto 0));
        end if;
    end if; 
end process;
end generate SOBELY_FRAME_ENABLED;
----------------------------------------------------------------------------------------
--                                SOBELXY_FRAME
----------------------------------------------------------------------------------------
SOBELXY_FRAME_ENABLED: if (SOBEL_FRAME = true) generate
    signal rgbSyncValid          : std_logic_vector(15 downto 0)  := x"0000";
    signal mx                    : unsigned (15 downto 0);
    signal my                    : unsigned (15 downto 0);
    signal sxy                   : unsigned (15 downto 0);
    signal sqr                   : std_logic_vector (31 downto 0);--14
    signal edgeValid             : std_logic;
    signal sbof                  : std_logic_vector (31 downto 0);
    signal validO                : std_logic;
    signal thresholdxy           : std_logic_vector(15 downto 0) :=x"006E";
begin
process (clk) begin
    if rising_edge(clk) then
        mx  <= (unsigned(sobel_pax) * unsigned(sobel_pax));
        my  <= (unsigned(sobel_pay) * unsigned(sobel_pay));
        sxy <= (mx + my);
        sqr <= std_logic_vector(resize(unsigned(sxy), sqr'length));
    end if;
end process;
------------------------------------------------------------------------------------------------
squareRootTopInst: squareRootTop
port map(
    clk        => clk,
    ivalid     => rgbSyncValid(14),
    idata      => sqr,
    ovalid     => validO,
    odata      => sbof);
------------------------------------------------------------------------------------------------
edgeValid  <= hi when (unsigned(sbof(15 downto 0)) > unsigned(thresholdxy)) else lo;
oEdgeValid <= edgeValid;
------------------------------------------------------------------------------------------------
process (clk) begin
    if rising_edge(clk) then
        if (edgeValid = hi) then
            oRgb.sobel.red   <= black;
            oRgb.sobel.green <= black;
            oRgb.sobel.blue  <= black;
        else
            oRgb.sobel.red   <= white;
            oRgb.sobel.green <= white;
            oRgb.sobel.blue  <= white;
        end if;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncValid(0)  <= iRgb.valid;
        rgbSyncValid(1)  <= rgbSyncValid(0);
        rgbSyncValid(2)  <= rgbSyncValid(1);
        rgbSyncValid(3)  <= rgbSyncValid(2);
        rgbSyncValid(4)  <= rgbSyncValid(3);
        rgbSyncValid(5)  <= rgbSyncValid(4);
        rgbSyncValid(6)  <= rgbSyncValid(5);
        rgbSyncValid(7)  <= rgbSyncValid(6);
        rgbSyncValid(8)  <= rgbSyncValid(7);
        rgbSyncValid(9)  <= rgbSyncValid(8);
        rgbSyncValid(10) <= rgbSyncValid(9);
        rgbSyncValid(11) <= rgbSyncValid(10);
        rgbSyncValid(12) <= rgbSyncValid(11);
        rgbSyncValid(13) <= rgbSyncValid(12);
        rgbSyncValid(14) <= rgbSyncValid(13);
        rgbSyncValid(15) <= rgbSyncValid(14);
        oRgb.sobel.valid <= rgbSyncValid(15);
    end if; 
end process;
end generate SOBELXY_FRAME_ENABLED;
----------------------------------------------------------------------------------------
--                                BLURE_FRAME
----------------------------------------------------------------------------------------
BLURE_FRAME_ENABLED: if (BLURE_FRAME = true) generate
----------------------------------------------------------------------------------------
--  BLURE
--  |-----------------------|
--  |R  = +1/9  +1/9  +1/9  |
--  |G  = +1/9  +1/9  +1/9  |
--  |B  = +1/9  +1/9  +1/9  |
--  |-----------------------|
    signal kBu1            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu2            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu3            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu4            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu5            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu6            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu7            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu8            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kBu9            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
----------------------------------------------------------------------------------------
    signal rgbSyncValid    : std_logic_vector(10 downto 0)  := "00000000000";
    constant RED_FRAME     : boolean := BLURE_FRAME;
    constant GREEN_FRAME   : boolean := BLURE_FRAME;
    constant BLUE_FRAME    : boolean := BLURE_FRAME;
    signal coef            : filtersCoefRecord;
----------------------------------------------------------------------------------------
begin
    coef.flCoef.k1 <= to_float((signed(kBu1)),coef.flCoef.k1);
    coef.flCoef.k2 <= to_float((signed(kBu2)),coef.flCoef.k2);
    coef.flCoef.k3 <= to_float((signed(kBu3)),coef.flCoef.k3);
    coef.flCoef.k4 <= to_float((signed(kBu4)),coef.flCoef.k4);
    coef.flCoef.k5 <= to_float((signed(kBu5)),coef.flCoef.k5);
    coef.flCoef.k6 <= to_float((signed(kBu6)),coef.flCoef.k6);
    coef.flCoef.k7 <= to_float((signed(kBu7)),coef.flCoef.k7);
    coef.flCoef.k8 <= to_float((signed(kBu8)),coef.flCoef.k8);
    coef.flCoef.k9 <= to_float((signed(kBu9)),coef.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then
        coef.flCoefFract.k1 <= (coef.flCoef.k1 * fract * thresholdFl);
        coef.flCoefFract.k2 <= (coef.flCoef.k2 * fract * thresholdFl);
        coef.flCoefFract.k3 <= (coef.flCoef.k3 * fract * thresholdFl);
        coef.flCoefFract.k4 <= (coef.flCoef.k4 * fract * thresholdFl);
        coef.flCoefFract.k5 <= (coef.flCoef.k5 * fract * thresholdFl);
        coef.flCoefFract.k6 <= (coef.flCoef.k6 * fract * thresholdFl);
        coef.flCoefFract.k7 <= (coef.flCoef.k7 * fract * thresholdFl);
        coef.flCoefFract.k8 <= (coef.flCoef.k8 * fract * thresholdFl);
        coef.flCoefFract.k9 <= (coef.flCoef.k9 * fract * thresholdFl);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncValid(0)  <= iRgb.valid;
        rgbSyncValid(1)  <= rgbSyncValid(0);
        rgbSyncValid(2)  <= rgbSyncValid(1);
        rgbSyncValid(3)  <= rgbSyncValid(2);
        rgbSyncValid(4)  <= rgbSyncValid(3);
        rgbSyncValid(5)  <= rgbSyncValid(4);
        rgbSyncValid(6)  <= rgbSyncValid(5);
        rgbSyncValid(7)  <= rgbSyncValid(6);
        rgbSyncValid(8)  <= rgbSyncValid(7);
        rgbSyncValid(9)  <= rgbSyncValid(8);
        rgbSyncValid(10) <= rgbSyncValid(9);
        oRgb.blur.valid   <= rgbSyncValid(10);
    end if;
end process;
RED_FRAME_ENABLED: if (RED_FRAME = true) generate
signal blur         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        blur.tpd1.vTap0x <= rgbMac1.red;
        blur.tpd2.vTap0x <= blur.tpd1.vTap0x;
        blur.tpd3.vTap0x <= blur.tpd2.vTap0x;
        blur.tpd1.vTap1x <= rgbMac1.green;
        blur.tpd2.vTap1x <= blur.tpd1.vTap1x;
        blur.tpd3.vTap1x <= blur.tpd2.vTap1x;
        blur.tpd1.vTap2x <= rgbMac1.blue;
        blur.tpd2.vTap2x <= blur.tpd1.vTap2x;
        blur.tpd3.vTap2x <= blur.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.flProd.k1 <= (coef.flCoefFract.k1 * blur.tpd3.vTap2x);
        blur.flProd.k2 <= (coef.flCoefFract.k2 * blur.tpd2.vTap2x);
        blur.flProd.k3 <= (coef.flCoefFract.k3 * blur.tpd1.vTap2x);
        blur.flProd.k4 <= (coef.flCoefFract.k4 * blur.tpd3.vTap1x);
        blur.flProd.k5 <= (coef.flCoefFract.k5 * blur.tpd2.vTap1x);
        blur.flProd.k6 <= (coef.flCoefFract.k6 * blur.tpd1.vTap1x);
        blur.flProd.k7 <= (coef.flCoefFract.k7 * blur.tpd3.vTap0x);
        blur.flProd.k8 <= (coef.flCoefFract.k8 * blur.tpd2.vTap0x);
        blur.flProd.k9 <= (coef.flCoefFract.k9 * blur.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.flToSnFxProd.k1 <= to_sfixed((blur.flProd.k1), blur.flToSnFxProd.k1);
        blur.flToSnFxProd.k2 <= to_sfixed((blur.flProd.k2), blur.flToSnFxProd.k2);
        blur.flToSnFxProd.k3 <= to_sfixed((blur.flProd.k3), blur.flToSnFxProd.k3);
        blur.flToSnFxProd.k4 <= to_sfixed((blur.flProd.k4), blur.flToSnFxProd.k4);
        blur.flToSnFxProd.k5 <= to_sfixed((blur.flProd.k5), blur.flToSnFxProd.k5);
        blur.flToSnFxProd.k6 <= to_sfixed((blur.flProd.k6), blur.flToSnFxProd.k6);
        blur.flToSnFxProd.k7 <= to_sfixed((blur.flProd.k7), blur.flToSnFxProd.k7);
        blur.flToSnFxProd.k8 <= to_sfixed((blur.flProd.k8), blur.flToSnFxProd.k8);
        blur.flToSnFxProd.k9 <= to_sfixed((blur.flProd.k9), blur.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snFxToSnProd.k1 <= to_signed(blur.flToSnFxProd.k1(19 downto 0), 20);
        blur.snFxToSnProd.k2 <= to_signed(blur.flToSnFxProd.k2(19 downto 0), 20);
        blur.snFxToSnProd.k3 <= to_signed(blur.flToSnFxProd.k3(19 downto 0), 20);
        blur.snFxToSnProd.k4 <= to_signed(blur.flToSnFxProd.k4(19 downto 0), 20);
        blur.snFxToSnProd.k5 <= to_signed(blur.flToSnFxProd.k5(19 downto 0), 20);
        blur.snFxToSnProd.k6 <= to_signed(blur.flToSnFxProd.k6(19 downto 0), 20);
        blur.snFxToSnProd.k7 <= to_signed(blur.flToSnFxProd.k7(19 downto 0), 20);
        blur.snFxToSnProd.k8 <= to_signed(blur.flToSnFxProd.k8(19 downto 0), 20);
        blur.snFxToSnProd.k9 <= to_signed(blur.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snToTrimProd.k1 <= blur.snFxToSnProd.k1(19 downto 5);
        blur.snToTrimProd.k2 <= blur.snFxToSnProd.k2(19 downto 5);
        blur.snToTrimProd.k3 <= blur.snFxToSnProd.k3(19 downto 5);
        blur.snToTrimProd.k4 <= blur.snFxToSnProd.k4(19 downto 5);
        blur.snToTrimProd.k5 <= blur.snFxToSnProd.k5(19 downto 5);
        blur.snToTrimProd.k6 <= blur.snFxToSnProd.k6(19 downto 5);
        blur.snToTrimProd.k7 <= blur.snFxToSnProd.k7(19 downto 5);
        blur.snToTrimProd.k8 <= blur.snFxToSnProd.k8(19 downto 5);
        blur.snToTrimProd.k9 <= blur.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        blur.snSum.red            <= (others => '0');
        blur.snSum.green          <= (others => '0');
        blur.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        blur.snSum.red   <= resize(blur.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        blur.snSum.green <= resize(blur.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        blur.snSum.blue  <= resize(blur.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snToTrimSum.red    <= blur.snSum.red(blur.snSum.red'left downto FRAC_BITS_TO_KEEP);
        blur.snToTrimSum.green  <= blur.snSum.green(blur.snSum.green'left downto FRAC_BITS_TO_KEEP);
        blur.snToTrimSum.blue   <= blur.snSum.blue(blur.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        blur.rgbSum  <= (blur.snToTrimSum.red + blur.snToTrimSum.green + blur.snToTrimSum.blue);
    if (blur.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.blur.red <= black;
    elsif (unsigned(blur.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.blur.red <= white;
    else
        oRgb.blur.red <= std_logic_vector(blur.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate RED_FRAME_ENABLED;
GREEN_FRAME_ENABLED: if (GREEN_FRAME = true) generate
signal blur         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        blur.tpd1.vTap0x <= rgbMac2.red;
        blur.tpd2.vTap0x <= blur.tpd1.vTap0x;
        blur.tpd3.vTap0x <= blur.tpd2.vTap0x;
        blur.tpd1.vTap1x <= rgbMac2.green;
        blur.tpd2.vTap1x <= blur.tpd1.vTap1x;
        blur.tpd3.vTap1x <= blur.tpd2.vTap1x;
        blur.tpd1.vTap2x <= rgbMac2.blue;
        blur.tpd2.vTap2x <= blur.tpd1.vTap2x;
        blur.tpd3.vTap2x <= blur.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.flProd.k1 <= (coef.flCoefFract.k1 * blur.tpd3.vTap2x);
        blur.flProd.k2 <= (coef.flCoefFract.k2 * blur.tpd2.vTap2x);
        blur.flProd.k3 <= (coef.flCoefFract.k3 * blur.tpd1.vTap2x);
        blur.flProd.k4 <= (coef.flCoefFract.k4 * blur.tpd3.vTap1x);
        blur.flProd.k5 <= (coef.flCoefFract.k5 * blur.tpd2.vTap1x);
        blur.flProd.k6 <= (coef.flCoefFract.k6 * blur.tpd1.vTap1x);
        blur.flProd.k7 <= (coef.flCoefFract.k7 * blur.tpd3.vTap0x);
        blur.flProd.k8 <= (coef.flCoefFract.k8 * blur.tpd2.vTap0x);
        blur.flProd.k9 <= (coef.flCoefFract.k9 * blur.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.flToSnFxProd.k1 <= to_sfixed((blur.flProd.k1), blur.flToSnFxProd.k1);
        blur.flToSnFxProd.k2 <= to_sfixed((blur.flProd.k2), blur.flToSnFxProd.k2);
        blur.flToSnFxProd.k3 <= to_sfixed((blur.flProd.k3), blur.flToSnFxProd.k3);
        blur.flToSnFxProd.k4 <= to_sfixed((blur.flProd.k4), blur.flToSnFxProd.k4);
        blur.flToSnFxProd.k5 <= to_sfixed((blur.flProd.k5), blur.flToSnFxProd.k5);
        blur.flToSnFxProd.k6 <= to_sfixed((blur.flProd.k6), blur.flToSnFxProd.k6);
        blur.flToSnFxProd.k7 <= to_sfixed((blur.flProd.k7), blur.flToSnFxProd.k7);
        blur.flToSnFxProd.k8 <= to_sfixed((blur.flProd.k8), blur.flToSnFxProd.k8);
        blur.flToSnFxProd.k9 <= to_sfixed((blur.flProd.k9), blur.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snFxToSnProd.k1 <= to_signed(blur.flToSnFxProd.k1(19 downto 0), 20);
        blur.snFxToSnProd.k2 <= to_signed(blur.flToSnFxProd.k2(19 downto 0), 20);
        blur.snFxToSnProd.k3 <= to_signed(blur.flToSnFxProd.k3(19 downto 0), 20);
        blur.snFxToSnProd.k4 <= to_signed(blur.flToSnFxProd.k4(19 downto 0), 20);
        blur.snFxToSnProd.k5 <= to_signed(blur.flToSnFxProd.k5(19 downto 0), 20);
        blur.snFxToSnProd.k6 <= to_signed(blur.flToSnFxProd.k6(19 downto 0), 20);
        blur.snFxToSnProd.k7 <= to_signed(blur.flToSnFxProd.k7(19 downto 0), 20);
        blur.snFxToSnProd.k8 <= to_signed(blur.flToSnFxProd.k8(19 downto 0), 20);
        blur.snFxToSnProd.k9 <= to_signed(blur.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snToTrimProd.k1 <= blur.snFxToSnProd.k1(19 downto 5);
        blur.snToTrimProd.k2 <= blur.snFxToSnProd.k2(19 downto 5);
        blur.snToTrimProd.k3 <= blur.snFxToSnProd.k3(19 downto 5);
        blur.snToTrimProd.k4 <= blur.snFxToSnProd.k4(19 downto 5);
        blur.snToTrimProd.k5 <= blur.snFxToSnProd.k5(19 downto 5);
        blur.snToTrimProd.k6 <= blur.snFxToSnProd.k6(19 downto 5);
        blur.snToTrimProd.k7 <= blur.snFxToSnProd.k7(19 downto 5);
        blur.snToTrimProd.k8 <= blur.snFxToSnProd.k8(19 downto 5);
        blur.snToTrimProd.k9 <= blur.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        blur.snSum.red            <= (others => '0');
        blur.snSum.green          <= (others => '0');
        blur.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        blur.snSum.red   <= resize(blur.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        blur.snSum.green <= resize(blur.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        blur.snSum.blue  <= resize(blur.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snToTrimSum.red    <= blur.snSum.red(blur.snSum.red'left downto FRAC_BITS_TO_KEEP);
        blur.snToTrimSum.green  <= blur.snSum.green(blur.snSum.green'left downto FRAC_BITS_TO_KEEP);
        blur.snToTrimSum.blue   <= blur.snSum.blue(blur.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        blur.rgbSum  <= (blur.snToTrimSum.red + blur.snToTrimSum.green + blur.snToTrimSum.blue);
    if (blur.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.blur.green <= black;
    elsif (unsigned(blur.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.blur.green <= white;
    else
        oRgb.blur.green <= std_logic_vector(blur.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate GREEN_FRAME_ENABLED;
BLUE_FRAME_ENABLED: if (BLUE_FRAME = true) generate
signal blur         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        blur.tpd1.vTap0x <= rgbMac3.red;
        blur.tpd2.vTap0x <= blur.tpd1.vTap0x;
        blur.tpd3.vTap0x <= blur.tpd2.vTap0x;
        blur.tpd1.vTap1x <= rgbMac3.green;
        blur.tpd2.vTap1x <= blur.tpd1.vTap1x;
        blur.tpd3.vTap1x <= blur.tpd2.vTap1x;
        blur.tpd1.vTap2x <= rgbMac3.blue;
        blur.tpd2.vTap2x <= blur.tpd1.vTap2x;
        blur.tpd3.vTap2x <= blur.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.flProd.k1 <= (coef.flCoefFract.k1 * blur.tpd3.vTap2x);
        blur.flProd.k2 <= (coef.flCoefFract.k2 * blur.tpd2.vTap2x);
        blur.flProd.k3 <= (coef.flCoefFract.k3 * blur.tpd1.vTap2x);
        blur.flProd.k4 <= (coef.flCoefFract.k4 * blur.tpd3.vTap1x);
        blur.flProd.k5 <= (coef.flCoefFract.k5 * blur.tpd2.vTap1x);
        blur.flProd.k6 <= (coef.flCoefFract.k6 * blur.tpd1.vTap1x);
        blur.flProd.k7 <= (coef.flCoefFract.k7 * blur.tpd3.vTap0x);
        blur.flProd.k8 <= (coef.flCoefFract.k8 * blur.tpd2.vTap0x);
        blur.flProd.k9 <= (coef.flCoefFract.k9 * blur.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.flToSnFxProd.k1 <= to_sfixed((blur.flProd.k1), blur.flToSnFxProd.k1);
        blur.flToSnFxProd.k2 <= to_sfixed((blur.flProd.k2), blur.flToSnFxProd.k2);
        blur.flToSnFxProd.k3 <= to_sfixed((blur.flProd.k3), blur.flToSnFxProd.k3);
        blur.flToSnFxProd.k4 <= to_sfixed((blur.flProd.k4), blur.flToSnFxProd.k4);
        blur.flToSnFxProd.k5 <= to_sfixed((blur.flProd.k5), blur.flToSnFxProd.k5);
        blur.flToSnFxProd.k6 <= to_sfixed((blur.flProd.k6), blur.flToSnFxProd.k6);
        blur.flToSnFxProd.k7 <= to_sfixed((blur.flProd.k7), blur.flToSnFxProd.k7);
        blur.flToSnFxProd.k8 <= to_sfixed((blur.flProd.k8), blur.flToSnFxProd.k8);
        blur.flToSnFxProd.k9 <= to_sfixed((blur.flProd.k9), blur.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snFxToSnProd.k1 <= to_signed(blur.flToSnFxProd.k1(19 downto 0), 20);
        blur.snFxToSnProd.k2 <= to_signed(blur.flToSnFxProd.k2(19 downto 0), 20);
        blur.snFxToSnProd.k3 <= to_signed(blur.flToSnFxProd.k3(19 downto 0), 20);
        blur.snFxToSnProd.k4 <= to_signed(blur.flToSnFxProd.k4(19 downto 0), 20);
        blur.snFxToSnProd.k5 <= to_signed(blur.flToSnFxProd.k5(19 downto 0), 20);
        blur.snFxToSnProd.k6 <= to_signed(blur.flToSnFxProd.k6(19 downto 0), 20);
        blur.snFxToSnProd.k7 <= to_signed(blur.flToSnFxProd.k7(19 downto 0), 20);
        blur.snFxToSnProd.k8 <= to_signed(blur.flToSnFxProd.k8(19 downto 0), 20);
        blur.snFxToSnProd.k9 <= to_signed(blur.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snToTrimProd.k1 <= blur.snFxToSnProd.k1(19 downto 5);
        blur.snToTrimProd.k2 <= blur.snFxToSnProd.k2(19 downto 5);
        blur.snToTrimProd.k3 <= blur.snFxToSnProd.k3(19 downto 5);
        blur.snToTrimProd.k4 <= blur.snFxToSnProd.k4(19 downto 5);
        blur.snToTrimProd.k5 <= blur.snFxToSnProd.k5(19 downto 5);
        blur.snToTrimProd.k6 <= blur.snFxToSnProd.k6(19 downto 5);
        blur.snToTrimProd.k7 <= blur.snFxToSnProd.k7(19 downto 5);
        blur.snToTrimProd.k8 <= blur.snFxToSnProd.k8(19 downto 5);
        blur.snToTrimProd.k9 <= blur.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        blur.snSum.red            <= (others => '0');
        blur.snSum.green          <= (others => '0');
        blur.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        blur.snSum.red   <= resize(blur.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        blur.snSum.green <= resize(blur.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        blur.snSum.blue  <= resize(blur.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(blur.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        blur.snToTrimSum.red    <= blur.snSum.red(blur.snSum.red'left downto FRAC_BITS_TO_KEEP);
        blur.snToTrimSum.green  <= blur.snSum.green(blur.snSum.green'left downto FRAC_BITS_TO_KEEP);
        blur.snToTrimSum.blue   <= blur.snSum.blue(blur.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        blur.rgbSum  <= (blur.snToTrimSum.red + blur.snToTrimSum.green + blur.snToTrimSum.blue);
    if (blur.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.blur.blue <= black;
    elsif (unsigned(blur.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.blur.blue <= white;
    else
        oRgb.blur.blue <= std_logic_vector(blur.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate BLUE_FRAME_ENABLED;
end generate BLURE_FRAME_ENABLED;
----------------------------------------------------------------------------------------
--                                EMBOS_FRAME
----------------------------------------------------------------------------------------
EMBOS_FRAME_ENABLED: if (EMBOS_FRAME = true) generate
----------------------------------------------------------------------------------------
--  EMBOSS
--  |---------------------|
--  |R  = -1   -1    0    |
--  |G  = -1    0    1    |
--  |B  =  0    1    1    |
--  |---------------------|
    signal kEm1             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal kEm2             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal kEm3             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal kEm4             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal kEm5             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal kEm6             : std_logic_vector(15 downto 0) := x"03E8";--  1
    signal kEm7             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal kEm8             : std_logic_vector(15 downto 0) := x"03E8";--  1
    signal kEm9             : std_logic_vector(15 downto 0) := x"03E8";--  1
----------------------------------------------------------------------------------------
    signal rgbSyncValid    : std_logic_vector(10 downto 0)  := "00000000000";
    constant RED_FRAME     : boolean := EMBOS_FRAME;
    constant GREEN_FRAME   : boolean := EMBOS_FRAME;
    constant BLUE_FRAME    : boolean := EMBOS_FRAME;
    signal coef            : filtersCoefRecord;
----------------------------------------------------------------------------------------
begin
    coef.flCoef.k1 <= to_float((signed(kEm1)),coef.flCoef.k1);
    coef.flCoef.k2 <= to_float((signed(kEm2)),coef.flCoef.k2);
    coef.flCoef.k3 <= to_float((signed(kEm3)),coef.flCoef.k3);
    coef.flCoef.k4 <= to_float((signed(kEm4)),coef.flCoef.k4);
    coef.flCoef.k5 <= to_float((signed(kEm5)),coef.flCoef.k5);
    coef.flCoef.k6 <= to_float((signed(kEm6)),coef.flCoef.k6);
    coef.flCoef.k7 <= to_float((signed(kEm7)),coef.flCoef.k7);
    coef.flCoef.k8 <= to_float((signed(kEm8)),coef.flCoef.k8);
    coef.flCoef.k9 <= to_float((signed(kEm9)),coef.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then
        coef.flCoefFract.k1 <= (coef.flCoef.k1 * fract * thresholdFl);
        coef.flCoefFract.k2 <= (coef.flCoef.k2 * fract * thresholdFl);
        coef.flCoefFract.k3 <= (coef.flCoef.k3 * fract * thresholdFl);
        coef.flCoefFract.k4 <= (coef.flCoef.k4 * fract * thresholdFl);
        coef.flCoefFract.k5 <= (coef.flCoef.k5 * fract * thresholdFl);
        coef.flCoefFract.k6 <= (coef.flCoef.k6 * fract * thresholdFl);
        coef.flCoefFract.k7 <= (coef.flCoef.k7 * fract * thresholdFl);
        coef.flCoefFract.k8 <= (coef.flCoef.k8 * fract * thresholdFl);
        coef.flCoefFract.k9 <= (coef.flCoef.k9 * fract * thresholdFl);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncValid(0)  <= iRgb.valid;
        rgbSyncValid(1)  <= rgbSyncValid(0);
        rgbSyncValid(2)  <= rgbSyncValid(1);
        rgbSyncValid(3)  <= rgbSyncValid(2);
        rgbSyncValid(4)  <= rgbSyncValid(3);
        rgbSyncValid(5)  <= rgbSyncValid(4);
        rgbSyncValid(6)  <= rgbSyncValid(5);
        rgbSyncValid(7)  <= rgbSyncValid(6);
        rgbSyncValid(8)  <= rgbSyncValid(7);
        rgbSyncValid(9)  <= rgbSyncValid(8);
        rgbSyncValid(10) <= rgbSyncValid(9);
        oRgb.embos.valid   <= rgbSyncValid(10);
    end if;
end process;
RED_FRAME_ENABLED: if (RED_FRAME = true) generate
signal emboss         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        emboss.tpd1.vTap0x <= rgbMac1.red;
        emboss.tpd2.vTap0x <= emboss.tpd1.vTap0x;
        emboss.tpd3.vTap0x <= emboss.tpd2.vTap0x;
        emboss.tpd1.vTap1x <= rgbMac1.green;
        emboss.tpd2.vTap1x <= emboss.tpd1.vTap1x;
        emboss.tpd3.vTap1x <= emboss.tpd2.vTap1x;
        emboss.tpd1.vTap2x <= rgbMac1.blue;
        emboss.tpd2.vTap2x <= emboss.tpd1.vTap2x;
        emboss.tpd3.vTap2x <= emboss.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.flProd.k1 <= (coef.flCoefFract.k1 * emboss.tpd3.vTap2x);
        emboss.flProd.k2 <= (coef.flCoefFract.k2 * emboss.tpd2.vTap2x);
        emboss.flProd.k3 <= (coef.flCoefFract.k3 * emboss.tpd1.vTap2x);
        emboss.flProd.k4 <= (coef.flCoefFract.k4 * emboss.tpd3.vTap1x);
        emboss.flProd.k5 <= (coef.flCoefFract.k5 * emboss.tpd2.vTap1x);
        emboss.flProd.k6 <= (coef.flCoefFract.k6 * emboss.tpd1.vTap1x);
        emboss.flProd.k7 <= (coef.flCoefFract.k7 * emboss.tpd3.vTap0x);
        emboss.flProd.k8 <= (coef.flCoefFract.k8 * emboss.tpd2.vTap0x);
        emboss.flProd.k9 <= (coef.flCoefFract.k9 * emboss.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.flToSnFxProd.k1 <= to_sfixed((emboss.flProd.k1), emboss.flToSnFxProd.k1);
        emboss.flToSnFxProd.k2 <= to_sfixed((emboss.flProd.k2), emboss.flToSnFxProd.k2);
        emboss.flToSnFxProd.k3 <= to_sfixed((emboss.flProd.k3), emboss.flToSnFxProd.k3);
        emboss.flToSnFxProd.k4 <= to_sfixed((emboss.flProd.k4), emboss.flToSnFxProd.k4);
        emboss.flToSnFxProd.k5 <= to_sfixed((emboss.flProd.k5), emboss.flToSnFxProd.k5);
        emboss.flToSnFxProd.k6 <= to_sfixed((emboss.flProd.k6), emboss.flToSnFxProd.k6);
        emboss.flToSnFxProd.k7 <= to_sfixed((emboss.flProd.k7), emboss.flToSnFxProd.k7);
        emboss.flToSnFxProd.k8 <= to_sfixed((emboss.flProd.k8), emboss.flToSnFxProd.k8);
        emboss.flToSnFxProd.k9 <= to_sfixed((emboss.flProd.k9), emboss.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snFxToSnProd.k1 <= to_signed(emboss.flToSnFxProd.k1(19 downto 0), 20);
        emboss.snFxToSnProd.k2 <= to_signed(emboss.flToSnFxProd.k2(19 downto 0), 20);
        emboss.snFxToSnProd.k3 <= to_signed(emboss.flToSnFxProd.k3(19 downto 0), 20);
        emboss.snFxToSnProd.k4 <= to_signed(emboss.flToSnFxProd.k4(19 downto 0), 20);
        emboss.snFxToSnProd.k5 <= to_signed(emboss.flToSnFxProd.k5(19 downto 0), 20);
        emboss.snFxToSnProd.k6 <= to_signed(emboss.flToSnFxProd.k6(19 downto 0), 20);
        emboss.snFxToSnProd.k7 <= to_signed(emboss.flToSnFxProd.k7(19 downto 0), 20);
        emboss.snFxToSnProd.k8 <= to_signed(emboss.flToSnFxProd.k8(19 downto 0), 20);
        emboss.snFxToSnProd.k9 <= to_signed(emboss.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snToTrimProd.k1 <= emboss.snFxToSnProd.k1(19 downto 5);
        emboss.snToTrimProd.k2 <= emboss.snFxToSnProd.k2(19 downto 5);
        emboss.snToTrimProd.k3 <= emboss.snFxToSnProd.k3(19 downto 5);
        emboss.snToTrimProd.k4 <= emboss.snFxToSnProd.k4(19 downto 5);
        emboss.snToTrimProd.k5 <= emboss.snFxToSnProd.k5(19 downto 5);
        emboss.snToTrimProd.k6 <= emboss.snFxToSnProd.k6(19 downto 5);
        emboss.snToTrimProd.k7 <= emboss.snFxToSnProd.k7(19 downto 5);
        emboss.snToTrimProd.k8 <= emboss.snFxToSnProd.k8(19 downto 5);
        emboss.snToTrimProd.k9 <= emboss.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        emboss.snSum.red            <= (others => '0');
        emboss.snSum.green          <= (others => '0');
        emboss.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        emboss.snSum.red   <= resize(emboss.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        emboss.snSum.green <= resize(emboss.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        emboss.snSum.blue  <= resize(emboss.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snToTrimSum.red    <= emboss.snSum.red(emboss.snSum.red'left downto FRAC_BITS_TO_KEEP);
        emboss.snToTrimSum.green  <= emboss.snSum.green(emboss.snSum.green'left downto FRAC_BITS_TO_KEEP);
        emboss.snToTrimSum.blue   <= emboss.snSum.blue(emboss.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        emboss.rgbSum  <= (emboss.snToTrimSum.red + emboss.snToTrimSum.green + emboss.snToTrimSum.blue);
    if (emboss.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.embos.red <= black;
    elsif (unsigned(emboss.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.embos.red <= white;
    else
        oRgb.embos.red <= std_logic_vector(emboss.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate RED_FRAME_ENABLED;
GREEN_FRAME_ENABLED: if (GREEN_FRAME = true) generate
signal emboss         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        emboss.tpd1.vTap0x <= rgbMac2.red;
        emboss.tpd2.vTap0x <= emboss.tpd1.vTap0x;
        emboss.tpd3.vTap0x <= emboss.tpd2.vTap0x;
        emboss.tpd1.vTap1x <= rgbMac2.green;
        emboss.tpd2.vTap1x <= emboss.tpd1.vTap1x;
        emboss.tpd3.vTap1x <= emboss.tpd2.vTap1x;
        emboss.tpd1.vTap2x <= rgbMac2.blue;
        emboss.tpd2.vTap2x <= emboss.tpd1.vTap2x;
        emboss.tpd3.vTap2x <= emboss.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.flProd.k1 <= (coef.flCoefFract.k1 * emboss.tpd3.vTap2x);
        emboss.flProd.k2 <= (coef.flCoefFract.k2 * emboss.tpd2.vTap2x);
        emboss.flProd.k3 <= (coef.flCoefFract.k3 * emboss.tpd1.vTap2x);
        emboss.flProd.k4 <= (coef.flCoefFract.k4 * emboss.tpd3.vTap1x);
        emboss.flProd.k5 <= (coef.flCoefFract.k5 * emboss.tpd2.vTap1x);
        emboss.flProd.k6 <= (coef.flCoefFract.k6 * emboss.tpd1.vTap1x);
        emboss.flProd.k7 <= (coef.flCoefFract.k7 * emboss.tpd3.vTap0x);
        emboss.flProd.k8 <= (coef.flCoefFract.k8 * emboss.tpd2.vTap0x);
        emboss.flProd.k9 <= (coef.flCoefFract.k9 * emboss.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.flToSnFxProd.k1 <= to_sfixed((emboss.flProd.k1), emboss.flToSnFxProd.k1);
        emboss.flToSnFxProd.k2 <= to_sfixed((emboss.flProd.k2), emboss.flToSnFxProd.k2);
        emboss.flToSnFxProd.k3 <= to_sfixed((emboss.flProd.k3), emboss.flToSnFxProd.k3);
        emboss.flToSnFxProd.k4 <= to_sfixed((emboss.flProd.k4), emboss.flToSnFxProd.k4);
        emboss.flToSnFxProd.k5 <= to_sfixed((emboss.flProd.k5), emboss.flToSnFxProd.k5);
        emboss.flToSnFxProd.k6 <= to_sfixed((emboss.flProd.k6), emboss.flToSnFxProd.k6);
        emboss.flToSnFxProd.k7 <= to_sfixed((emboss.flProd.k7), emboss.flToSnFxProd.k7);
        emboss.flToSnFxProd.k8 <= to_sfixed((emboss.flProd.k8), emboss.flToSnFxProd.k8);
        emboss.flToSnFxProd.k9 <= to_sfixed((emboss.flProd.k9), emboss.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snFxToSnProd.k1 <= to_signed(emboss.flToSnFxProd.k1(19 downto 0), 20);
        emboss.snFxToSnProd.k2 <= to_signed(emboss.flToSnFxProd.k2(19 downto 0), 20);
        emboss.snFxToSnProd.k3 <= to_signed(emboss.flToSnFxProd.k3(19 downto 0), 20);
        emboss.snFxToSnProd.k4 <= to_signed(emboss.flToSnFxProd.k4(19 downto 0), 20);
        emboss.snFxToSnProd.k5 <= to_signed(emboss.flToSnFxProd.k5(19 downto 0), 20);
        emboss.snFxToSnProd.k6 <= to_signed(emboss.flToSnFxProd.k6(19 downto 0), 20);
        emboss.snFxToSnProd.k7 <= to_signed(emboss.flToSnFxProd.k7(19 downto 0), 20);
        emboss.snFxToSnProd.k8 <= to_signed(emboss.flToSnFxProd.k8(19 downto 0), 20);
        emboss.snFxToSnProd.k9 <= to_signed(emboss.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snToTrimProd.k1 <= emboss.snFxToSnProd.k1(19 downto 5);
        emboss.snToTrimProd.k2 <= emboss.snFxToSnProd.k2(19 downto 5);
        emboss.snToTrimProd.k3 <= emboss.snFxToSnProd.k3(19 downto 5);
        emboss.snToTrimProd.k4 <= emboss.snFxToSnProd.k4(19 downto 5);
        emboss.snToTrimProd.k5 <= emboss.snFxToSnProd.k5(19 downto 5);
        emboss.snToTrimProd.k6 <= emboss.snFxToSnProd.k6(19 downto 5);
        emboss.snToTrimProd.k7 <= emboss.snFxToSnProd.k7(19 downto 5);
        emboss.snToTrimProd.k8 <= emboss.snFxToSnProd.k8(19 downto 5);
        emboss.snToTrimProd.k9 <= emboss.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        emboss.snSum.red            <= (others => '0');
        emboss.snSum.green          <= (others => '0');
        emboss.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        emboss.snSum.red   <= resize(emboss.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        emboss.snSum.green <= resize(emboss.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        emboss.snSum.blue  <= resize(emboss.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snToTrimSum.red    <= emboss.snSum.red(emboss.snSum.red'left downto FRAC_BITS_TO_KEEP);
        emboss.snToTrimSum.green  <= emboss.snSum.green(emboss.snSum.green'left downto FRAC_BITS_TO_KEEP);
        emboss.snToTrimSum.blue   <= emboss.snSum.blue(emboss.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        emboss.rgbSum  <= (emboss.snToTrimSum.red + emboss.snToTrimSum.green + emboss.snToTrimSum.blue);
    if (emboss.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.embos.green <= black;
    elsif (unsigned(emboss.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.embos.green <= white;
    else
        oRgb.embos.green <= std_logic_vector(emboss.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate GREEN_FRAME_ENABLED;
BLUE_FRAME_ENABLED: if (BLUE_FRAME = true) generate
signal emboss         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        emboss.tpd1.vTap0x <= rgbMac3.red;
        emboss.tpd2.vTap0x <= emboss.tpd1.vTap0x;
        emboss.tpd3.vTap0x <= emboss.tpd2.vTap0x;
        emboss.tpd1.vTap1x <= rgbMac3.green;
        emboss.tpd2.vTap1x <= emboss.tpd1.vTap1x;
        emboss.tpd3.vTap1x <= emboss.tpd2.vTap1x;
        emboss.tpd1.vTap2x <= rgbMac3.blue;
        emboss.tpd2.vTap2x <= emboss.tpd1.vTap2x;
        emboss.tpd3.vTap2x <= emboss.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.flProd.k1 <= (coef.flCoefFract.k1 * emboss.tpd3.vTap2x);
        emboss.flProd.k2 <= (coef.flCoefFract.k2 * emboss.tpd2.vTap2x);
        emboss.flProd.k3 <= (coef.flCoefFract.k3 * emboss.tpd1.vTap2x);
        emboss.flProd.k4 <= (coef.flCoefFract.k4 * emboss.tpd3.vTap1x);
        emboss.flProd.k5 <= (coef.flCoefFract.k5 * emboss.tpd2.vTap1x);
        emboss.flProd.k6 <= (coef.flCoefFract.k6 * emboss.tpd1.vTap1x);
        emboss.flProd.k7 <= (coef.flCoefFract.k7 * emboss.tpd3.vTap0x);
        emboss.flProd.k8 <= (coef.flCoefFract.k8 * emboss.tpd2.vTap0x);
        emboss.flProd.k9 <= (coef.flCoefFract.k9 * emboss.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.flToSnFxProd.k1 <= to_sfixed((emboss.flProd.k1), emboss.flToSnFxProd.k1);
        emboss.flToSnFxProd.k2 <= to_sfixed((emboss.flProd.k2), emboss.flToSnFxProd.k2);
        emboss.flToSnFxProd.k3 <= to_sfixed((emboss.flProd.k3), emboss.flToSnFxProd.k3);
        emboss.flToSnFxProd.k4 <= to_sfixed((emboss.flProd.k4), emboss.flToSnFxProd.k4);
        emboss.flToSnFxProd.k5 <= to_sfixed((emboss.flProd.k5), emboss.flToSnFxProd.k5);
        emboss.flToSnFxProd.k6 <= to_sfixed((emboss.flProd.k6), emboss.flToSnFxProd.k6);
        emboss.flToSnFxProd.k7 <= to_sfixed((emboss.flProd.k7), emboss.flToSnFxProd.k7);
        emboss.flToSnFxProd.k8 <= to_sfixed((emboss.flProd.k8), emboss.flToSnFxProd.k8);
        emboss.flToSnFxProd.k9 <= to_sfixed((emboss.flProd.k9), emboss.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snFxToSnProd.k1 <= to_signed(emboss.flToSnFxProd.k1(19 downto 0), 20);
        emboss.snFxToSnProd.k2 <= to_signed(emboss.flToSnFxProd.k2(19 downto 0), 20);
        emboss.snFxToSnProd.k3 <= to_signed(emboss.flToSnFxProd.k3(19 downto 0), 20);
        emboss.snFxToSnProd.k4 <= to_signed(emboss.flToSnFxProd.k4(19 downto 0), 20);
        emboss.snFxToSnProd.k5 <= to_signed(emboss.flToSnFxProd.k5(19 downto 0), 20);
        emboss.snFxToSnProd.k6 <= to_signed(emboss.flToSnFxProd.k6(19 downto 0), 20);
        emboss.snFxToSnProd.k7 <= to_signed(emboss.flToSnFxProd.k7(19 downto 0), 20);
        emboss.snFxToSnProd.k8 <= to_signed(emboss.flToSnFxProd.k8(19 downto 0), 20);
        emboss.snFxToSnProd.k9 <= to_signed(emboss.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snToTrimProd.k1 <= emboss.snFxToSnProd.k1(19 downto 5);
        emboss.snToTrimProd.k2 <= emboss.snFxToSnProd.k2(19 downto 5);
        emboss.snToTrimProd.k3 <= emboss.snFxToSnProd.k3(19 downto 5);
        emboss.snToTrimProd.k4 <= emboss.snFxToSnProd.k4(19 downto 5);
        emboss.snToTrimProd.k5 <= emboss.snFxToSnProd.k5(19 downto 5);
        emboss.snToTrimProd.k6 <= emboss.snFxToSnProd.k6(19 downto 5);
        emboss.snToTrimProd.k7 <= emboss.snFxToSnProd.k7(19 downto 5);
        emboss.snToTrimProd.k8 <= emboss.snFxToSnProd.k8(19 downto 5);
        emboss.snToTrimProd.k9 <= emboss.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        emboss.snSum.red            <= (others => '0');
        emboss.snSum.green          <= (others => '0');
        emboss.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        emboss.snSum.red   <= resize(emboss.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        emboss.snSum.green <= resize(emboss.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        emboss.snSum.blue  <= resize(emboss.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(emboss.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        emboss.snToTrimSum.red    <= emboss.snSum.red(emboss.snSum.red'left downto FRAC_BITS_TO_KEEP);
        emboss.snToTrimSum.green  <= emboss.snSum.green(emboss.snSum.green'left downto FRAC_BITS_TO_KEEP);
        emboss.snToTrimSum.blue   <= emboss.snSum.blue(emboss.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        emboss.rgbSum  <= (emboss.snToTrimSum.red + emboss.snToTrimSum.green + emboss.snToTrimSum.blue);
    if (emboss.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.embos.blue <= black;
    elsif (unsigned(emboss.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.embos.blue <= white;
    else
        oRgb.embos.blue <= std_logic_vector(emboss.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate BLUE_FRAME_ENABLED;
end generate EMBOS_FRAME_ENABLED;
----------------------------------------------------------------------------------------
--                                SHARP_FRAME
----------------------------------------------------------------------------------------
SHARP_FRAME_ENABLED: if (SHARP_FRAME = true) generate
----------------------------------------------------------------------------------------
--  SHARP
--  |---------------------|
--  |R  =  0   -1    0    |
--  |G  = -1   +5   -1    |
--  |B  =  0   -1    0    |
--  |---------------------|
    signal kSh1           : std_logic_vector(15 downto 0) := x"0000";--  0
    signal kSh2           : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal kSh3           : std_logic_vector(15 downto 0) := x"0000";--  0
    signal kSh4           : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal kSh5           : std_logic_vector(15 downto 0) := x"1388";--  5
    signal kSh6           : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal kSh7           : std_logic_vector(15 downto 0) := x"0000";--  0
    signal kSh8           : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal kSh9           : std_logic_vector(15 downto 0) := x"0000";--  0
----------------------------------------------------------------------------------------
    signal rgbSyncValid    : std_logic_vector(11 downto 0)  := "000000000000";
    constant RED_FRAME     : boolean := SHARP_FRAME;
    constant GREEN_FRAME   : boolean := SHARP_FRAME;
    constant BLUE_FRAME    : boolean := SHARP_FRAME;
    signal coef            : filtersCoefRecord;
----------------------------------------------------------------------------------------
begin
    coef.flCoef.k1 <= to_float((signed(kSh1)),coef.flCoef.k1);
    coef.flCoef.k2 <= to_float((signed(kSh2)),coef.flCoef.k2);
    coef.flCoef.k3 <= to_float((signed(kSh3)),coef.flCoef.k3);
    coef.flCoef.k4 <= to_float((signed(kSh4)),coef.flCoef.k4);
    coef.flCoef.k5 <= to_float((signed(kSh5)),coef.flCoef.k5);
    coef.flCoef.k6 <= to_float((signed(kSh6)),coef.flCoef.k6);
    coef.flCoef.k7 <= to_float((signed(kSh7)),coef.flCoef.k7);
    coef.flCoef.k8 <= to_float((signed(kSh8)),coef.flCoef.k8);
    coef.flCoef.k9 <= to_float((signed(kSh9)),coef.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then
        coef.flCoefFract.k1 <= (coef.flCoef.k1 * fract * thresholdFl);
        coef.flCoefFract.k2 <= (coef.flCoef.k2 * fract * thresholdFl);
        coef.flCoefFract.k3 <= (coef.flCoef.k3 * fract * thresholdFl);
        coef.flCoefFract.k4 <= (coef.flCoef.k4 * fract * thresholdFl);
        coef.flCoefFract.k5 <= (coef.flCoef.k5 * fract * thresholdFl);
        coef.flCoefFract.k6 <= (coef.flCoef.k6 * fract * thresholdFl);
        coef.flCoefFract.k7 <= (coef.flCoef.k7 * fract * thresholdFl);
        coef.flCoefFract.k8 <= (coef.flCoef.k8 * fract * thresholdFl);
        coef.flCoefFract.k9 <= (coef.flCoef.k9 * fract * thresholdFl);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncValid(0)  <= iRgb.valid;
        rgbSyncValid(1)  <= rgbSyncValid(0);
        rgbSyncValid(2)  <= rgbSyncValid(1);
        rgbSyncValid(3)  <= rgbSyncValid(2);
        rgbSyncValid(4)  <= rgbSyncValid(3);
        rgbSyncValid(5)  <= rgbSyncValid(4);
        rgbSyncValid(6)  <= rgbSyncValid(5);
        rgbSyncValid(7)  <= rgbSyncValid(6);
        rgbSyncValid(8)  <= rgbSyncValid(7);
        rgbSyncValid(9)  <= rgbSyncValid(8);
        rgbSyncValid(10) <= rgbSyncValid(9);
        rgbSyncValid(11) <= rgbSyncValid(10);
        oRgb.sharp.valid  <= rgbSyncValid(11);
    end if;
end process;
RED_FRAME_ENABLED: if (RED_FRAME = true) generate
signal sharp         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        sharp.tpd1.vTap0x <= rgbMac1.red;
        sharp.tpd2.vTap0x <= sharp.tpd1.vTap0x;
        sharp.tpd3.vTap0x <= sharp.tpd2.vTap0x;
        sharp.tpd1.vTap1x <= rgbMac1.green;
        sharp.tpd2.vTap1x <= sharp.tpd1.vTap1x;
        sharp.tpd3.vTap1x <= sharp.tpd2.vTap1x;
        sharp.tpd1.vTap2x <= rgbMac1.blue;
        sharp.tpd2.vTap2x <= sharp.tpd1.vTap2x;
        sharp.tpd3.vTap2x <= sharp.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.flProd.k1 <= (coef.flCoefFract.k1 * sharp.tpd1.vTap2x);
        sharp.flProd.k2 <= (coef.flCoefFract.k2 * sharp.tpd2.vTap2x);
        sharp.flProd.k3 <= (coef.flCoefFract.k3 * sharp.tpd3.vTap2x);
        sharp.flProd.k4 <= (coef.flCoefFract.k4 * sharp.tpd1.vTap1x);
        sharp.flProd.k5 <= (coef.flCoefFract.k5 * sharp.tpd2.vTap1x);
        sharp.flProd.k6 <= (coef.flCoefFract.k6 * sharp.tpd3.vTap1x);
        sharp.flProd.k7 <= (coef.flCoefFract.k7 * sharp.tpd1.vTap0x);
        sharp.flProd.k8 <= (coef.flCoefFract.k8 * sharp.tpd2.vTap0x);
        sharp.flProd.k9 <= (coef.flCoefFract.k9 * sharp.tpd3.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.flToSnFxProd.k1 <= to_sfixed((sharp.flProd.k1), sharp.flToSnFxProd.k1);
        sharp.flToSnFxProd.k2 <= to_sfixed((sharp.flProd.k2), sharp.flToSnFxProd.k2);
        sharp.flToSnFxProd.k3 <= to_sfixed((sharp.flProd.k3), sharp.flToSnFxProd.k3);
        sharp.flToSnFxProd.k4 <= to_sfixed((sharp.flProd.k4), sharp.flToSnFxProd.k4);
        sharp.flToSnFxProd.k5 <= to_sfixed((sharp.flProd.k5), sharp.flToSnFxProd.k5);
        sharp.flToSnFxProd.k6 <= to_sfixed((sharp.flProd.k6), sharp.flToSnFxProd.k6);
        sharp.flToSnFxProd.k7 <= to_sfixed((sharp.flProd.k7), sharp.flToSnFxProd.k7);
        sharp.flToSnFxProd.k8 <= to_sfixed((sharp.flProd.k8), sharp.flToSnFxProd.k8);
        sharp.flToSnFxProd.k9 <= to_sfixed((sharp.flProd.k9), sharp.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snFxToSnProd.k1 <= to_signed(sharp.flToSnFxProd.k1(19 downto 0), 20);
        sharp.snFxToSnProd.k2 <= to_signed(sharp.flToSnFxProd.k2(19 downto 0), 20);
        sharp.snFxToSnProd.k3 <= to_signed(sharp.flToSnFxProd.k3(19 downto 0), 20);
        sharp.snFxToSnProd.k4 <= to_signed(sharp.flToSnFxProd.k4(19 downto 0), 20);
        sharp.snFxToSnProd.k5 <= to_signed(sharp.flToSnFxProd.k5(19 downto 0), 20);
        sharp.snFxToSnProd.k6 <= to_signed(sharp.flToSnFxProd.k6(19 downto 0), 20);
        sharp.snFxToSnProd.k7 <= to_signed(sharp.flToSnFxProd.k7(19 downto 0), 20);
        sharp.snFxToSnProd.k8 <= to_signed(sharp.flToSnFxProd.k8(19 downto 0), 20);
        sharp.snFxToSnProd.k9 <= to_signed(sharp.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snToTrimProd.k1 <= sharp.snFxToSnProd.k1(19 downto 5);
        sharp.snToTrimProd.k2 <= sharp.snFxToSnProd.k2(19 downto 5);
        sharp.snToTrimProd.k3 <= sharp.snFxToSnProd.k3(19 downto 5);
        sharp.snToTrimProd.k4 <= sharp.snFxToSnProd.k4(19 downto 5);
        sharp.snToTrimProd.k5 <= sharp.snFxToSnProd.k5(19 downto 5);
        sharp.snToTrimProd.k6 <= sharp.snFxToSnProd.k6(19 downto 5);
        sharp.snToTrimProd.k7 <= sharp.snFxToSnProd.k7(19 downto 5);
        sharp.snToTrimProd.k8 <= sharp.snFxToSnProd.k8(19 downto 5);
        sharp.snToTrimProd.k9 <= sharp.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        sharp.snSum.red            <= (others => '0');
        sharp.snSum.green          <= (others => '0');
        sharp.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        sharp.snSum.red   <= resize(sharp.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        sharp.snSum.green <= resize(sharp.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        sharp.snSum.blue  <= resize(sharp.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snToTrimSum.red    <= sharp.snSum.red(sharp.snSum.red'left downto FRAC_BITS_TO_KEEP);
        sharp.snToTrimSum.green  <= sharp.snSum.green(sharp.snSum.green'left downto FRAC_BITS_TO_KEEP);
        sharp.snToTrimSum.blue   <= sharp.snSum.blue(sharp.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        sharp.rgbSum  <= (sharp.snToTrimSum.red + sharp.snToTrimSum.green + sharp.snToTrimSum.blue);
    if (sharp.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.sharp.red <= black;
    elsif (unsigned(sharp.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.sharp.red <= white;
    else
        oRgb.sharp.red <= std_logic_vector(sharp.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate RED_FRAME_ENABLED;
GREEN_FRAME_ENABLED: if (GREEN_FRAME = true) generate
signal sharp         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        sharp.tpd1.vTap0x <= rgbMac2.red;
        sharp.tpd2.vTap0x <= sharp.tpd1.vTap0x;
        sharp.tpd3.vTap0x <= sharp.tpd2.vTap0x;
        sharp.tpd1.vTap1x <= rgbMac2.green;
        sharp.tpd2.vTap1x <= sharp.tpd1.vTap1x;
        sharp.tpd3.vTap1x <= sharp.tpd2.vTap1x;
        sharp.tpd1.vTap2x <= rgbMac2.blue;
        sharp.tpd2.vTap2x <= sharp.tpd1.vTap2x;
        sharp.tpd3.vTap2x <= sharp.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.flProd.k1 <= (coef.flCoefFract.k1 * sharp.tpd1.vTap2x);
        sharp.flProd.k2 <= (coef.flCoefFract.k2 * sharp.tpd2.vTap2x);
        sharp.flProd.k3 <= (coef.flCoefFract.k3 * sharp.tpd3.vTap2x);
        sharp.flProd.k4 <= (coef.flCoefFract.k4 * sharp.tpd1.vTap1x);
        sharp.flProd.k5 <= (coef.flCoefFract.k5 * sharp.tpd2.vTap1x);
        sharp.flProd.k6 <= (coef.flCoefFract.k6 * sharp.tpd3.vTap1x);
        sharp.flProd.k7 <= (coef.flCoefFract.k7 * sharp.tpd1.vTap0x);
        sharp.flProd.k8 <= (coef.flCoefFract.k8 * sharp.tpd2.vTap0x);
        sharp.flProd.k9 <= (coef.flCoefFract.k9 * sharp.tpd3.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.flToSnFxProd.k1 <= to_sfixed((sharp.flProd.k1), sharp.flToSnFxProd.k1);
        sharp.flToSnFxProd.k2 <= to_sfixed((sharp.flProd.k2), sharp.flToSnFxProd.k2);
        sharp.flToSnFxProd.k3 <= to_sfixed((sharp.flProd.k3), sharp.flToSnFxProd.k3);
        sharp.flToSnFxProd.k4 <= to_sfixed((sharp.flProd.k4), sharp.flToSnFxProd.k4);
        sharp.flToSnFxProd.k5 <= to_sfixed((sharp.flProd.k5), sharp.flToSnFxProd.k5);
        sharp.flToSnFxProd.k6 <= to_sfixed((sharp.flProd.k6), sharp.flToSnFxProd.k6);
        sharp.flToSnFxProd.k7 <= to_sfixed((sharp.flProd.k7), sharp.flToSnFxProd.k7);
        sharp.flToSnFxProd.k8 <= to_sfixed((sharp.flProd.k8), sharp.flToSnFxProd.k8);
        sharp.flToSnFxProd.k9 <= to_sfixed((sharp.flProd.k9), sharp.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snFxToSnProd.k1 <= to_signed(sharp.flToSnFxProd.k1(19 downto 0), 20);
        sharp.snFxToSnProd.k2 <= to_signed(sharp.flToSnFxProd.k2(19 downto 0), 20);
        sharp.snFxToSnProd.k3 <= to_signed(sharp.flToSnFxProd.k3(19 downto 0), 20);
        sharp.snFxToSnProd.k4 <= to_signed(sharp.flToSnFxProd.k4(19 downto 0), 20);
        sharp.snFxToSnProd.k5 <= to_signed(sharp.flToSnFxProd.k5(19 downto 0), 20);
        sharp.snFxToSnProd.k6 <= to_signed(sharp.flToSnFxProd.k6(19 downto 0), 20);
        sharp.snFxToSnProd.k7 <= to_signed(sharp.flToSnFxProd.k7(19 downto 0), 20);
        sharp.snFxToSnProd.k8 <= to_signed(sharp.flToSnFxProd.k8(19 downto 0), 20);
        sharp.snFxToSnProd.k9 <= to_signed(sharp.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snToTrimProd.k1 <= sharp.snFxToSnProd.k1(19 downto 5);
        sharp.snToTrimProd.k2 <= sharp.snFxToSnProd.k2(19 downto 5);
        sharp.snToTrimProd.k3 <= sharp.snFxToSnProd.k3(19 downto 5);
        sharp.snToTrimProd.k4 <= sharp.snFxToSnProd.k4(19 downto 5);
        sharp.snToTrimProd.k5 <= sharp.snFxToSnProd.k5(19 downto 5);
        sharp.snToTrimProd.k6 <= sharp.snFxToSnProd.k6(19 downto 5);
        sharp.snToTrimProd.k7 <= sharp.snFxToSnProd.k7(19 downto 5);
        sharp.snToTrimProd.k8 <= sharp.snFxToSnProd.k8(19 downto 5);
        sharp.snToTrimProd.k9 <= sharp.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        sharp.snSum.red            <= (others => '0');
        sharp.snSum.green          <= (others => '0');
        sharp.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        sharp.snSum.red   <= resize(sharp.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        sharp.snSum.green <= resize(sharp.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        sharp.snSum.blue  <= resize(sharp.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                             resize(sharp.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snToTrimSum.red    <= sharp.snSum.red(sharp.snSum.red'left downto FRAC_BITS_TO_KEEP);
        sharp.snToTrimSum.green  <= sharp.snSum.green(sharp.snSum.green'left downto FRAC_BITS_TO_KEEP);
        sharp.snToTrimSum.blue   <= sharp.snSum.blue(sharp.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.rgbSum  <= (sharp.snToTrimSum.red + sharp.snToTrimSum.green + sharp.snToTrimSum.blue);
    if (sharp.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.sharp.green <= black;
    elsif (unsigned(sharp.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.sharp.green <= white;
    else
        oRgb.sharp.green <= std_logic_vector(sharp.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate GREEN_FRAME_ENABLED;
BLUE_FRAME_ENABLED: if (BLUE_FRAME = true) generate
signal sharp         : filtersRecord;
begin
process (clk) begin
    if rising_edge(clk) then 
        sharp.tpd1.vTap0x <= rgbMac3.red;
        sharp.tpd2.vTap0x <= sharp.tpd1.vTap0x;
        sharp.tpd3.vTap0x <= sharp.tpd2.vTap0x;
        sharp.tpd1.vTap1x <= rgbMac3.green;
        sharp.tpd2.vTap1x <= sharp.tpd1.vTap1x;
        sharp.tpd3.vTap1x <= sharp.tpd2.vTap1x;
        sharp.tpd1.vTap2x <= rgbMac3.blue;
        sharp.tpd2.vTap2x <= sharp.tpd1.vTap2x;
        sharp.tpd3.vTap2x <= sharp.tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.flProd.k1 <= (coef.flCoefFract.k1 * sharp.tpd1.vTap2x);
        sharp.flProd.k2 <= (coef.flCoefFract.k2 * sharp.tpd2.vTap2x);
        sharp.flProd.k3 <= (coef.flCoefFract.k3 * sharp.tpd3.vTap2x);
        sharp.flProd.k4 <= (coef.flCoefFract.k4 * sharp.tpd1.vTap1x);
        sharp.flProd.k5 <= (coef.flCoefFract.k5 * sharp.tpd2.vTap1x);
        sharp.flProd.k6 <= (coef.flCoefFract.k6 * sharp.tpd3.vTap1x);
        sharp.flProd.k7 <= (coef.flCoefFract.k7 * sharp.tpd1.vTap0x);
        sharp.flProd.k8 <= (coef.flCoefFract.k8 * sharp.tpd2.vTap0x);
        sharp.flProd.k9 <= (coef.flCoefFract.k9 * sharp.tpd3.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.flToSnFxProd.k1 <= to_sfixed((sharp.flProd.k1), sharp.flToSnFxProd.k1);
        sharp.flToSnFxProd.k2 <= to_sfixed((sharp.flProd.k2), sharp.flToSnFxProd.k2);
        sharp.flToSnFxProd.k3 <= to_sfixed((sharp.flProd.k3), sharp.flToSnFxProd.k3);
        sharp.flToSnFxProd.k4 <= to_sfixed((sharp.flProd.k4), sharp.flToSnFxProd.k4);
        sharp.flToSnFxProd.k5 <= to_sfixed((sharp.flProd.k5), sharp.flToSnFxProd.k5);
        sharp.flToSnFxProd.k6 <= to_sfixed((sharp.flProd.k6), sharp.flToSnFxProd.k6);
        sharp.flToSnFxProd.k7 <= to_sfixed((sharp.flProd.k7), sharp.flToSnFxProd.k7);
        sharp.flToSnFxProd.k8 <= to_sfixed((sharp.flProd.k8), sharp.flToSnFxProd.k8);
        sharp.flToSnFxProd.k9 <= to_sfixed((sharp.flProd.k9), sharp.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snFxToSnProd.k1 <= to_signed(sharp.flToSnFxProd.k1(19 downto 0), 20);
        sharp.snFxToSnProd.k2 <= to_signed(sharp.flToSnFxProd.k2(19 downto 0), 20);
        sharp.snFxToSnProd.k3 <= to_signed(sharp.flToSnFxProd.k3(19 downto 0), 20);
        sharp.snFxToSnProd.k4 <= to_signed(sharp.flToSnFxProd.k4(19 downto 0), 20);
        sharp.snFxToSnProd.k5 <= to_signed(sharp.flToSnFxProd.k5(19 downto 0), 20);
        sharp.snFxToSnProd.k6 <= to_signed(sharp.flToSnFxProd.k6(19 downto 0), 20);
        sharp.snFxToSnProd.k7 <= to_signed(sharp.flToSnFxProd.k7(19 downto 0), 20);
        sharp.snFxToSnProd.k8 <= to_signed(sharp.flToSnFxProd.k8(19 downto 0), 20);
        sharp.snFxToSnProd.k9 <= to_signed(sharp.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snToTrimProd.k1 <= sharp.snFxToSnProd.k1(19 downto 5);
        sharp.snToTrimProd.k2 <= sharp.snFxToSnProd.k2(19 downto 5);
        sharp.snToTrimProd.k3 <= sharp.snFxToSnProd.k3(19 downto 5);
        sharp.snToTrimProd.k4 <= sharp.snFxToSnProd.k4(19 downto 5);
        sharp.snToTrimProd.k5 <= sharp.snFxToSnProd.k5(19 downto 5);
        sharp.snToTrimProd.k6 <= sharp.snFxToSnProd.k6(19 downto 5);
        sharp.snToTrimProd.k7 <= sharp.snFxToSnProd.k7(19 downto 5);
        sharp.snToTrimProd.k8 <= sharp.snFxToSnProd.k8(19 downto 5);
        sharp.snToTrimProd.k9 <= sharp.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        sharp.snSum.red            <= (others => '0');
        sharp.snSum.green          <= (others => '0');
        sharp.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        sharp.snSum.red   <= resize(sharp.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(sharp.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(sharp.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        sharp.snSum.green <= resize(sharp.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(sharp.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(sharp.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        sharp.snSum.blue  <= resize(sharp.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(sharp.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(sharp.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        sharp.snToTrimSum.red    <= sharp.snSum.red(sharp.snSum.red'left downto FRAC_BITS_TO_KEEP);
        sharp.snToTrimSum.green  <= sharp.snSum.green(sharp.snSum.green'left downto FRAC_BITS_TO_KEEP);
        sharp.snToTrimSum.blue   <= sharp.snSum.blue(sharp.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;    
process (clk) begin
    if rising_edge(clk) then 
        sharp.rgbSum  <= (sharp.snToTrimSum.red + sharp.snToTrimSum.green + sharp.snToTrimSum.blue);
    if (sharp.rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        oRgb.sharp.blue <= black;
    elsif (unsigned(sharp.rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        oRgb.sharp.blue <= white;
    else
        oRgb.sharp.blue <= std_logic_vector(sharp.rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
end generate BLUE_FRAME_ENABLED;
end generate SHARP_FRAME_ENABLED;
----------------------------------------------------------------------------------------
--                                CGAIN_FRAME
----------------------------------------------------------------------------------------
CGAIN_FRAME_ENABLED: if (CGAIN_FRAME = true) generate
----------------------------------------------------------------------------------------
--  CGAIN
--  |----------------------------|
--  |R  =  1.375 - 0.250 - 0.500 |
--  |G  = -0.500 + 1.375 - 0.250 |
--  |B  = -0.250 - 0.500 + 1.375 |
--  |----------------------------|
    -- signal kCg1           : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
    -- signal kCg2           : std_logic_vector(15 downto 0) := x"FF06";-- -250   = -0.250
    -- signal kCg3           : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
    -- signal kCg4           : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
    -- signal kCg5           : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
    -- signal kCg6           : std_logic_vector(15 downto 0) := x"FF06";-- -250   = -0.250
    -- signal kCg7           : std_logic_vector(15 downto 0) := x"FF06";-- -250   = -0.250
    -- signal kCg8           : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
    -- signal kCg9           : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
    signal kCg1           : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
    signal kCg2           : std_logic_vector(15 downto 0) := x"FF06";-- -250   = -0.250
    signal kCg3           : std_logic_vector(15 downto 0) := x"FF06";-- -500   = -0.500
    signal kCg4           : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
    signal kCg5           : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
    signal kCg6           : std_logic_vector(15 downto 0) := x"FE0C";-- -250   = -0.250
    signal kCg7           : std_logic_vector(15 downto 0) := x"FE0C";-- -250   = -0.250
    signal kCg8           : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
    signal kCg9           : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
----------------------------------------------------------------------------------------
    signal rgbSyncValid   : std_logic_vector(8 downto 0)  := "000000000";
    signal cc             : ccRecord;
    signal cGain          : channel;
    signal tpd1           : tapsFl;
    signal tpd2           : tapsFl;
    signal tpd3           : tapsFl;
begin
    cc.flCoef.k1 <= to_float((signed(kCg1)),cc.flCoef.k1);
    cc.flCoef.k2 <= to_float((signed(kCg2)),cc.flCoef.k2);
    cc.flCoef.k3 <= to_float((signed(kCg3)),cc.flCoef.k3);
    cc.flCoef.k4 <= to_float((signed(kCg4)),cc.flCoef.k4);
    cc.flCoef.k5 <= to_float((signed(kCg5)),cc.flCoef.k5);
    cc.flCoef.k6 <= to_float((signed(kCg6)),cc.flCoef.k6);
    cc.flCoef.k7 <= to_float((signed(kCg7)),cc.flCoef.k7);
    cc.flCoef.k8 <= to_float((signed(kCg8)),cc.flCoef.k8);
    cc.flCoef.k9 <= to_float((signed(kCg9)),cc.flCoef.k9);
process (clk,rst_l) begin
    if (rst_l = lo) then
        cc.rgbToFl.red   <= (others => '0');
        cc.rgbToFl.green <= (others => '0');
        cc.rgbToFl.blue  <= (others => '0');
    elsif rising_edge(clk) then 
        cc.rgbToFl.red   <= to_float(unsigned(iRgb.red), cc.rgbToFl.red);
        cc.rgbToFl.green <= to_float(unsigned(iRgb.green), cc.rgbToFl.green);
        cc.rgbToFl.blue  <= to_float(unsigned(iRgb.blue), cc.rgbToFl.blue);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        tpd1.vTap0x <= cc.rgbToFl.blue;
        tpd2.vTap0x <= cc.rgbToFl.green;
        tpd3.vTap0x <= cc.rgbToFl.red;
        tpd1.vTap1x <= cc.rgbToFl.blue;
        tpd2.vTap1x <= cc.rgbToFl.green;
        tpd3.vTap1x <= cc.rgbToFl.red;
        tpd1.vTap2x <= cc.rgbToFl.blue;
        tpd2.vTap2x <= cc.rgbToFl.green;
        tpd3.vTap2x <= cc.rgbToFl.red;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        cc.flCoefFract.k1 <= (cc.flCoef.k1 * fract * thresholdFl);
        cc.flCoefFract.k2 <= (cc.flCoef.k2 * fract * thresholdFl);
        cc.flCoefFract.k3 <= (cc.flCoef.k3 * fract * thresholdFl);
        cc.flCoefFract.k4 <= (cc.flCoef.k4 * fract * thresholdFl);
        cc.flCoefFract.k5 <= (cc.flCoef.k5 * fract * thresholdFl);
        cc.flCoefFract.k6 <= (cc.flCoef.k6 * fract * thresholdFl);
        cc.flCoefFract.k7 <= (cc.flCoef.k7 * fract * thresholdFl);
        cc.flCoefFract.k8 <= (cc.flCoef.k8 * fract * thresholdFl);
        cc.flCoefFract.k9 <= (cc.flCoef.k9 * fract * thresholdFl);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        cc.flProd.k1 <= (cc.flCoefFract.k1 * tpd3.vTap2x);
        cc.flProd.k2 <= (cc.flCoefFract.k2 * tpd2.vTap2x);
        cc.flProd.k3 <= (cc.flCoefFract.k3 * tpd1.vTap2x);
        cc.flProd.k4 <= (cc.flCoefFract.k4 * tpd3.vTap1x);
        cc.flProd.k5 <= (cc.flCoefFract.k5 * tpd2.vTap1x);
        cc.flProd.k6 <= (cc.flCoefFract.k6 * tpd1.vTap1x);
        cc.flProd.k7 <= (cc.flCoefFract.k7 * tpd3.vTap0x);
        cc.flProd.k8 <= (cc.flCoefFract.k8 * tpd2.vTap0x);
        cc.flProd.k9 <= (cc.flCoefFract.k9 * tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        cc.flToSnFxProd.k1 <= to_sfixed((cc.flProd.k1), cc.flToSnFxProd.k1);
        cc.flToSnFxProd.k2 <= to_sfixed((cc.flProd.k2), cc.flToSnFxProd.k2);
        cc.flToSnFxProd.k3 <= to_sfixed((cc.flProd.k3), cc.flToSnFxProd.k3);
        cc.flToSnFxProd.k4 <= to_sfixed((cc.flProd.k4), cc.flToSnFxProd.k4);
        cc.flToSnFxProd.k5 <= to_sfixed((cc.flProd.k5), cc.flToSnFxProd.k5);
        cc.flToSnFxProd.k6 <= to_sfixed((cc.flProd.k6), cc.flToSnFxProd.k6);
        cc.flToSnFxProd.k7 <= to_sfixed((cc.flProd.k7), cc.flToSnFxProd.k7);
        cc.flToSnFxProd.k8 <= to_sfixed((cc.flProd.k8), cc.flToSnFxProd.k8);
        cc.flToSnFxProd.k9 <= to_sfixed((cc.flProd.k9), cc.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        cc.snFxToSnProd.k1 <= to_signed(cc.flToSnFxProd.k1(19 downto 0), 20);
        cc.snFxToSnProd.k2 <= to_signed(cc.flToSnFxProd.k2(19 downto 0), 20);
        cc.snFxToSnProd.k3 <= to_signed(cc.flToSnFxProd.k3(19 downto 0), 20);
        cc.snFxToSnProd.k4 <= to_signed(cc.flToSnFxProd.k4(19 downto 0), 20);
        cc.snFxToSnProd.k5 <= to_signed(cc.flToSnFxProd.k5(19 downto 0), 20);
        cc.snFxToSnProd.k6 <= to_signed(cc.flToSnFxProd.k6(19 downto 0), 20);
        cc.snFxToSnProd.k7 <= to_signed(cc.flToSnFxProd.k7(19 downto 0), 20);
        cc.snFxToSnProd.k8 <= to_signed(cc.flToSnFxProd.k8(19 downto 0), 20);
        cc.snFxToSnProd.k9 <= to_signed(cc.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        cc.snToTrimProd.k1 <= cc.snFxToSnProd.k1(19 downto 5);
        cc.snToTrimProd.k2 <= cc.snFxToSnProd.k2(19 downto 5);
        cc.snToTrimProd.k3 <= cc.snFxToSnProd.k3(19 downto 5);
        cc.snToTrimProd.k4 <= cc.snFxToSnProd.k4(19 downto 5);
        cc.snToTrimProd.k5 <= cc.snFxToSnProd.k5(19 downto 5);
        cc.snToTrimProd.k6 <= cc.snFxToSnProd.k6(19 downto 5);
        cc.snToTrimProd.k7 <= cc.snFxToSnProd.k7(19 downto 5);
        cc.snToTrimProd.k8 <= cc.snFxToSnProd.k8(19 downto 5);
        cc.snToTrimProd.k9 <= cc.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        cc.snSum.red            <= (others => '0');
        cc.snSum.green          <= (others => '0');
        cc.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        cc.snSum.red   <= resize(cc.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                          resize(cc.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                          resize(cc.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        cc.snSum.green <= resize(cc.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                          resize(cc.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                          resize(cc.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        cc.snSum.blue  <= resize(cc.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                          resize(cc.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                          resize(cc.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        cc.snToTrimSum.red    <= cc.snSum.red(cc.snSum.red'left downto FRAC_BITS_TO_KEEP);
        cc.snToTrimSum.green  <= cc.snSum.green(cc.snSum.green'left downto FRAC_BITS_TO_KEEP);
        cc.snToTrimSum.blue   <= cc.snSum.blue(cc.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;
process (clk, rst_l) begin
    if (rst_l = lo) then
        cGain.red    <= (others => '0');
        cGain.green  <= (others => '0');
        cGain.blue   <= (others => '0');
    elsif rising_edge(clk) then
        if (cc.snToTrimSum.red(ROUND_RESULT_WIDTH-1) = hi) then	
            cGain.red <= black;
        elsif (unsigned(cc.snToTrimSum.red(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then	
            cGain.red <= white;
        else
            cGain.red <= std_logic_vector(cc.snToTrimSum.red(i_data_width-1 downto 0));
        end if;
        if (cc.snToTrimSum.green(ROUND_RESULT_WIDTH-1) = hi) then
            cGain.green <= black;
        elsif (unsigned(cc.snToTrimSum.green(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
            cGain.green <= white;
        else
            cGain.green <= std_logic_vector(cc.snToTrimSum.green(i_data_width-1 downto 0));
        end if;
        if (cc.snToTrimSum.blue(ROUND_RESULT_WIDTH-1) = hi) then
            cGain.blue <= black;
        elsif (unsigned(cc.snToTrimSum.blue(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
            cGain.blue <= white;
        else
            cGain.blue <= std_logic_vector(cc.snToTrimSum.blue(i_data_width-1 downto 0));
        end if;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncValid(0)  <= iRgb.valid;
        rgbSyncValid(1)  <= rgbSyncValid(0);
        rgbSyncValid(2)  <= rgbSyncValid(1);
        rgbSyncValid(3)  <= rgbSyncValid(2);
        rgbSyncValid(4)  <= rgbSyncValid(3);
        rgbSyncValid(5)  <= rgbSyncValid(4);
        rgbSyncValid(6)  <= rgbSyncValid(5);
        rgbSyncValid(7)  <= rgbSyncValid(6);
        rgbSyncValid(8)  <= rgbSyncValid(7);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        oRgb.cgain.valid  <= rgbSyncValid(8);
        oRgb.cgain.red    <= cGain.red;
        oRgb.cgain.green  <= cGain.green;
        oRgb.cgain.blue   <= cGain.blue;
    end if;
end process;
end generate CGAIN_FRAME_ENABLED;
----------------------------------------------------------------------------------------
--                                YCBCR_FRAME
----------------------------------------------------------------------------------------
YCBCR_FRAME_ENABLED: if (YCBCR_FRAME = true) generate
----------------------------------------------------------------------------------------
--  YCBCR
--  |----------------------------------|
--  |Y  =  0.257 + 0.504 + 0.098 + 16  |
--  |Cb = -0.148 - 0.291 + 0.439 + 128 |
--  |Cr =  0.439 - 0.368 - 0.071 + 128 |
--  |----------------------------------|
    signal kYc1           : std_logic_vector(15 downto 0) := x"0101";--  0.257
    signal kYc2           : std_logic_vector(15 downto 0) := x"01F8";--  0.504
    signal kYc3           : std_logic_vector(15 downto 0) := x"0062";--  0.098
    signal kYc4           : std_logic_vector(15 downto 0) := x"FF6C";-- -0.148
    signal kYc5           : std_logic_vector(15 downto 0) := x"FEDD";-- -0.291
    signal kYc6           : std_logic_vector(15 downto 0) := x"01B7";--  0.439
    signal kYc7           : std_logic_vector(15 downto 0) := x"01B7";--  0.439
    signal kYc8           : std_logic_vector(15 downto 0) := x"FE90";-- -0.368
    signal kYc9           : std_logic_vector(15 downto 0) := x"FFB9";-- -0.071
----------------------------------------------------------------------------------------
    signal rgbSyncValid   : std_logic_vector(8 downto 0)  := "000000000";
    constant i_full_range : boolean := true;
    signal ycbcr          : ccRecord;
    signal yRgb           : uChannel;
    signal YCBCR128       : unsigned(i_data_width-1 downto 0);
    signal YCBCR16        : unsigned(i_data_width-1 downto 0);
begin
    YCBCR128        <= shift_left(to_unsigned(one,i_data_width), i_data_width - 1);
    YCBCR16         <= shift_left(to_unsigned(one,i_data_width), i_data_width - 4);
    ycbcr.flCoef.k1 <= to_float((signed(kYc1)),ycbcr.flCoef.k1);
    ycbcr.flCoef.k2 <= to_float((signed(kYc2)),ycbcr.flCoef.k2);
    ycbcr.flCoef.k3 <= to_float((signed(kYc3)),ycbcr.flCoef.k3);
    ycbcr.flCoef.k4 <= to_float((signed(kYc4)),ycbcr.flCoef.k4);
    ycbcr.flCoef.k5 <= to_float((signed(kYc5)),ycbcr.flCoef.k5);
    ycbcr.flCoef.k6 <= to_float((signed(kYc6)),ycbcr.flCoef.k6);
    ycbcr.flCoef.k7 <= to_float((signed(kYc7)),ycbcr.flCoef.k7);
    ycbcr.flCoef.k8 <= to_float((signed(kYc8)),ycbcr.flCoef.k8);
    ycbcr.flCoef.k9 <= to_float((signed(kYc9)),ycbcr.flCoef.k9);
process (clk,rst_l) begin
    if (rst_l = lo) then
        ycbcr.rgbToFl.red   <= (others => '0');
        ycbcr.rgbToFl.green <= (others => '0');
        ycbcr.rgbToFl.blue  <= (others => '0');
    elsif rising_edge(clk) then 
        ycbcr.rgbToFl.red   <= to_float(unsigned(iRgb.red), ycbcr.rgbToFl.red);
        ycbcr.rgbToFl.green <= to_float(unsigned(iRgb.green), ycbcr.rgbToFl.green);
        ycbcr.rgbToFl.blue  <= to_float(unsigned(iRgb.blue), ycbcr.rgbToFl.blue);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        ycbcr.tpd1.vTap0x <= ycbcr.rgbToFl.blue;
        ycbcr.tpd2.vTap0x <= ycbcr.rgbToFl.green;
        ycbcr.tpd3.vTap0x <= ycbcr.rgbToFl.red;
        ycbcr.tpd1.vTap1x <= ycbcr.rgbToFl.blue;
        ycbcr.tpd2.vTap1x <= ycbcr.rgbToFl.green;
        ycbcr.tpd3.vTap1x <= ycbcr.rgbToFl.red;
        ycbcr.tpd1.vTap2x <= ycbcr.rgbToFl.blue;
        ycbcr.tpd2.vTap2x <= ycbcr.rgbToFl.green;
        ycbcr.tpd3.vTap2x <= ycbcr.rgbToFl.red;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        ycbcr.flCoefFract.k1 <= (ycbcr.flCoef.k1 * fract * thresholdFl);
        ycbcr.flCoefFract.k2 <= (ycbcr.flCoef.k2 * fract * thresholdFl);
        ycbcr.flCoefFract.k3 <= (ycbcr.flCoef.k3 * fract * thresholdFl);
        ycbcr.flCoefFract.k4 <= (ycbcr.flCoef.k4 * fract * thresholdFl);
        ycbcr.flCoefFract.k5 <= (ycbcr.flCoef.k5 * fract * thresholdFl);
        ycbcr.flCoefFract.k6 <= (ycbcr.flCoef.k6 * fract * thresholdFl);
        ycbcr.flCoefFract.k7 <= (ycbcr.flCoef.k7 * fract * thresholdFl);
        ycbcr.flCoefFract.k8 <= (ycbcr.flCoef.k8 * fract * thresholdFl);
        ycbcr.flCoefFract.k9 <= (ycbcr.flCoef.k9 * fract * thresholdFl);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        ycbcr.flProd.k1 <= (ycbcr.flCoefFract.k1 * ycbcr.tpd3.vTap2x);
        ycbcr.flProd.k2 <= (ycbcr.flCoefFract.k2 * ycbcr.tpd2.vTap2x);
        ycbcr.flProd.k3 <= (ycbcr.flCoefFract.k3 * ycbcr.tpd1.vTap2x);
        ycbcr.flProd.k4 <= (ycbcr.flCoefFract.k4 * ycbcr.tpd3.vTap1x);
        ycbcr.flProd.k5 <= (ycbcr.flCoefFract.k5 * ycbcr.tpd2.vTap1x);
        ycbcr.flProd.k6 <= (ycbcr.flCoefFract.k6 * ycbcr.tpd1.vTap1x);
        ycbcr.flProd.k7 <= (ycbcr.flCoefFract.k7 * ycbcr.tpd3.vTap0x);
        ycbcr.flProd.k8 <= (ycbcr.flCoefFract.k8 * ycbcr.tpd2.vTap0x);
        ycbcr.flProd.k9 <= (ycbcr.flCoefFract.k9 * ycbcr.tpd1.vTap0x);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        ycbcr.flToSnFxProd.k1 <= to_sfixed((ycbcr.flProd.k1), ycbcr.flToSnFxProd.k1);
        ycbcr.flToSnFxProd.k2 <= to_sfixed((ycbcr.flProd.k2), ycbcr.flToSnFxProd.k2);
        ycbcr.flToSnFxProd.k3 <= to_sfixed((ycbcr.flProd.k3), ycbcr.flToSnFxProd.k3);
        ycbcr.flToSnFxProd.k4 <= to_sfixed((ycbcr.flProd.k4), ycbcr.flToSnFxProd.k4);
        ycbcr.flToSnFxProd.k5 <= to_sfixed((ycbcr.flProd.k5), ycbcr.flToSnFxProd.k5);
        ycbcr.flToSnFxProd.k6 <= to_sfixed((ycbcr.flProd.k6), ycbcr.flToSnFxProd.k6);
        ycbcr.flToSnFxProd.k7 <= to_sfixed((ycbcr.flProd.k7), ycbcr.flToSnFxProd.k7);
        ycbcr.flToSnFxProd.k8 <= to_sfixed((ycbcr.flProd.k8), ycbcr.flToSnFxProd.k8);
        ycbcr.flToSnFxProd.k9 <= to_sfixed((ycbcr.flProd.k9), ycbcr.flToSnFxProd.k9);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        ycbcr.snFxToSnProd.k1 <= to_signed(ycbcr.flToSnFxProd.k1(19 downto 0), 20);
        ycbcr.snFxToSnProd.k2 <= to_signed(ycbcr.flToSnFxProd.k2(19 downto 0), 20);
        ycbcr.snFxToSnProd.k3 <= to_signed(ycbcr.flToSnFxProd.k3(19 downto 0), 20);
        ycbcr.snFxToSnProd.k4 <= to_signed(ycbcr.flToSnFxProd.k4(19 downto 0), 20);
        ycbcr.snFxToSnProd.k5 <= to_signed(ycbcr.flToSnFxProd.k5(19 downto 0), 20);
        ycbcr.snFxToSnProd.k6 <= to_signed(ycbcr.flToSnFxProd.k6(19 downto 0), 20);
        ycbcr.snFxToSnProd.k7 <= to_signed(ycbcr.flToSnFxProd.k7(19 downto 0), 20);
        ycbcr.snFxToSnProd.k8 <= to_signed(ycbcr.flToSnFxProd.k8(19 downto 0), 20);
        ycbcr.snFxToSnProd.k9 <= to_signed(ycbcr.flToSnFxProd.k9(19 downto 0), 20);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then 
        ycbcr.snToTrimProd.k1 <= ycbcr.snFxToSnProd.k1(19 downto 5);
        ycbcr.snToTrimProd.k2 <= ycbcr.snFxToSnProd.k2(19 downto 5);
        ycbcr.snToTrimProd.k3 <= ycbcr.snFxToSnProd.k3(19 downto 5);
        ycbcr.snToTrimProd.k4 <= ycbcr.snFxToSnProd.k4(19 downto 5);
        ycbcr.snToTrimProd.k5 <= ycbcr.snFxToSnProd.k5(19 downto 5);
        ycbcr.snToTrimProd.k6 <= ycbcr.snFxToSnProd.k6(19 downto 5);
        ycbcr.snToTrimProd.k7 <= ycbcr.snFxToSnProd.k7(19 downto 5);
        ycbcr.snToTrimProd.k8 <= ycbcr.snFxToSnProd.k8(19 downto 5);
        ycbcr.snToTrimProd.k9 <= ycbcr.snFxToSnProd.k9(19 downto 5);
    end if; 
end process;
process (clk,rst_l) begin
    if (rst_l = lo) then
        ycbcr.snSum.red            <= (others => '0');
        ycbcr.snSum.green          <= (others => '0');
        ycbcr.snSum.blue           <= (others => '0');
    elsif rising_edge(clk) then 
        ycbcr.snSum.red   <= resize(ycbcr.snToTrimProd.k1, ADD_RESULT_WIDTH) +
                             resize(ycbcr.snToTrimProd.k2, ADD_RESULT_WIDTH) +
                             resize(ycbcr.snToTrimProd.k3, ADD_RESULT_WIDTH) + ROUND;
        ycbcr.snSum.green <= resize(ycbcr.snToTrimProd.k4, ADD_RESULT_WIDTH) +
                             resize(ycbcr.snToTrimProd.k5, ADD_RESULT_WIDTH) +
                             resize(ycbcr.snToTrimProd.k6, ADD_RESULT_WIDTH) + ROUND;
        ycbcr.snSum.blue  <= resize(ycbcr.snToTrimProd.k7, ADD_RESULT_WIDTH) +
                             resize(ycbcr.snToTrimProd.k8, ADD_RESULT_WIDTH) +
                             resize(ycbcr.snToTrimProd.k9, ADD_RESULT_WIDTH) + ROUND;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        ycbcr.snToTrimSum.red    <= ycbcr.snSum.red(ycbcr.snSum.red'left downto FRAC_BITS_TO_KEEP);
        ycbcr.snToTrimSum.green  <= ycbcr.snSum.green(ycbcr.snSum.green'left downto FRAC_BITS_TO_KEEP);
        ycbcr.snToTrimSum.blue   <= ycbcr.snSum.blue(ycbcr.snSum.blue'left downto FRAC_BITS_TO_KEEP);
    end if; 
end process;
process (clk, rst_l)
    variable y_round      : unsigned(i_data_width-1 downto 0);
    variable cb_round     : unsigned(i_data_width-1 downto 0);
    variable cr_round     : unsigned(i_data_width-1 downto 0);
    begin
    if (rst_l = lo) then
        yRgb.red   <= (others => '0');
        yRgb.green <= (others => '0');
        yRgb.blue  <= (others => '0');
    elsif rising_edge(clk) then
    if (ycbcr.snToTrimSum.red(ROUND_RESULT_WIDTH-1) = hi)  then
        if i_full_range then
            y_round := YCBCR16 + 1;
        else
            y_round := to_unsigned(1, i_data_width);
        end if;
    else
        if i_full_range then
            y_round := YCBCR16;
        else
            y_round := (others => '0');
        end if;
    end if;
    if (ycbcr.snToTrimSum.green(ROUND_RESULT_WIDTH-1) = hi) then
        cb_round := resize(YCBCR128+1, i_data_width);
    else
        cb_round := YCBCR128;
    end if;
    if (ycbcr.snToTrimSum.blue(ROUND_RESULT_WIDTH-1) = hi) then
        cr_round := resize(YCBCR128+1, i_data_width);
    else
        cr_round := YCBCR128;
    end if;
    yRgb.red   <= (unsigned(ycbcr.snToTrimSum.red(i_data_width-1 downto 0))) + y_round;
    yRgb.green <= (unsigned(ycbcr.snToTrimSum.green(i_data_width-1 downto 0))) + cb_round;
    yRgb.blue  <= (unsigned(ycbcr.snToTrimSum.blue(i_data_width-1 downto 0))) + cr_round;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        rgbSyncValid(0)   <= iRgb.valid;
        rgbSyncValid(1)   <= rgbSyncValid(0);
        rgbSyncValid(2)   <= rgbSyncValid(1);
        rgbSyncValid(3)   <= rgbSyncValid(2);
        rgbSyncValid(4)   <= rgbSyncValid(3);
        rgbSyncValid(5)   <= rgbSyncValid(4);
        rgbSyncValid(6)   <= rgbSyncValid(5);
        rgbSyncValid(7)   <= rgbSyncValid(6);
        rgbSyncValid(8)   <= rgbSyncValid(7);
        oRgb.ycbcr.valid  <= rgbSyncValid(8);
    end if; 
end process;
process (clk) begin
    if rising_edge(clk) then
        oRgb.ycbcr.red     <= std_logic_vector(yRgb.red);
        oRgb.ycbcr.green   <= std_logic_vector(yRgb.green);
        oRgb.ycbcr.blue    <= std_logic_vector(yRgb.blue); 
    end if;
end process;
end generate YCBCR_FRAME_ENABLED;
YCBCR_FRAME_DISABLED: if (YCBCR_FRAME = false) generate
    oRgb.ycbcr.red     <= black;
    oRgb.ycbcr.blue    <= black;
    oRgb.ycbcr.green   <= black;
    oRgb.ycbcr.valid   <= lo;
end generate YCBCR_FRAME_DISABLED;
SHARP_FRAME_DISABLED: if (SHARP_FRAME = false) generate
    oRgb.sharp.red     <= black;
    oRgb.sharp.blue    <= black;
    oRgb.sharp.green   <= black;
    oRgb.sharp.valid   <= lo;
end generate SHARP_FRAME_DISABLED;
BLURE_FRAME_DISABLED: if (BLURE_FRAME = false) generate
    oRgb.blur.red     <= black;
    oRgb.blur.blue    <= black;
    oRgb.blur.green   <= black;
    oRgb.blur.valid   <= lo;
end generate BLURE_FRAME_DISABLED;
EMBOS_FRAME_DISABLED: if (EMBOS_FRAME = false) generate
    oRgb.embos.red     <= black;
    oRgb.embos.blue    <= black;
    oRgb.embos.green   <= black;
    oRgb.embos.valid   <= lo;
end generate EMBOS_FRAME_DISABLED;
SOBEL_FRAME_DISABLED: if (SOBEL_FRAME = false) generate
    oRgb.sobel.red     <= black;
    oRgb.sobel.blue    <= black;
    oRgb.sobel.green   <= black;
    oRgb.sobel.valid   <= lo;
end generate SOBEL_FRAME_DISABLED;
CGAIN_FRAME_DISABLED: if (CGAIN_FRAME = false) generate
    oRgb.cgain.red     <= black;
    oRgb.cgain.blue    <= black;
    oRgb.cgain.green   <= black;
    oRgb.cgain.valid   <= lo;
end generate CGAIN_FRAME_DISABLED;
end architecture;
