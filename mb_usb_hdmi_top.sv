//-------------------------------------------------------------------------
//    mb_usb_hdmi_top.sv                                                 --
//    Zuofu Cheng                                                        --
//    2-29-24                                                            --
//                                                                       --
//                                                                       --
//    Spring 2024 Distribution                                           --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;
    
    logic [7:0] LR, UD, buttons, TC;
    
    logic [9:0] ballX, ballY, player1X, player1Y;
    logic dir, shoot, shotFinished;
    logic [1:0] madeShot;
    
    assign reset_ah = reset_rtl_0;
    
    assign LR = keycode0_gpio[7:0];
    assign UD = keycode0_gpio[15:8];
    assign buttons = keycode0_gpio[23:16];
    assign TC = keycode0_gpio[31:24];
    
    logic [4:0] timer;
    logic [6:0] score_;
    
    mb_block mb_block_i (
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .gpio_ballX_tri_o(ballX),
        .gpio_ballY_tri_o(ballY),
        .gpio_madeShot_tri_o(madeShot),
        .gpio_shotFinished_tri_o(shotFinished),
        .gpio_dir_tri_i(dir),
        .gpio_playerX_tri_i(player1X),
        .gpio_playerY_tri_i(player1Y),
        .gpio_shoot_tri_i(shoot),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );
    //Keycode HEX drivers
//    hex_driver HexA (
//        .clk(Clk),
//        .reset(reset_ah),
//        .in({keycode0_gpio[31:28], keycode0_gpio[27:24], keycode0_gpio[23:20], keycode0_gpio[19:16]}),
//        .hex_seg(hex_segA),
//        .hex_grid(hex_gridA)
//    );
    
    hex_driver HexB (
        .clk(Clk),
        .reset(reset_ah),
        .in({timer[4], timer[3:0], ballY[3:0], keycode0_gpio[3:0]}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );

    hex_driver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({score_[6:4], score_[3:0], ballX[3:0], keycode0_gpio[19:16]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    
    //Ball Module
//    ball ball_instance(
//        .Reset(reset_ah),
//        .frame_clk(),                    //Figure out what this should be so that the ball will move
//        .keycode(keycode0_gpio[7:0]),    //Notice: only one keycode connected to ball by default
//        .BallX(ballxsig),
//        .BallY(ballysig),
//        .BallS(ballsizesig)
//    );
    
    //Color Mapper Module   
    color_picker picker(
        .vga_clk(clk_25MHz),
        .DrawX(drawX),
        .DrawY(drawY),
        .blank(vde),
        .LR(LR),
        .UD(UD),
        .buttons(buttons),
        .TC(TC),
        .ballX(ballX),
        .ballY(ballY),
        .madeShot(madeShot),
        .shotFinished(shotFinished),
        .Reset(reset_ah),
        .frame_clk(vsync),
        .player1_dir(dir),
        .player1X(player1X),
        .player1Y(player1Y),
        .shoot(shoot),
        .timer(timer),
        .score_(score_),
        .red(red),
        .green(green),
        .blue(blue)
    );
    
endmodule