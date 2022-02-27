`include "CNN_defines.vh"

module Atom_Systolic_MAC_Control
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
reg [`base_Tin*`MAX_DAT_DW-1:0]dat_reg;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    dat_reg<='d0;
else
    if(dat_vld)
        dat_reg<=dat;

reg dat_vld_d;
always @(posedge clk or negedge rst_n)
if(~rst_n)
    dat_vld_d<=1'b0;
else
    dat_vld_d<=dat_vld;

    
wire [`MAX_DAT_DW-1:0] dat_to_mac[`base_Tin-1:0];
reg [`base_Tin:0]dat_to_mac_vld;
wire [`Tout*(`base_log2Tin+`MAX_DW2)-1:0]down_dat_out[`base_Tin-1:0];
wire [`Tout*(`base_log2Tin+`MAX_DW2)-1:0]dat_to_cacc;
    
generate
begin
    genvar i,j;
    for(i=0;i<`base_Tin;i=i+1)
    begin
        generate_shift_reg #
        (
            .DATA_WIDTH(`MAX_DAT_DW),
            .DEPTH(i+1)
        )dat_shift_reg
        (
            .clk(clk),
            .rst_n(rst_n),
            .data_in(dat_reg[`MAX_DAT_DW*i+:`MAX_DAT_DW]),
            .data_out(dat_to_mac[i])
        );
    end
end
endgenerate


generate
begin
    genvar i;
    for(i=0;i<`base_Tin;i=i+1)
    begin
        always@(posedge clk or negedge rst_n)
        if(!rst_n)
            dat_to_mac_vld<='d0;
        else
            dat_to_mac_vld<={dat_to_mac_vld[i:0],dat_vld_d};
    end
end
endgenerate


//////// start wt ///////////////
wire wt_load_reg2;
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

assign wt_load_reg2=(wt_load_cnt==2'd1)&(wt_load_new|Wout_loop_start);

wire [`base_Tin*`Tout*`MAX_WT_DW-1:0]tp_wt_reg3;
wire [`Tout*`MAX_WT_DW-1:0]wt_reg3[`base_Tin-1:0];

genvar i;
generate
begin
    for(i=0;i<`Tout;i=i+1)
    begin
        reg [`base_Tin*`MAX_WT_DW-1:0]wt_reg1;
        reg [`base_Tin*`MAX_WT_DW-1:0]wt_reg2;
        always @(posedge clk or negedge rst_n)
        if(~rst_n)
            wt_reg1<='d0;
        else
            if(wt_vld&(wt_sel==i))
                wt_reg1<=wt;

        always @(posedge clk or negedge rst_n)
        if(~rst_n)
            wt_reg2<='d0;
        else
            if(wt_load_reg2)
                wt_reg2<=wt_reg1;

        assign  tp_wt_reg3[`base_Tin*`MAX_WT_DW*i+:`base_Tin*`MAX_WT_DW]=wt_reg2;

    end
end
endgenerate

generate
begin
    genvar i,j;
    for(i=0;i<`base_Tin;i=i+1)
    begin
        for(j=0;j<`Tout;j=j+1)
        begin
            assign wt_reg3[i][j*`MAX_WT_DW+`MAX_WT_DW-1:j*`MAX_WT_DW]=tp_wt_reg3[j*(`base_Tin*`MAX_WT_DW)+i*`MAX_WT_DW+`MAX_WT_DW-1:j*(`base_Tin*`MAX_WT_DW)+i*`MAX_WT_DW];
        end
    end
end
endgenerate


wire [`Tout*`MAX_WT_DW-1:0]wt_to_mac[`base_Tin-1:0];
generate
begin
    genvar i;
    for(i=0;i<`base_Tin;i=i+1)
    begin
         generate_shift_reg #
        (
            .DATA_WIDTH(`Tout*`MAX_DAT_DW),
            .DEPTH(i+1)
        )wt_shift_reg
        (
            .clk(clk),
            .rst_n(rst_n),
            .data_in(wt_reg3[i]),
            .data_out(wt_to_mac[i])
        );
    end
end
endgenerate

reg Wout_loop_start_d1;
reg Wout_loop_end_d1;
always@(posedge clk or negedge rst_n)
if(~rst_n)
begin
    Wout_loop_start_d1<='d0;
    Wout_loop_end_d1<='d0;
end
else
begin
    Wout_loop_start_d1<=Wout_loop_start;
    Wout_loop_end_d1<=Wout_loop_end;
end

reg [`base_Tin-1:0]Wout_loop_end_in_mac;
reg [`base_Tin-1:0]Wout_loop_start_in_mac;
generate
begin
    genvar i,j;
    for(i=0;i<`base_Tin;i=i+1)
    begin
        always@(posedge clk or negedge rst_n)
        if(!rst_n) begin
            Wout_loop_end_in_mac<=0;
            Wout_loop_start_in_mac<=0;
        end
        else begin
            Wout_loop_end_in_mac<={Wout_loop_end_in_mac[i:0],Wout_loop_end_d1};
            Wout_loop_start_in_mac<={Wout_loop_start_in_mac[i:0],Wout_loop_start_d1};
        end
    end
end
endgenerate
 
Systolic_PE_Row Systolic_PE_Row0
(
    .clk(clk),
    .rst_n(rst_n),
    .wt(wt_to_mac[0]),
    .Tin_factor(Tin_factor),
    
    .wout_loop_start(Wout_loop_start_in_mac[0]),
    .wout_loop_end(Wout_loop_end_in_mac[0]),
    
    .input_vld(dat_to_mac_vld[0]),
    .left_dat_in(dat_to_mac[0]),
    .up_dat_in({(`Tout*(`base_log2Tin+`MAX_DW2)){1'b0}}),
    
    .down_dat_out(down_dat_out[0])
);

generate
begin
    genvar i;
    for(i=1;i<`base_Tin;i=i+1)
        begin
            Systolic_PE_Row Systolic_PE_Row
            (
                .clk(clk),
                .rst_n(rst_n),
                .wt(wt_to_mac[i]),
                .Tin_factor(Tin_factor),
                
                .wout_loop_start(Wout_loop_start_in_mac[i]),
                .wout_loop_end(Wout_loop_end_in_mac[i]),
                
                .input_vld(dat_to_mac_vld[i]),
                .left_dat_in(dat_to_mac[i]),
                .up_dat_in(down_dat_out[i-1]),
                
                .down_dat_out(down_dat_out[i])
            );
        end
    end
endgenerate

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
            .data_in(down_dat_out[`base_Tin-1][i*(`base_log2Tin+`MAX_DW2)+:(`base_log2Tin+`MAX_DW2)]),
            .data_out(dat_out_shift[i])
        );
        assign dat_to_cacc[i*(`MAX_DW2+`base_log2Tin)+:(`MAX_DW2+`base_log2Tin)]=dat_out_shift[i];
    end
end
endgenerate

assign dat_o=dat_to_cacc;

endmodule
