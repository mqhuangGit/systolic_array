`include "CNN_defines.vh"

module Column_Systolic_MAC_Control
(
    input clk,
    input rst_n,
    input [`MAX_DW_Ratio-1:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit
    
    //data from BUF
    input dat_vld,
    input [`base_Tin*`MAX_DAT_DW-1:0]dat,
    input Wout_loop_start,
    input Wout_loop_end,
    
    //wt from BUF
    input wt_vld,
    input [`base_Tin*`MAX_WT_DW-1:0]wt,
    input [`log2Tout-1:0]wt_sel,
    
    //dat to ACC
    output [`Tout*(`MAX_DW2+`base_log2Tin)-1:0]dat_o
);

//////// start feature /////////////
reg [`base_Tin*`MAX_DAT_DW-1:0]dat_to_mac;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    dat_to_mac<='d0;
else
    if(dat_vld)
        dat_to_mac<=dat;

reg dat_to_mac_vld;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    dat_to_mac_vld<=1'b0;
else
    dat_to_mac_vld<=dat_vld;


//////// start wt ///////////////
wire wt_load_new=wt_vld&(wt_sel==0);
reg [1:0]wt_load_cnt;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    wt_load_cnt<=2'd0;
else
    case({wt_load_new,Wout_loop_start})
        2'b01:wt_load_cnt<=wt_load_cnt-2'd1;
        2'b10:wt_load_cnt<=wt_load_cnt+2'd1;
    endcase

wire wt_load_reg2=(wt_load_cnt==2'd1)&(wt_load_new|Wout_loop_start);
reg [`base_Tin*`MAX_WT_DW-1:0]wt_reg1[`Tout-1:0];
reg [`base_Tin*`MAX_WT_DW-1:0]wt_reg2[`Tout-1:0];
genvar i;
generate
begin
    for(i=0;i<`Tout;i=i+1)
    begin
        always @(posedge clk or negedge rst_n)
        if(~rst_n)
            wt_reg1[i]<='d0;
        else
            if(wt_vld&(wt_sel==i))
                wt_reg1[i]<=wt;

        always @(posedge clk or negedge rst_n)
        if(~rst_n)
            wt_reg2[i]<='d0;
        else
            if(wt_load_reg2)
                wt_reg2[i]<=wt_reg1[i];
    end
end
endgenerate


wire [`base_Tin*`MAX_WT_DW-1:0]wt_to_mac[`Tout-1:1];
generate
begin
    genvar i;
    for(i=1;i<`Tout;i=i+1)
    begin
         generate_shift_reg #
        (
            .DATA_WIDTH(`base_Tin*`MAX_WT_DW),
            .DEPTH(i)
        )wt_shift_reg
        (
            .clk(clk),
            .rst_n(rst_n),
            .data_in(wt_reg2[i]),
            .data_out(wt_to_mac[i])
        );
    end
end
endgenerate


//////// start calculation ////////
wire [`base_Tin*`MAX_DAT_DW-1:0]right_dat_out[`Tout-1:0];
wire [(`base_log2Tin+`MAX_DW2)-1:0]down_dat_out[`Tout-1:0];
Systolic_PE_Column Systolic_PE_Column0
(
    .clk(clk),
    .rst_n(rst_n),
    .Tin_factor(Tin_factor),
        
    .wt(wt_reg2[0]),
    .left_dat_in(dat_to_mac),    
    .right_dat_out(right_dat_out[0]),
    
    .down_dat_out(down_dat_out[0])
);

generate
begin
    genvar i;
    for(i=1;i<`Tout;i=i+1)
        begin
            Systolic_PE_Column Systolic_PE_Column
            (
                .clk(clk),
                .rst_n(rst_n),
                .Tin_factor(Tin_factor),
                    
                .wt(wt_to_mac[i]),
                .left_dat_in(right_dat_out[i-1]),    
                .right_dat_out(right_dat_out[i]),
                
                .down_dat_out(down_dat_out[i])
            );
        end
    end
endgenerate


///start ouptut shift
wire [`Tout*(`base_log2Tin+`MAX_DW2)-1:0]dat_to_cacc;
wire [(`MAX_DW2+`base_log2Tin)-1:0] dat_out_shift[`Tout-1:0];
generate
begin
    genvar i,j;
    for(i=0;i<`Tout;i=i+1)
    begin
        generate_shift_reg #
        (
            .DATA_WIDTH(`MAX_DW2+`base_log2Tin),
            .DEPTH(`Tout-i)
        )dat_out_shift_reg
        (
            .clk(clk),
            .rst_n(rst_n),
            .data_in(down_dat_out[i]),
            .data_out(dat_out_shift[i])
        );
        assign dat_to_cacc[i*(`MAX_DW2+`base_log2Tin)+:(`MAX_DW2+`base_log2Tin)]=dat_out_shift[i];
    end
end
endgenerate

assign dat_o=dat_to_cacc;

endmodule
