library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.fixed_pkg.all;
use work.float_pkg.all;
use work.constantspackage.all;
use work.vpfrecords.all;
use work.portspackage.all;
entity Filters is
generic (
    F_TES                 : boolean := false;
    F_RGB                 : boolean := false;
    F_SHP                 : boolean := false;
    F_BLU                 : boolean := false;
    F_EMB                 : boolean := false;
    F_YCC                 : boolean := false;
    F_SOB                 : boolean := false;
    F_CGA                 : boolean := false;
    F_HSV                 : boolean := false;
    F_HSL                 : boolean := false;
    F_CGA_TO_CGA          : boolean := false;
    F_CGA_TO_HSL          : boolean := false;
    F_CGA_TO_HSV          : boolean := false;
    F_CGA_TO_YCC          : boolean := false;
    F_CGA_TO_SHP          : boolean := false;
    F_CGA_TO_BLU          : boolean := false;
    F_SHP_TO_SHP          : boolean := false;
    F_SHP_TO_HSL          : boolean := false;
    F_SHP_TO_HSV          : boolean := false;
    F_SHP_TO_YCC          : boolean := false;
    F_SHP_TO_CGA          : boolean := false;
    F_SHP_TO_BLU          : boolean := false;
    F_BLU_TO_BLU          : boolean := false;
    F_BLU_TO_HSL          : boolean := false;
    F_BLU_TO_HSV          : boolean := false;
    F_BLU_TO_YCC          : boolean := false;
    F_BLU_TO_CGA          : boolean := false;
    F_BLU_TO_SHP          : boolean := false;
    img_width             : integer := 4096;
    img_height            : integer := 4096;
    i_data_width          : integer := 8);
port (
    clk                : in std_logic;
    rst_l              : in std_logic;
    txCord             : in coord;
    iRgb               : in channel;
    iKcoeff            : in kernelCoeff;
    oRgb               : out frameColors);
end Filters;
architecture Behavioral of Filters is
signal rgbImageKernel   : colors;
signal edgeValid        : std_logic := lo;
constant init_channel   : channel := (valid => lo, red => black, green => black, blue => black);
signal location         : cord := (x => 10, y => 10);
signal fRgb             : frameColors;
begin
oRgb     <= fRgb;
ImageKernelInst: Kernel
generic map(
    INRGB_FRAME         => F_RGB,
    SHARP_FRAME         => F_SHP,
    BLURE_FRAME         => F_BLU,
    EMBOS_FRAME         => F_EMB,
    YCBCR_FRAME         => F_YCC,
    SOBEL_FRAME         => F_SOB,
    CGAIN_FRAME         => F_CGA,
    HSV_FRAME           => F_HSV,
    HSL_FRAME           => F_HSL,
    img_width           => img_width,
    img_height          => img_height,
    i_data_width        => i_data_width)
port map(
    clk                 => clk,
    rst_l               => rst_l,
    txCord              => txCord,
    iRgb                => iRgb,
    iKcoeff             => iKcoeff,
    oEdgeValid          => edgeValid,
    oRgb                => rgbImageKernel);
CGA_TO_FILTRS1_FRAME_ENABLE: if (F_CGA_TO_HSV = true) or (F_CGA_TO_HSL = true) or (F_CGA_TO_YCC = true)  or (F_CGA_TO_SHP = true) or (F_CGA_TO_BLU = true) or (F_CGA_TO_CGA = true)generate
signal fRgb1             : colors;
begin
ImageKernelInst: Kernel
generic map(
    INRGB_FRAME         => false,
    SHARP_FRAME         => F_CGA_TO_SHP,
    BLURE_FRAME         => F_CGA_TO_BLU,
    EMBOS_FRAME         => false,
    YCBCR_FRAME         => F_CGA_TO_YCC,
    SOBEL_FRAME         => false,
    CGAIN_FRAME         => F_CGA_TO_CGA,
    HSV_FRAME           => F_CGA_TO_HSV,
    HSL_FRAME           => F_CGA_TO_HSL,
    img_width           => img_width,
    img_height          => img_height,
    i_data_width        => i_data_width)
port map(
    clk                 => clk,
    rst_l               => rst_l,
    txCord              => txCord,
    iRgb                => rgbImageKernel.cgain,
    iKcoeff             => iKcoeff,
    oEdgeValid          => edgeValid,
    oRgb                => fRgb1);
    fRgb.cgainToHsl     <= fRgb1.hsl;
    fRgb.cgainToHsv     <= fRgb1.hsv;
    fRgb.cgainToYcbcr   <= fRgb1.ycbcr;
    fRgb.cgainToShp     <= fRgb1.sharp;
    fRgb.cgainToBlu     <= fRgb1.blur;
    fRgb.cgainToCgain   <= fRgb1.cgain;
end generate CGA_TO_FILTRS1_FRAME_ENABLE;
SHP_TO_FILTRS2_FRAME_ENABLE: if (F_SHP_TO_HSV = true) or (F_SHP_TO_HSL = true) or (F_SHP_TO_YCC = true)  or (F_SHP_TO_SHP = true) or (F_SHP_TO_BLU = true) or (F_SHP_TO_CGA = true) generate
signal fRgb2             : colors;
begin
ImageKernelInst: Kernel
generic map(
    INRGB_FRAME         => false,
    SHARP_FRAME         => F_SHP_TO_SHP,
    BLURE_FRAME         => F_SHP_TO_BLU,
    EMBOS_FRAME         => false,
    YCBCR_FRAME         => F_SHP_TO_YCC,
    SOBEL_FRAME         => false,
    CGAIN_FRAME         => F_SHP_TO_CGA,
    HSV_FRAME           => F_SHP_TO_HSV,
    HSL_FRAME           => F_SHP_TO_HSL,
    img_width           => img_width,
    img_height          => img_height,
    i_data_width        => i_data_width)
port map(
    clk                 => clk,
    rst_l               => rst_l,
    txCord              => txCord,
    iRgb                => rgbImageKernel.sharp,
    iKcoeff             => iKcoeff,
    oEdgeValid          => edgeValid,
    oRgb                => fRgb2);
    fRgb.shpToHsl       <= fRgb2.hsl;
    fRgb.shpToHsv       <= fRgb2.hsv;
    fRgb.shpToYcbcr     <= fRgb2.ycbcr;
    fRgb.shpToShp       <= fRgb2.sharp;
    fRgb.shpToBlu       <= fRgb2.blur;
    fRgb.shpToCgain     <= fRgb2.cgain;
end generate SHP_TO_FILTRS2_FRAME_ENABLE;
BLU_TO_FILTRS3_FRAME_ENABLE: if (F_BLU_TO_HSV = true) or (F_BLU_TO_HSL = true) or (F_BLU_TO_YCC = true)  or (F_BLU_TO_SHP = true) or (F_BLU_TO_BLU = true) or (F_BLU_TO_CGA = true) generate
signal fRgb3             : colors;
begin
ImageKernelInst: Kernel
generic map(
    INRGB_FRAME         => false,
    SHARP_FRAME         => F_BLU_TO_SHP,
    BLURE_FRAME         => F_BLU_TO_BLU,
    EMBOS_FRAME         => false,
    YCBCR_FRAME         => F_BLU_TO_YCC,
    SOBEL_FRAME         => false,
    CGAIN_FRAME         => F_BLU_TO_CGA,
    HSV_FRAME           => F_BLU_TO_HSV,
    HSL_FRAME           => F_BLU_TO_HSL,
    img_width           => img_width,
    img_height          => img_height,
    i_data_width        => i_data_width)
port map(
    clk                 => clk,
    rst_l               => rst_l,
    txCord              => txCord,
    iRgb                => rgbImageKernel.sharp,
    iKcoeff             => iKcoeff,
    oEdgeValid          => edgeValid,
    oRgb                => fRgb3);
    fRgb.bluToHsl       <= fRgb3.hsl;
    fRgb.bluToHsv       <= fRgb3.hsv;
    fRgb.bluToYcc       <= fRgb3.ycbcr;
    fRgb.bluToShp       <= fRgb3.sharp;
    fRgb.bluToBlu       <= fRgb3.blur;
    fRgb.bluToCga       <= fRgb3.cgain;
end generate BLU_TO_FILTRS3_FRAME_ENABLE;
TEST_FRAME_ENABLE: if (F_TES = true) generate
    signal ChannelSelect      : integer := 0;
    signal rgbSum             : tpRgb;
begin
frameTestPatternInst: frameTestPattern
generic map(
    s_data_width        => s_data_width)
port map(   
    clk                 => clk,
    iValid              => iRgb.valid,
    iCord               => txCord,
    oRgb                => rgbSum);
process (clk) begin
    if rising_edge(clk) then
        if(ChannelSelect = 0)then
            fRgb.tPattern.valid     <= rgbSum.valid;
            fRgb.tPattern.red       <= rgbSum.red(7 downto 0);
            fRgb.tPattern.green     <= rgbSum.green(7 downto 0);
            fRgb.tPattern.blue      <= rgbSum.blue(7 downto 0);
        elsif(ChannelSelect = 1)then
            fRgb.tPattern.valid     <= rgbSum.valid;
            fRgb.tPattern.red       <= x"0" & rgbSum.red(3 downto 0);
            fRgb.tPattern.green     <= x"0" & rgbSum.green(7 downto 4);
            fRgb.tPattern.blue      <= x"0" & rgbSum.blue(11 downto 8);
        elsif(ChannelSelect = 2)then
            fRgb.tPattern.valid     <= rgbSum.valid;
            fRgb.tPattern.red       <= rgbSum.red(7 downto 0);
            fRgb.tPattern.green     <= x"0" & rgbSum.green(7 downto 4);
            fRgb.tPattern.blue      <= x"0" & rgbSum.blue(11 downto 8);
        elsif(ChannelSelect = 3)then
            fRgb.tPattern.valid     <= rgbSum.valid;
            fRgb.tPattern.red       <= x"0" & rgbSum.red(3 downto 0);
            fRgb.tPattern.green     <= rgbSum.green(7 downto 0);
            fRgb.tPattern.blue      <= x"0" & rgbSum.blue(11 downto 8);
        else
            fRgb.tPattern.valid     <= rgbSum.valid;
            fRgb.tPattern.red       <= x"0" & rgbSum.red(3 downto 0);
            fRgb.tPattern.green     <= x"0" & rgbSum.green(7 downto 4);
            fRgb.tPattern.blue      <= rgbSum.blue(7 downto 0);
        end if;
    end if;
end process;
end generate TEST_FRAME_ENABLE;
INRGB_FRAME_ENABLE: if (F_RGB = true) generate
begin
TextGenInrgbInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "INRGB")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.inrgb,
    oRgb     => fRgb.inrgb);
end generate INRGB_FRAME_ENABLE;
YCBCR_FRAME_ENABLE: if (F_YCC = true) generate
begin
TextGenYcbcrInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "YCBCR")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.ycbcr,
    oRgb     => fRgb.ycbcr);
end generate YCBCR_FRAME_ENABLE;
SHARP_FRAME_ENABLE: if (F_SHP = true) generate
begin
TextGenSharpInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "SHARP")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.sharp,
    oRgb     => fRgb.sharp);
end generate SHARP_FRAME_ENABLE;
BLURE_FRAME_ENABLE: if (F_BLU = true) generate
begin
TextGenBlurInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "BLUR")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.blur,
    oRgb     => fRgb.blur);
end generate BLURE_FRAME_ENABLE;
EMBOS_FRAME_ENABLE: if (F_EMB = true) generate
begin
TextGenEmbossInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "EMBOSS")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.embos,
    oRgb     => fRgb.embos);
end generate EMBOS_FRAME_ENABLE;
SOBEL_FRAME_ENABLE: if (F_SOB = true) generate
begin
TextGenSobelInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "SOBEL")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.sobel,
    oRgb     => fRgb.sobel);
end generate SOBEL_FRAME_ENABLE;
CGAIN_FRAME_ENABLE: if (F_CGA = true) generate
begin
TextGenCgainInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "CGAIN")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.cgain,
    oRgb     => fRgb.cgain);
end generate CGAIN_FRAME_ENABLE;
HSL_FRAME_ENABLE: if (F_HSL = true) generate
begin
TextGenHslInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "HSL")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.hsl,
    oRgb     => fRgb.hsl);
end generate HSL_FRAME_ENABLE;
HSV_FRAME_ENABLE: if (F_HSV = true) generate
begin
TextGenHsvInst: TextGen
generic map (
    img_width     => img_width,
    img_height    => img_height,
    displayText   => "HSV")
port map(            
    clk      => clk,
    rst_l    => rst_l,
    txCord   => txCord,
    location => location,
    iRgb     => rgbImageKernel.hsv,
    oRgb     => fRgb.hsv);
end generate HSV_FRAME_ENABLE;
INRGB_FRAME_DISABLED: if (F_RGB = false) generate
    fRgb.inrgb     <= init_channel;
end generate INRGB_FRAME_DISABLED;
YCBCR_FRAME_DISABLED: if (F_YCC = false) generate
    fRgb.ycbcr     <= init_channel;
end generate YCBCR_FRAME_DISABLED;
SHARP_FRAME_DISABLED: if (F_SHP = false) generate
    fRgb.sharp     <= init_channel;
end generate SHARP_FRAME_DISABLED;
BLURE_FRAME_DISABLED: if (F_BLU = false) generate
    fRgb.blur     <= init_channel;
end generate BLURE_FRAME_DISABLED;
EMBOS_FRAME_DISABLED: if (F_EMB = false) generate
    fRgb.embos     <= init_channel;
end generate EMBOS_FRAME_DISABLED;
SOBEL_FRAME_DISABLED: if (F_SOB = false) generate
    fRgb.sobel     <= init_channel;
end generate SOBEL_FRAME_DISABLED;
CGAIN_FRAME_DISABLED: if (F_CGA = false) generate
    fRgb.cgain     <= init_channel;
end generate CGAIN_FRAME_DISABLED;
HSL_FRAME_DISABLED: if (F_HSL = false) generate
    fRgb.hsl     <= init_channel;
end generate HSL_FRAME_DISABLED;
HSV_FRAME_DISABLED: if (F_HSV = false) generate
    fRgb.hsv     <= init_channel;
end generate HSV_FRAME_DISABLED;
end Behavioral;