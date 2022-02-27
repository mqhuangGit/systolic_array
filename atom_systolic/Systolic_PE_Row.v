`include "CNN_defines.vh"

module Systolic_PE_Row
(
    input clk,
    input rst_n,
    input [`MAX_DW_Ratio-1:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit
    
    input [`Tout*`MAX_WT_DW-1:0]wt,
    
    input wout_loop_start,   //new weight should be loaded
    input wout_loop_end,
    
    input input_vld,
    input [`MAX_DAT_DW-1:0]left_dat_in,
    input [`Tout*(`base_log2Tin+`MAX_DW2)-1:0]up_dat_in,
    
    output reg [`Tout*(`base_log2Tin+`MAX_DW2)-1:0]down_dat_out

);
reg [`log2Tout-1:0] wout_loop_cnt;
always@(posedge clk or negedge rst_n)
if(~rst_n)
    wout_loop_cnt<='d0;
else
    if(input_vld)
    begin
        if(wout_loop_end)
            wout_loop_cnt<=0;
        else
            wout_loop_cnt<=wout_loop_cnt+1'b1;
    end

reg [(`base_log2Tin+`MAX_DW2)-1:0] tp_up_dat_in[`Tout-1:0];
wire [`MAX_DAT_DW-1:0]tp_right_data_out[`Tout-1:0];
wire [(`base_log2Tin+`MAX_DW2)-1:0] tp_down_dat_out[`Tout-1:0];

generate
begin
	genvar i;
	for(i=0;i<`Tout;i=i+1)
	begin
	always@(*)
        tp_up_dat_in[i]<=up_dat_in[i*(`base_log2Tin+`MAX_DW2)+:(`base_log2Tin+`MAX_DW2)];
	end
end
endgenerate


wire [`MAX_WT_DW-1:0]wt_to_PE[`Tout-1:1];
generate
begin
    genvar i;
    for(i=1;i<`Tout;i=i+1)
    begin
         generate_shift_reg #
        (
            .DATA_WIDTH(`MAX_WT_DW),
            .DEPTH(i)
        )wt_shift_reg
        (
            .clk(clk),
            .rst_n(rst_n),
            .data_in(wt[i*`MAX_WT_DW+:`MAX_WT_DW]),
            .data_out(wt_to_PE[i])
        );
    end
end
endgenerate

Atom_Systolic_PE PE_col0
(
    .clk(clk),
    .rst_n(rst_n),
    .Tin_factor(Tin_factor),
    
    .wt(wt[`MAX_WT_DW-1:0]),
    
    .left_dat_in(left_dat_in),
    .up_dat_in(tp_up_dat_in[0]),

    .right_dat_out(tp_right_data_out[0]),
    .down_dat_out(tp_down_dat_out[0])
);

generate
begin
	genvar i;
	for(i=1;i<`Tout;i=i+1)
	begin:PE_col
        Atom_Systolic_PE systolic_PE
        (
            .clk(clk),
            .rst_n(rst_n),
            .Tin_factor(Tin_factor),
                   
            .wt(wt_to_PE[i]),
            .left_dat_in(tp_right_data_out[i-1]),
            .up_dat_in(tp_up_dat_in[i]),

            .right_dat_out(tp_right_data_out[i]),
            .down_dat_out(tp_down_dat_out[i])
        );
	end
end
endgenerate

generate
begin
	genvar i;
	for(i=0;i<`Tout;i=i+1)
	begin
	always@(*)
        down_dat_out[i*(`base_log2Tin+`MAX_DW2)+:(`base_log2Tin+`MAX_DW2)]<=tp_down_dat_out[i];
	end
end
endgenerate


endmodule
