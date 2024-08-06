`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/23/2024 03:38:52 PM
// Design Name: 
// Module Name: player1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module player1(
    input logic [7:0] LR,
    input logic [7:0] UD,
    input logic [7:0] buttons,
    input logic Reset,
    input logic frame_clk,
    input logic endGame,
    output logic dir,
    output logic shoot,
    output logic [9:0] playerX,
    output logic [9:0] playerY
    );
    
    logic [9:0] nextX;
    logic [9:0] nextY;
    
    logic signed [9:0] x1 = 511;
    logic signed [9:0] y1 = 265;
    logic signed [9:0] x2 = 576;
    logic signed [9:0] y2 = 346;
    
    logic signed [9:0] vx1;
    logic signed [9:0] vy1;
    logic signed [9:0] vx2;
    logic signed [9:0] vy2;
    
    assign vx1 = (playerX + 20) - x1;
    assign vy1 = (playerY + 56) - y1;
    assign vx2 = x2 - x1;
    assign vy2 = y2 - y1;

    logic signed [19:0] cross_product;
    assign cross_product = vx1*vy2 - vy1*vx2;
    
    logic signed [9:0] x12 = 64;
    logic signed [9:0] y12 = 344;
    logic signed [9:0] x22 = 127;
    logic signed [9:0] y22 = 264;
    
    logic signed [9:0] vx12;
    logic signed [9:0] vy12;
    logic signed [9:0] vx22;
    logic signed [9:0] vy22;
    
    assign vx12 = (playerX) - x12;
    assign vy12 = (playerY + 56) - y12;
    assign vx22 = x22 - x12;
    assign vy22 = y22 - y12;

    logic signed [19:0] cross_product2;
    assign cross_product2 = vx12*vy22 - vy12*vx22;
    
    always_ff @(posedge frame_clk) begin
        if(Reset) begin
            nextX = 373;
            nextY = 300;
            dir = 1;
        end
        //&& (playerY+56) > ((-129/100)*(playerX) + 428)
        else if(endGame == 0) begin
            if(LR == 8'b0 && cross_product2 < 0) begin
                nextX = nextX - 2;
                dir = 0;
            end
            //((playerY+56) > ((33/25)*(playerX+20) - 414))
            else if(LR == 8'hff && cross_product < 0) begin
                nextX = nextX + 2;
                dir = 1;
            end 
            else if(UD == 8'b0 && (playerY + 53) > 255 && cross_product < 0 && cross_product2 < 0) begin
                nextY = nextY - 2;
            end
            else if(UD == 8'hff && (playerY + 56) < 358) begin
                nextY = nextY + 2;
            end
            
            if(buttons == 8'h8)begin
                shoot = 1;
            end
            else begin
                shoot = 0;
            end
         
            playerX = nextX;
            playerY = nextY;
        end
    end
endmodule
