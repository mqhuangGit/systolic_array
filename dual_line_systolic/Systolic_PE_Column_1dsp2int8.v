`include "CNN_defines.vh"


module Systolic_PE_Column_1dsp2int8
(
	input clk,
	input rst_n,
	input [3:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit     
	
	input [2*`base_Tin*`MAX_WT_DW-1:0]wt,
	input [`base_Tin*`MAX_DAT_DW-1:0]left_dat_in,
	output reg [`base_Tin*`MAX_DAT_DW-1:0]right_dat_out,
	output [2*(`base_log2Tin+`MAX_DW2)-1:0]down_dat_out

);

Parallel_MAC_Calculation_1dsp2int8 Parallel_MAC
(
	.clk(clk),
	.rst_n(rst_n),
	.Tin_factor(Tin_factor),
	
	.dat(left_dat_in),
	.wt0(wt[`base_Tin*`MAX_WT_DW-1:0]),
	.wt1(wt[2*`base_Tin*`MAX_WT_DW-1:`base_Tin*`MAX_WT_DW]),
	.dat_o(down_dat_out)
);


always@(posedge clk or negedge rst_n)
if(~rst_n)
    right_dat_out<=0;
else
    right_dat_out<=left_dat_in;
    
endmodule




/////////////////////////////////
module Systolic_PE_Column_0dsp2int8
(
	input clk,
	input rst_n,
	input [3:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit     
	
	input [2*`base_Tin*`MAX_WT_DW-1:0]wt,
	input [`base_Tin*`MAX_DAT_DW-1:0]left_dat_in,
	output reg [`base_Tin*`MAX_DAT_DW-1:0]right_dat_out,
	output [2*(`base_log2Tin+`MAX_DW2)-1:0]down_dat_out

);

Parallel_MAC_Calculation_0dsp2int8 Parallel_MAC
(
	.clk(clk),
	.rst_n(rst_n),
	.Tin_factor(Tin_factor),
	
	.dat(left_dat_in),
	.wt0(wt[`base_Tin*`MAX_WT_DW-1:0]),
	.wt1(wt[2*`base_Tin*`MAX_WT_DW-1:`base_Tin*`MAX_WT_DW]),
	.dat_o(down_dat_out)
);


always@(posedge clk or negedge rst_n)
if(~rst_n)
    right_dat_out<=0;
else
    right_dat_out<=left_dat_in;
    
endmodule