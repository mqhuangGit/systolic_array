`include "CNN_defines.vh"

module Systolic_PE_Column
(
    input clk,
    input rst_n,
    input [`MAX_DW_Ratio-1:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit
    
    input [`base_Tin*`MAX_WT_DW-1:0]wt,
    input [`base_Tin*`MAX_DAT_DW-1:0]left_dat_in,
    output reg [`base_Tin*`MAX_DAT_DW-1:0]right_dat_out,
    output [(`base_log2Tin+`MAX_DW2)-1:0]down_dat_out

);

Parallel_MAC_Calculation Parallel_MAC
(
    .clk(clk),
    .rst_n(rst_n),
    .Tin_factor(Tin_factor),
    
    .dat(left_dat_in),
    .wt(wt),
    .dat_o(down_dat_out)
);

always@(posedge clk or negedge rst_n)
if(~rst_n)
    right_dat_out<=0;
else
    right_dat_out<=left_dat_in;
    
endmodule
