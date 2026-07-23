`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.07.2026 02:58:58
// Design Name: 
// Module Name: tomasulo_tb
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


module tomasulo_tb(

    );
    reg clk,rst;
    wire test;
    tomasulo uut(.clk(clk),.rst(rst),.done(test));
    initial
    begin
    rst<=0;
    clk<=0;
    
    #1 rst<=1;
    #3 rst<=0;
    end
    
    always
    #1 clk=~clk;
    
endmodule
