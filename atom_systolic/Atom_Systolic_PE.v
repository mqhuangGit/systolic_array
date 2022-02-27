`include "CNN_defines.vh"


module Atom_Systolic_PE
(
    input clk,
    input rst_n,
    input [`MAX_DW_Ratio-1:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit
    
    input [`MAX_WT_DW-1:0]wt,
    input [`MAX_DAT_DW-1:0]left_dat_in,
    input [`base_log2Tin+`MAX_DW2-1:0]up_dat_in,
    
    output reg[`MAX_DAT_DW-1:0]right_dat_out,
    output reg [`base_log2Tin+`MAX_DW2-1:0]down_dat_out

);

always@(posedge clk or negedge rst_n)
if(~rst_n)
    begin
        right_dat_out<='d0;
        down_dat_out<='d0;
    end
else
    begin
        right_dat_out<=left_dat_in;
        down_dat_out<=$signed(wt)*$signed(left_dat_in)+$signed(up_dat_in);
    end

endmodule
