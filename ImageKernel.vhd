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
    SHARP_FRAME           : boolean := false;
    BLURE_FRAME           : boolean := false;
    EMBOS_FRAME           : boolean := false;
    YCBCR_FRAME           : boolean := false;
    SOBEL_FRAME           : boolean := false;
    CGAIN_FRAME           : boolean := true;
    i_data_width          : integer := 8);
port (
    clk                   : in std_logic;
    rst_l                 : in std_logic;
    iRgb                  : in channel;
    als                   : in coefficient;
    oRgb                  : out channel);
end ImageKernel;
architecture arch of ImageKernel is
    signal cc             : ccRecord;
    signal rgbSyncValid   : std_logic_vector(7 downto 0)  := x"00";
    signal threshold      : sfixed(9 downto 0)            := "0100000000";
    signal fract          : float32;
    signal ccThreshold    : float32;
    signal rgb            : channel;
    signal tpd1           : tapsFl;
    signal tpd2           : tapsFl;
    signal tpd3           : tapsFl;
    signal sobel_pax      : std_logic_vector(7 downto 0)  := x"00";
    signal sobel_pay      : std_logic_vector(7 downto 0)  := x"00";
begin
    ccThreshold         <= to_float ((threshold), ccThreshold);
    fract               <= to_float ((0.001), fract);
process (clk) begin
    if rising_edge(clk) then
        cc.flCoefFract.k1 <= (cc.flCoef.k1 * fract * ccThreshold);
        cc.flCoefFract.k2 <= (cc.flCoef.k2 * fract * ccThreshold);
        cc.flCoefFract.k3 <= (cc.flCoef.k3 * fract * ccThreshold);
        cc.flCoefFract.k4 <= (cc.flCoef.k4 * fract * ccThreshold);
        cc.flCoefFract.k5 <= (cc.flCoef.k5 * fract * ccThreshold);
        cc.flCoefFract.k6 <= (cc.flCoef.k6 * fract * ccThreshold);
        cc.flCoefFract.k7 <= (cc.flCoef.k7 * fract * ccThreshold);
        cc.flCoefFract.k8 <= (cc.flCoef.k8 * fract * ccThreshold);
        cc.flCoefFract.k9 <= (cc.flCoef.k9 * fract * ccThreshold);
    end if;
end process;
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
        rgb.red    <= (others => '0');
        rgb.green  <= (others => '0');
        rgb.blue   <= (others => '0');
    elsif rising_edge(clk) then
        if (cc.snToTrimSum.red(ROUND_RESULT_WIDTH-1) = hi) then	
            rgb.red <= black;
        elsif (unsigned(cc.snToTrimSum.red(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then	
            rgb.red <= white;
        else
            rgb.red <= std_logic_vector(cc.snToTrimSum.red(i_data_width-1 downto 0));
        end if;
        if (cc.snToTrimSum.green(ROUND_RESULT_WIDTH-1) = hi) then
            rgb.green <= black;
        elsif (unsigned(cc.snToTrimSum.green(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
            rgb.green <= white;
        else
            rgb.green <= std_logic_vector(cc.snToTrimSum.green(i_data_width-1 downto 0));
        end if;
        if (cc.snToTrimSum.blue(ROUND_RESULT_WIDTH-1) = hi) then
            rgb.blue <= black;
        elsif (unsigned(cc.snToTrimSum.blue(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
            rgb.blue <= white;
        else
            rgb.blue <= std_logic_vector(cc.snToTrimSum.blue(i_data_width-1 downto 0));
        end if;
    end if;
end process;
------------------------------------------------------------------------------
--                                SOBELX_FRAME
------------------------------------------------------------------------------
SOBELX_FRAME_ENABLED: if (SOBEL_FRAME = true) generate
--  |----------------|
--  | -1   +0   +1   |
--  | -2   +0   +2   |
--  | -1   +0   +1   |
--  |----------------|
    signal kX1            : std_logic_vector(15 downto 0) := x"FC18";--  [-1]
    signal kX2            : std_logic_vector(15 downto 0) := x"0000";--  [+0]
    signal kX3            : std_logic_vector(15 downto 0) := x"03E8";--  [+1]
    signal kX4            : std_logic_vector(15 downto 0) := x"F830";--  [-2]
    signal kX5            : std_logic_vector(15 downto 0) := x"0000";--  [+0]
    signal kX6            : std_logic_vector(15 downto 0) := x"07D0";--  [+2]
    signal kX7            : std_logic_vector(15 downto 0) := x"FC18";--  [-1]
    signal kX8            : std_logic_vector(15 downto 0) := x"0000";--  [+0]
    signal kX9            : std_logic_vector(15 downto 0) := x"03E8";--  [+1]
    signal sobelx         : SobelRecord;
begin
    sobelx.flCoef.k1 <= to_float((signed(kX1)),sobelx.flCoef.k1);
    sobelx.flCoef.k2 <= to_float((signed(kX2)),sobelx.flCoef.k2);
    sobelx.flCoef.k3 <= to_float((signed(kX3)),sobelx.flCoef.k3);
    sobelx.flCoef.k4 <= to_float((signed(kX4)),sobelx.flCoef.k4);
    sobelx.flCoef.k5 <= to_float((signed(kX5)),sobelx.flCoef.k5);
    sobelx.flCoef.k6 <= to_float((signed(kX6)),sobelx.flCoef.k6);
    sobelx.flCoef.k7 <= to_float((signed(kX7)),sobelx.flCoef.k7);
    sobelx.flCoef.k8 <= to_float((signed(kX8)),sobelx.flCoef.k8);
    sobelx.flCoef.k9 <= to_float((signed(kX9)),sobelx.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then
        sobelx.flCoefFract.k1 <= (sobelx.flCoef.k1 * fract * ccThreshold);
        sobelx.flCoefFract.k2 <= (sobelx.flCoef.k2 * fract * ccThreshold);
        sobelx.flCoefFract.k3 <= (sobelx.flCoef.k3 * fract * ccThreshold);
        sobelx.flCoefFract.k4 <= (sobelx.flCoef.k4 * fract * ccThreshold);
        sobelx.flCoefFract.k5 <= (sobelx.flCoef.k5 * fract * ccThreshold);
        sobelx.flCoefFract.k6 <= (sobelx.flCoef.k6 * fract * ccThreshold);
        sobelx.flCoefFract.k7 <= (sobelx.flCoef.k7 * fract * ccThreshold);
        sobelx.flCoefFract.k8 <= (sobelx.flCoef.k8 * fract * ccThreshold);
        sobelx.flCoefFract.k9 <= (sobelx.flCoef.k9 * fract * ccThreshold);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        sobelx.tpd1.vTap0x <= cc.rgbToFl.red;
        sobelx.tpd2.vTap0x <= sobelx.tpd1.vTap0x;
        sobelx.tpd3.vTap0x <= sobelx.tpd2.vTap0x;
        sobelx.tpd1.vTap1x <= cc.rgbToFl.green;
        sobelx.tpd2.vTap1x <= sobelx.tpd1.vTap1x;
        sobelx.tpd3.vTap1x <= sobelx.tpd2.vTap1x;
        sobelx.tpd1.vTap2x <= cc.rgbToFl.blue;
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
------------------------------------------------------------------------------
--                                SOBELY_FRAME
------------------------------------------------------------------------------
SOBELY_FRAME_ENABLED: if (SOBEL_FRAME = true) generate
--  |----------------|
--  | +1   +2   +1   |
--  | +0   +0   +0   |
--  | -1   -2   -1   |
--  |----------------|
    signal kY1            : std_logic_vector(15 downto 0) := x"03E8";--  +1
    signal kY2            : std_logic_vector(15 downto 0) := x"07D0";--  +2
    signal kY3            : std_logic_vector(15 downto 0) := x"03E8";--  +1
    signal kY4            : std_logic_vector(15 downto 0) := x"0000";--  -2
    signal kY5            : std_logic_vector(15 downto 0) := x"0000";--  +0
    signal kY6            : std_logic_vector(15 downto 0) := x"0000";--  +2
    signal kY7            : std_logic_vector(15 downto 0) := x"FC18";--  -1
    signal kY8            : std_logic_vector(15 downto 0) := x"F830";--  -2
    signal kY9            : std_logic_vector(15 downto 0) := x"FC18";--  -1
    signal sobely         : SobelRecord;
begin
    sobely.flCoef.k1 <= to_float((signed(kY1)),sobely.flCoef.k1);
    sobely.flCoef.k2 <= to_float((signed(kY2)),sobely.flCoef.k2);
    sobely.flCoef.k3 <= to_float((signed(kY3)),sobely.flCoef.k3);
    sobely.flCoef.k4 <= to_float((signed(kY4)),sobely.flCoef.k4);
    sobely.flCoef.k5 <= to_float((signed(kY5)),sobely.flCoef.k5);
    sobely.flCoef.k6 <= to_float((signed(kY6)),sobely.flCoef.k6);
    sobely.flCoef.k7 <= to_float((signed(kY7)),sobely.flCoef.k7);
    sobely.flCoef.k8 <= to_float((signed(kY8)),sobely.flCoef.k8);
    sobely.flCoef.k9 <= to_float((signed(kY9)),sobely.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then
        sobely.flCoefFract.k1 <= (sobely.flCoef.k1 * fract * ccThreshold);
        sobely.flCoefFract.k2 <= (sobely.flCoef.k2 * fract * ccThreshold);
        sobely.flCoefFract.k3 <= (sobely.flCoef.k3 * fract * ccThreshold);
        sobely.flCoefFract.k4 <= (sobely.flCoef.k4 * fract * ccThreshold);
        sobely.flCoefFract.k5 <= (sobely.flCoef.k5 * fract * ccThreshold);
        sobely.flCoefFract.k6 <= (sobely.flCoef.k6 * fract * ccThreshold);
        sobely.flCoefFract.k7 <= (sobely.flCoef.k7 * fract * ccThreshold);
        sobely.flCoefFract.k8 <= (sobely.flCoef.k8 * fract * ccThreshold);
        sobely.flCoefFract.k9 <= (sobely.flCoef.k9 * fract * ccThreshold);
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then
        ------------------------------------------------
        sobely.tpd1.vTap0x <= cc.rgbToFl.red;
        sobely.tpd2.vTap0x <= sobely.tpd1.vTap0x;
        sobely.tpd3.vTap0x <= sobely.tpd2.vTap0x;
        ------------------------------------------------
        sobely.tpd1.vTap1x <= cc.rgbToFl.green;
        sobely.tpd2.vTap1x <= sobely.tpd1.vTap1x;
        sobely.tpd3.vTap1x <= sobely.tpd2.vTap1x;
        ------------------------------------------------
        sobely.tpd1.vTap2x <= cc.rgbToFl.blue;
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
------------------------------------------------------------------------------
--                                SOBELXY_FRAME
------------------------------------------------------------------------------
SOBELXY_FRAME_ENABLED: if (SOBEL_FRAME = true) generate
    signal mx                    : unsigned (15 downto 0);
    signal my                    : unsigned (15 downto 0);
    signal sxy                   : unsigned (15 downto 0);
    signal sqr                   : std_logic_vector (31 downto 0);
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
    ivalid     => rgbSyncValid(7),
    idata      => sqr,
    ovalid     => validO,
    odata      => sbof);
------------------------------------------------------------------------------------------------
edgeValid <= hi when (unsigned(sbof(15 downto 0)) > unsigned(thresholdxy)) else lo;
------------------------------------------------------------------------------------------------
process (clk) begin
    if rising_edge(clk) then
        if (edgeValid = hi) then
            oRgb.red   <= black;
            oRgb.green <= black;
            oRgb.blue  <= black;
        else
            oRgb.red   <= white;
            oRgb.green <= white;
            oRgb.blue  <= white;
        end if;
    end if;
end process;
end generate SOBELXY_FRAME_ENABLED;
------------------------------------------------------------------------------
--                                BLURE_FRAME
------------------------------------------------------------------------------
BLURE_FRAME_ENABLED: if (BLURE_FRAME = true) generate
--  |-----------------------|
--  |R  = +1/9  +1/9  +1/9  |
--  |G  = +1/9  +1/9  +1/9  |
--  |B  = +1/9  +1/9  +1/9  |
--  |-----------------------|
    signal kB1            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB2            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB3            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB4            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB5            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB6            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB7            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB8            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal kB9            : std_logic_vector(15 downto 0) := x"006F";-- 0.111
    signal rgbColor       : std_logic_vector(7 downto 0)  := black;
    signal rgbSum         : signed(12 downto 0) :=(others => '0');
begin
    cc.flCoef.k1 <= to_float((signed(kB1)),cc.flCoef.k1);
    cc.flCoef.k2 <= to_float((signed(kB2)),cc.flCoef.k2);
    cc.flCoef.k3 <= to_float((signed(kB3)),cc.flCoef.k3);
    cc.flCoef.k4 <= to_float((signed(kB4)),cc.flCoef.k4);
    cc.flCoef.k5 <= to_float((signed(kB5)),cc.flCoef.k5);
    cc.flCoef.k6 <= to_float((signed(kB6)),cc.flCoef.k6);
    cc.flCoef.k7 <= to_float((signed(kB7)),cc.flCoef.k7);
    cc.flCoef.k8 <= to_float((signed(kB8)),cc.flCoef.k8);
    cc.flCoef.k9 <= to_float((signed(kB9)),cc.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then 
        tpd1.vTap0x <= cc.rgbToFl.red;
        tpd2.vTap0x <= tpd1.vTap0x;
        tpd3.vTap0x <= tpd2.vTap0x;
        tpd1.vTap1x <= cc.rgbToFl.green;
        tpd2.vTap1x <= tpd1.vTap1x;
        tpd3.vTap1x <= tpd2.vTap1x;
        tpd1.vTap2x <= cc.rgbToFl.blue;
        tpd2.vTap2x <= tpd1.vTap2x;
        tpd3.vTap2x <= tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        rgbSum         <= (cc.snToTrimSum.red + cc.snToTrimSum.green + cc.snToTrimSum.blue);
    if (rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        rgbColor <= black;
    elsif (unsigned(rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        rgbColor <= white;
    else
        rgbColor <= std_logic_vector(rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
    oRgb.red   <= rgbColor;
    oRgb.green <= rgbColor;
    oRgb.blue  <= rgbColor;
end generate BLURE_FRAME_ENABLED;
------------------------------------------------------------------------------
--                                EMBOS_FRAME
------------------------------------------------------------------------------
EMBOS_FRAME_ENABLED: if (EMBOS_FRAME = true) generate
--  |---------------------|
--  |R  = -1   -1    0    |
--  |G  = -1    0    1    |
--  |B  =  0    1    1    |
--  |---------------------|
    signal k1             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal k2             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal k3             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal k4             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal k5             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal k6             : std_logic_vector(15 downto 0) := x"03E8";--  1
    signal k7             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal k8             : std_logic_vector(15 downto 0) := x"03E8";--  1
    signal k9             : std_logic_vector(15 downto 0) := x"03E8";--  1
    signal rgbColor       : std_logic_vector(7 downto 0)  := black;
    signal rgbSum         : signed(12 downto 0) :=(others => '0');
begin
    cc.flCoef.k1 <= to_float((signed(k1)),cc.flCoef.k1);
    cc.flCoef.k2 <= to_float((signed(k2)),cc.flCoef.k2);
    cc.flCoef.k3 <= to_float((signed(k3)),cc.flCoef.k3);
    cc.flCoef.k4 <= to_float((signed(k4)),cc.flCoef.k4);
    cc.flCoef.k5 <= to_float((signed(k5)),cc.flCoef.k5);
    cc.flCoef.k6 <= to_float((signed(k6)),cc.flCoef.k6);
    cc.flCoef.k7 <= to_float((signed(k7)),cc.flCoef.k7);
    cc.flCoef.k8 <= to_float((signed(k8)),cc.flCoef.k8);
    cc.flCoef.k9 <= to_float((signed(k9)),cc.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then 
        tpd1.vTap0x <= cc.rgbToFl.red;
        tpd2.vTap0x <= tpd1.vTap0x;
        tpd3.vTap0x <= tpd2.vTap0x;
        tpd1.vTap1x <= cc.rgbToFl.green;
        tpd2.vTap1x <= tpd1.vTap1x;
        tpd3.vTap1x <= tpd2.vTap1x;
        tpd1.vTap2x <= cc.rgbToFl.blue;
        tpd2.vTap2x <= tpd1.vTap2x;
        tpd3.vTap2x <= tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        rgbSum         <= (cc.snToTrimSum.red + cc.snToTrimSum.green + cc.snToTrimSum.blue);
    if (rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        rgbColor <= black;
    elsif (unsigned(rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        rgbColor <= white;
    else
        rgbColor <= std_logic_vector(rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
    oRgb.red   <= rgbColor;
    oRgb.green <= rgbColor;
    oRgb.blue  <= rgbColor;
end generate EMBOS_FRAME_ENABLED;
------------------------------------------------------------------------------
--                                SHARP_FRAME
------------------------------------------------------------------------------
SHARP_FRAME_ENABLED: if (SHARP_FRAME = true) generate
--  |---------------------|
--  |R  =  0   -1    0    |
--  |G  = -1   +5   -1    |
--  |B  =  0   -1    0    |
--  |---------------------|
    signal k1             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal k2             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal k3             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal k4             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal k5             : std_logic_vector(15 downto 0) := x"1388";--  5
    signal k6             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal k7             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal k8             : std_logic_vector(15 downto 0) := x"FC18";-- -1
    signal k9             : std_logic_vector(15 downto 0) := x"0000";--  0
    signal rgbColor       : std_logic_vector(7 downto 0)  := black;
    signal rgbSum         : signed(12 downto 0) :=(others => '0');
begin
    cc.flCoef.k1 <= to_float((signed(k1)),cc.flCoef.k1);
    cc.flCoef.k2 <= to_float((signed(k2)),cc.flCoef.k2);
    cc.flCoef.k3 <= to_float((signed(k3)),cc.flCoef.k3);
    cc.flCoef.k4 <= to_float((signed(k4)),cc.flCoef.k4);
    cc.flCoef.k5 <= to_float((signed(k5)),cc.flCoef.k5);
    cc.flCoef.k6 <= to_float((signed(k6)),cc.flCoef.k6);
    cc.flCoef.k7 <= to_float((signed(k7)),cc.flCoef.k7);
    cc.flCoef.k8 <= to_float((signed(k8)),cc.flCoef.k8);
    cc.flCoef.k9 <= to_float((signed(k9)),cc.flCoef.k9);
process (clk) begin
    if rising_edge(clk) then 
        tpd1.vTap0x <= cc.rgbToFl.red;
        tpd2.vTap0x <= tpd1.vTap0x;
        tpd3.vTap0x <= tpd2.vTap0x;
        tpd1.vTap1x <= cc.rgbToFl.green;
        tpd2.vTap1x <= tpd1.vTap1x;
        tpd3.vTap1x <= tpd2.vTap1x;
        tpd1.vTap2x <= cc.rgbToFl.blue;
        tpd2.vTap2x <= tpd1.vTap2x;
        tpd3.vTap2x <= tpd2.vTap2x;
    end if;
end process;
process (clk) begin
    if rising_edge(clk) then 
        rgbSum         <= (cc.snToTrimSum.red + cc.snToTrimSum.green + cc.snToTrimSum.blue);
    if (rgbSum(ROUND_RESULT_WIDTH-1) = hi) then
        rgbColor <= black;
    elsif (unsigned(rgbSum(ROUND_RESULT_WIDTH-2 downto i_data_width)) /= zero) then
        rgbColor <= white;
    else
        rgbColor <= std_logic_vector(rgbSum(i_data_width-1 downto 0));
    end if;
    end if; 
end process;
    oRgb.red   <= rgbColor;
    oRgb.green <= rgbColor;
    oRgb.blue  <= rgbColor;
end generate SHARP_FRAME_ENABLED;
------------------------------------------------------------------------------
--                                CGAIN_FRAME
------------------------------------------------------------------------------
CGAIN_FRAME_ENABLED: if (CGAIN_FRAME = true) generate
--  |----------------------------|
--  |R  =  1.375 - 0.250 - 0.500 |
--  |G  = -0.500 + 1.375 - 0.250 |
--  |B  = -0.250 - 0.500 + 1.375 |
--  |----------------------------|
  signal k1               : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
  signal k2               : std_logic_vector(15 downto 0) := x"FF06";-- -250   = -0.250
  signal k3               : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
  signal k4               : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
  signal k5               : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
  signal k6               : std_logic_vector(15 downto 0) := x"FF06";-- -250   = -0.250
  signal k7               : std_logic_vector(15 downto 0) := x"FF06";-- -250   = -0.250
  signal k8               : std_logic_vector(15 downto 0) := x"FE0C";-- -500   = -0.500
  signal k9               : std_logic_vector(15 downto 0) := x"055F";--  1375  =  1.375
begin
    cc.flCoef.k1 <= to_float((signed(k1)),cc.flCoef.k1);
    cc.flCoef.k2 <= to_float((signed(k2)),cc.flCoef.k2);
    cc.flCoef.k3 <= to_float((signed(k3)),cc.flCoef.k3);
    cc.flCoef.k4 <= to_float((signed(k4)),cc.flCoef.k4);
    cc.flCoef.k5 <= to_float((signed(k5)),cc.flCoef.k5);
    cc.flCoef.k6 <= to_float((signed(k6)),cc.flCoef.k6);
    cc.flCoef.k7 <= to_float((signed(k7)),cc.flCoef.k7);
    cc.flCoef.k8 <= to_float((signed(k8)),cc.flCoef.k8);
    cc.flCoef.k9 <= to_float((signed(k9)),cc.flCoef.k9);
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
    oRgb.red   <= rgb.red;
    oRgb.green <= rgb.green;
    oRgb.blue  <= rgb.blue;
end generate CGAIN_FRAME_ENABLED;
------------------------------------------------------------------------------
--                                YCBCR_FRAME
------------------------------------------------------------------------------
YCBCR_FRAME_ENABLED: if (YCBCR_FRAME = true) generate
--  |----------------------------------|
--  |Y  =  0.257 + 0.504 + 0.098 + 16  |
--  |Cb = -0.148 - 0.291 + 0.439 + 128 |
--  |Cr =  0.439 - 0.368 - 0.071 + 128 |
--  |----------------------------------|
  constant i_full_range   : boolean := true;
  signal k1               : std_logic_vector(15 downto 0) := x"0101";--  0.257
  signal k2               : std_logic_vector(15 downto 0) := x"01F8";--  0.504
  signal k3               : std_logic_vector(15 downto 0) := x"0062";--  0.098
  signal k4               : std_logic_vector(15 downto 0) := x"FF6C";-- -0.148
  signal k5               : std_logic_vector(15 downto 0) := x"FEDD";-- -0.291
  signal k6               : std_logic_vector(15 downto 0) := x"01B7";--  0.439
  signal k7               : std_logic_vector(15 downto 0) := x"01B7";--  0.439
  signal k8               : std_logic_vector(15 downto 0) := x"FE90";-- -0.368
  signal k9               : std_logic_vector(15 downto 0) := x"FFB9";-- -0.071
  signal yRgb             : uChannel;
  signal YCBCR128         : unsigned(i_data_width-1 downto 0);
  signal YCBCR16          : unsigned(i_data_width-1 downto 0);
begin
    YCBCR128     <= shift_left(to_unsigned(1,i_data_width), i_data_width-1);
    YCBCR16      <= shift_left(to_unsigned(1,i_data_width), i_data_width-4);
    cc.flCoef.k1 <= to_float((signed(k1)),cc.flCoef.k1);
    cc.flCoef.k2 <= to_float((signed(k2)),cc.flCoef.k2);
    cc.flCoef.k3 <= to_float((signed(k3)),cc.flCoef.k3);
    cc.flCoef.k4 <= to_float((signed(k4)),cc.flCoef.k4);
    cc.flCoef.k5 <= to_float((signed(k5)),cc.flCoef.k5);
    cc.flCoef.k6 <= to_float((signed(k6)),cc.flCoef.k6);
    cc.flCoef.k7 <= to_float((signed(k7)),cc.flCoef.k7);
    cc.flCoef.k8 <= to_float((signed(k8)),cc.flCoef.k8);
    cc.flCoef.k9 <= to_float((signed(k9)),cc.flCoef.k9);
    oRgb.red     <= std_logic_vector(yRgb.red);
    oRgb.green   <= std_logic_vector(yRgb.green);
    oRgb.blue    <= std_logic_vector(yRgb.blue);      
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
    if (cc.snToTrimSum.red(ROUND_RESULT_WIDTH-1) = hi)  then
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
    if (cc.snToTrimSum.green(ROUND_RESULT_WIDTH-1) = hi) then
        cb_round := resize(YCBCR128+1, i_data_width);
    else
        cb_round := YCBCR128;
    end if;
    if (cc.snToTrimSum.blue(ROUND_RESULT_WIDTH-1) = hi) then
        cr_round := resize(YCBCR128+1, i_data_width);
    else
        cr_round := YCBCR128;
    end if;
    yRgb.red   <= (unsigned(cc.snToTrimSum.red(i_data_width-1 downto 0))) + y_round;
    yRgb.green <= (unsigned(cc.snToTrimSum.green(i_data_width-1 downto 0))) + cb_round;
    yRgb.blue  <= (unsigned(cc.snToTrimSum.blue(i_data_width-1 downto 0))) + cr_round;
    end if;
end process;
end generate YCBCR_FRAME_ENABLED;
------------------------------------------------------------------------------
process (clk)begin
    if rising_edge(clk) then 
        rgbSyncValid(0) <= iRgb.valid;
        rgbSyncValid(1) <= rgbSyncValid(0);
        rgbSyncValid(2) <= rgbSyncValid(1);
        rgbSyncValid(3) <= rgbSyncValid(2);
        rgbSyncValid(4) <= rgbSyncValid(3);
        rgbSyncValid(5) <= rgbSyncValid(4);
        rgbSyncValid(6) <= rgbSyncValid(5);
        rgbSyncValid(7) <= rgbSyncValid(6);
        oRgb.valid      <= rgbSyncValid(7);
    end if; 
end process;
end architecture;