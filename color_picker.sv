module color_picker (
	input logic vga_clk,
	input logic [9:0] DrawX, DrawY,
	input logic blank,
	input logic [7:0] LR,
	input logic [7:0] UD,
	input logic [7:0] buttons,
	input logic [7:0] TC,
	input logic [9:0] ballX,
	input logic [9:0] ballY,
	input logic [1:0] madeShot,
	input logic shotFinished,
	input logic Reset,
	input logic frame_clk,
	output logic [9:0] player1X,
	output logic [9:0] player1Y,
	output logic shoot,
	output logic [4:0] timer,
	output logic [6:0] score_,
	output logic player1_dir,
	output logic [3:0] red, green, blue
);


logic [9:0] player1_distX, player1_distY, ball_distX, ball_distY;

logic [17:0] rom_address_court;
logic [3:0] rom_q_court;
logic [3:0] palette_red_court, palette_green_court, palette_blue_court;

logic [10:0] rom_address_player1;
logic [3:0] rom_q_player1L;
logic [3:0] palette_red_player1L, palette_green_player1L, palette_blue_player1L;

logic [3:0] rom_q_player1R;
logic [3:0] palette_red_player1R, palette_green_player1R, palette_blue_player1R;

logic [3:0] rom_q_player1L_B;
logic [3:0] palette_red_player1L_B, palette_green_player1L_B, palette_blue_player1L_B;

logic [3:0] rom_q_player1R_B;
logic [3:0] palette_red_player1R_B, palette_green_player1R_B, palette_blue_player1R_B;

logic [3:0] rom_q_player1L_UP;
logic [3:0] palette_red_player1L_UP, palette_green_player1L_UP, palette_blue_player1L_UP;

logic [3:0] rom_q_player1R_UP;
logic [3:0] palette_red_player1R_UP, palette_green_player1R_UP, palette_blue_player1R_UP;

logic [5:0] rom_address_ball;
logic [3:0] rom_q_ball;
logic [3:0] palette_red_ball, palette_green_ball, palette_blue_ball;

logic [16:0] rom_address_start;
logic [3:0] rom_q_start;
logic [3:0] palette_red_start, palette_green_start, palette_blue_start;

logic negedge_vga_clk;

logic [10:0] score_addr;
logic [3:0] char_index;
logic [7:0] score_data;
//logic [6:0] score_;
logic char_bit;

// read from ROM on negedge, set pixel on posedge
assign negedge_vga_clk = ~vga_clk;

assign player1_distX = DrawX - player1X;
assign player1_distY = DrawY - player1Y;

assign ball_distX = DrawX - ballX;
assign ball_distY = DrawY - ballY;

// address into the rom = (x*xDim)/640 + ((y*yDim)/480) * xDim
// this will stretch out the sprite across the entire screen
assign rom_address_court = ((DrawX * 640) / 640) + (((DrawY * 360) / 360) * 640);
assign rom_address_player1 = (player1_distX + (player1_distY * 20));
assign rom_address_ball = (ball_distX + (ball_distY * 7));
assign rom_address_start = ((DrawX * 320) / 640) + (((DrawY * 240) / 480) * 320);

logic startGame = 0;
logic endGame = 0;
logic [10:0] count = 0;


always_ff @ (posedge vga_clk) begin
	red <= 4'h0;
	green <= 4'h0;
	blue <= 4'h0;
	
	if(blank) begin
	    if(startGame == 0) begin
            red <= palette_red_start;
            green <= palette_green_start;
            blue <= palette_blue_start;
        end
	    if(buttons == 8'h80) begin
	       startGame <= 1;
	    end
        if (startGame) begin
        //&& palette_blue_player1L != 4'hb
            if(score_ >= 95 || timer == 0) begin
	           endGame <= 1;
	           if(buttons == 8'h80) begin
	               startGame <= 0;
	               endGame <= 0;
	              // score_ <= 0;
	           end
	        end
            if(player1_dir == 0) begin
                if(DrawX > player1X && DrawX <= (player1X+20) && DrawY >= player1Y && DrawY < (player1Y+56)) begin
                    if(shoot == 0 && palette_blue_player1L_B != 4'hb) begin
                        red <= palette_red_player1L_B;
                        green <= palette_green_player1L_B;
                        blue <= palette_blue_player1L_B;
                    end
                    else if(shoot == 1 && palette_blue_player1L_UP != 4'hb) begin
                        red <= palette_red_player1L_UP;
                        green <= palette_green_player1L_UP;
                        blue <= palette_blue_player1L_UP;
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else if(DrawX > ballX && DrawX <= (ballX+7) && DrawY >= ballY && DrawY < (ballY+7) 
                && palette_blue_ball != 4'hb) begin
                    red <= palette_red_ball;
                    green <= palette_green_ball;
                    blue <= palette_blue_ball;
                end
                else if(DrawX >= 284 && DrawX < 356 && DrawY >= 10 && DrawY < 26) begin
                    if(char_bit == 1'b1) begin
                       red <= 255;
                       green <= 255;
                       blue <= 255; 
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else if(DrawX >= 284 && DrawX < 356 && DrawY >= 28 && DrawY < 44) begin
                    if(char_bit == 1'b1) begin
                       red <= 255;
                       green <= 255;
                       blue <= 255; 
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else if(endGame && DrawX >= 284 && DrawX < 356 && DrawY >= 54 && DrawY < 70) begin
                    if(char_bit == 1'b1) begin
                       red <= 255;
                       green <= 255;
                       blue <= 255; 
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else begin
                    red <= palette_red_court;
                    green <= palette_green_court;
                    blue <= palette_blue_court;
                end
            end
            else if(player1_dir == 1) begin
                if(DrawX > player1X && DrawX <= (player1X+20) && DrawY >= player1Y && DrawY < (player1Y+56)) begin
                    if(shoot == 0 && palette_blue_player1R_B != 4'hb) begin
                        red <= palette_red_player1R_B;
                        green <= palette_green_player1R_B;
                        blue <= palette_blue_player1R_B;
                    end
                    else if(shoot == 1 && palette_blue_player1R_UP != 4'hb) begin
                        red <= palette_red_player1R_UP;
                        green <= palette_green_player1R_UP;
                        blue <= palette_blue_player1R_UP;
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else if(DrawX > ballX && DrawX <= (ballX+7) && DrawY >= ballY && DrawY < (ballY+7) 
                && palette_blue_ball != 4'hb) begin
                    red <= palette_red_ball;
                    green <= palette_green_ball;
                    blue <= palette_blue_ball;
                end
                else if(DrawX >= 284 && DrawX < 356 && DrawY >= 10 && DrawY < 26) begin                   
                    if(char_bit == 1'b1) begin
                       red <= 255;
                       green <= 255;
                       blue <= 255; 
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else if(DrawX >= 284 && DrawX < 356 && DrawY >= 28 && DrawY < 44) begin
                    if(char_bit == 1'b1) begin
                       red <= 255;
                       green <= 255;
                       blue <= 255; 
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else if(endGame && DrawX >= 284 && DrawX < 356 && DrawY >= 54 && DrawY < 70) begin
                    if(char_bit == 1'b1) begin
                       red <= 255;
                       green <= 255;
                       blue <= 255; 
                    end
                    else begin
                        red <= palette_red_court;
                        green <= palette_green_court;
                        blue <= palette_blue_court;
                    end
                end
                else begin
                  red <= palette_red_court;
                  green <= palette_green_court;
                  blue <= palette_blue_court;
                end
            end
        end
	end
end

logic [4:0] timer_next = 30;
logic [10:0] count_next = 0;
always_ff @ (posedge frame_clk) begin
    if(startGame && endGame == 0) begin
        if(timer == 0) begin
            count_next = 0;
            timer_next = 30;
        end
        else begin
            count_next = count_next + 1;
            if(count_next % 60 == 0)begin
                timer_next = timer_next - 1;
            end
        end
    end
    timer = timer_next;
    count = count_next;  
end

always_comb begin
        if(DrawX >= 284 && DrawX < 356 && DrawY >= 10 && DrawY < 26) begin
            char_index = ((DrawX - 284)/8) %9;
            if(char_index == 0) begin
                score_addr = (DrawY-10) + 16*(8'h53);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 1) begin
                score_addr = (DrawY-10) + 16*(8'h43);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 2) begin
                score_addr = (DrawY-10) + 16*(8'h4F);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 3) begin
                score_addr = (DrawY-10) + 16*(8'h52);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 4) begin
                score_addr = (DrawY-10) + 16*(8'h45);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 5) begin
                score_addr = (DrawY-10) + 16*(8'h3a);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 6) begin
                score_addr = (DrawY-10) + 16*(8'h00);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 7) begin
                score_addr = (DrawY-10) + 16*((score_/10) + 48);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 8) begin
                score_addr = (DrawY-10) + 16*((score_%10) + 48);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
        end
        else if(DrawX >= 284 && DrawX < 356 && DrawY >= 28 && DrawY < 44) begin
            char_index = ((DrawX - 284)/8) %9;
            if(char_index == 0) begin
                score_addr = (DrawY-28) + 16*(8'h54);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 1) begin
                score_addr = (DrawY-28) + 16*(8'h49);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 2) begin
                score_addr = (DrawY-28) + 16*(8'h4D);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 3) begin
                score_addr = (DrawY-28) + 16*(8'h45);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 4) begin
                score_addr = (DrawY-28) + 16*(8'h52);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 5) begin
                score_addr = (DrawY-28) + 16*(8'h3a);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 6) begin
                score_addr = (DrawY-28) + 16*(8'h00);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 7) begin
                score_addr = (DrawY-28) + 16*((timer/10) + 48);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 8) begin
                score_addr = (DrawY-28) + 16*((timer%10) + 48);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
        end
        else if(endGame && DrawX >= 284 && DrawX < 356 && DrawY >= 54 && DrawY < 70) begin
            char_index = ((DrawX - 284)/8) %9;
            if(char_index == 0) begin
                score_addr = (DrawY-54) + 16*(8'h47);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 1) begin
                score_addr = (DrawY-54) + 16*(8'h41);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 2) begin
                score_addr = (DrawY-54) + 16*(8'h4D);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 3) begin
                score_addr = (DrawY-54) + 16*(8'h45);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 4) begin
                score_addr = (DrawY-54) + 16*(8'h00);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 5) begin
                score_addr = (DrawY-54) + 16*(8'h4f);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 6) begin
                score_addr = (DrawY-54) + 16*(8'h56);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 7) begin
                score_addr = (DrawY-54) + 16*(8'h45);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
            else if(char_index == 8) begin
                score_addr = (DrawY-54) + 16*(8'h52);
                char_bit = score_data[7 - ((DrawX - 284)%8)];
            end
        end
end

court_rom court_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_court),
	.douta       (rom_q_court)
);

court_palette court_palette (
	.index (rom_q_court),
	.red   (palette_red_court),
	.green (palette_green_court),
	.blue  (palette_blue_court)
);

Player1_L_rom Player1_L_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_player1),
	.douta       (rom_q_player1L)
);

Player1_L_palette Player1_L_palette (
	.index (rom_q_player1L),
	.red   (palette_red_player1L),
	.green (palette_green_player1L),
	.blue  (palette_blue_player1L)
);

Player1_R_rom Player1_R_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_player1),
	.douta       (rom_q_player1R)
);

Player1_R_palette Player1_R_palette (
	.index (rom_q_player1R),
	.red   (palette_red_player1R),
	.green (palette_green_player1R),
	.blue  (palette_blue_player1R)
);

Player1_L_B_rom Player1_L_B_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_player1),
	.douta       (rom_q_player1L_B)
);

Player1_L_B_palette Player1_L_B_palette (
	.index (rom_q_player1L_B),
	.red   (palette_red_player1L_B),
	.green (palette_green_player1L_B),
	.blue  (palette_blue_player1L_B)
);

Player1_R_B_rom Player1_R_B_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_player1),
	.douta       (rom_q_player1R_B)
);

Player1_R_B_palette Player1_R_B_palette (
	.index (rom_q_player1R_B),
	.red   (palette_red_player1R_B),
	.green (palette_green_player1R_B),
	.blue  (palette_blue_player1R_B)
);

Player1_L_UP_rom Player1_L_UP_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_player1),
	.douta       (rom_q_player1L_UP)
);

Player1_L_UP_palette Player1_L_UP_palette (
	.index (rom_q_player1L_UP),
	.red   (palette_red_player1L_UP),
	.green (palette_green_player1L_UP),
	.blue  (palette_blue_player1L_UP)
);

Player1_R_UP_rom Player1_R_UP_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_player1),
	.douta       (rom_q_player1R_UP)
);

Player1_R_UP_palette Player1_R_UP_palette (
	.index (rom_q_player1R_UP),
	.red   (palette_red_player1R_UP),
	.green (palette_green_player1R_UP),
	.blue  (palette_blue_player1R_UP)
);

ball_rom ball_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_ball),
	.douta       (rom_q_ball)
);

ball_palette ball_palette (
	.index (rom_q_ball),
	.red   (palette_red_ball),
	.green (palette_green_ball),
	.blue  (palette_blue_ball)
);

StartScreen_rom StartScreen_rom (
	.clka   (negedge_vga_clk),
	.addra (rom_address_start),
	.douta       (rom_q_start)
);

StartScreen_palette StartScreen_palette (
	.index (rom_q_start),
	.red   (palette_red_start),
	.green (palette_green_start),
	.blue  (palette_blue_start)
);

player1 player1 (
    .LR(LR),
    .UD(UD),
    .buttons(buttons),
    .playerX(player1X),
    .playerY(player1Y),
    .endGame(endGame),
    .dir(player1_dir),
    .shoot(shoot),
    .Reset(Reset),
    .frame_clk(frame_clk)
);

font_rom font_rom (
    .addr(score_addr),
    .data(score_data)
);

score score (
    .madeShot(madeShot),
    .reset(Reset),
    .ballX(ballX),
    .ballY(ballY),
    .shotFinished(shotFinished),
    .endGame(endGame),
    .score_(score_),
    .frame_clk(frame_clk)
);

endmodule
