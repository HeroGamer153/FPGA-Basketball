`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 05/01/2024 01:50:04 PM
// Design Name: 
// Module Name: score
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


module score(
    input logic [1:0] madeShot,
    input logic reset,
    input logic [9:0] ballX,
    input logic [9:0] ballY,
    input logic shotFinished,
    input logic endGame,
    output logic [6:0] score_,
    input logic frame_clk
    );
    
    logic [6:0] nextScore;
    logic flag;
    
    always_ff @(posedge frame_clk) begin
        if(reset) begin
            nextScore = 0;
            flag = 0;
        end
        if(madeShot == 2'b10) begin
            if(shotFinished && flag == 0) begin
                nextScore = nextScore + 2;
                flag = 1;
            end
            else if (shotFinished == 0 && flag == 1) begin
                flag = 0;
             end
        end
        else if(madeShot == 2'b11) begin
            if(shotFinished && flag == 0) begin
                nextScore = nextScore + 3;
                flag = 1;
            end
            else if (shotFinished == 0 && flag == 1) begin
                flag = 0;
             end
        end
        
        if(endGame) begin
            nextScore = 0;
        end

        score_ = nextScore;
    end
    
endmodule
