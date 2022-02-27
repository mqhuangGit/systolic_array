`include "CNN_defines.vh"

module Column_Systolic_MAC_Control
(
    input clk,
    input rst_n,
    input [3:0]Tin_factor,// 1 meams 8bit, 2 means 4bit, 4 means 2bit, 8 means 1bit    
    
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
    for(i=0;i<`Tout;i=i+1)
    begin:wt_reg1_b
        always @(posedge clk or negedge rst_n)
        if(~rst_n)
            wt_reg1[i]<='d0;
        else
            if(wt_vld&(wt_sel==i))
                wt_reg1[i]<=wt;
    end
endgenerate

generate
    for(i=0;i<`Tout;i=i+1)
    begin:wt_reg2_b
        always @(posedge clk or negedge rst_n)
        if(~rst_n)
            wt_reg2[i]<='d0;
        else
            if(wt_load_reg2)
                wt_reg2[i]<=wt_reg1[i];
    end
endgenerate

//reg wt_load_reg2_d1;
//always @(posedge clk or negedge rst_n)
//if(~rst_n)
//    wt_load_reg2_d1<='d0;
//else
//    wt_load_reg2_d1<=wt_load_reg2;

//reg [`log2Tout:0]wt_col_cnt;
//reg wt_col_cnt_working;
//wire wt_col_cnt_done=(wt_col_cnt==`Tout);
//always @(posedge clk or negedge rst_n)
//if(~rst_n)
//    wt_col_cnt_working<='d0;
//else
//    if(wt_col_cnt_done)
//        wt_col_cnt_working<='d0;
//    else
//        if(wt_load_reg2_d1)
//            wt_col_cnt_working<='b1;


//always @(posedge clk or negedge rst_n)
//if(~rst_n)
//    wt_col_cnt<='d0;
//else
//    if(wt_col_cnt_done)
//        wt_col_cnt<='d0;
//    else
//        if(wt_col_cnt_working)
//            wt_col_cnt<=wt_col_cnt+1;



`ifdef dsp_for_two_int8
    reg [2*`base_Tin*`MAX_WT_DW-1:0]wt_to_mac[`Tout/2-1:1];
    wire [`Tout/2-1:1]wt_to_mac_vld;
    
    generate
        for(i=1;i<`Tout/2;i=i+1)
        begin:shift_reg_vld_b
             generate_shift_reg #
            (
                .DATA_WIDTH(1),
                .DEPTH(i)
            )wt_shift_reg
            (
                .clk(clk),
                .rst_n(rst_n),
                .data_in(wt_load_reg2),
                .data_out(wt_to_mac_vld[i])
            );
        end
    endgenerate
    
    generate
        for(i=1;i<`Tout/2;i=i+1)
        begin:wt_to_mac_b
            always @(posedge clk or negedge rst_n)
            if(~rst_n)
                wt_to_mac[i]<='d0;
            else
                if(wt_to_mac_vld[i])
                    wt_to_mac[i]<={wt_reg2[2*i+1],wt_reg2[2*i]};
        end
    endgenerate
    
    
    //////// start calculation ////////
    wire [`base_Tin*`MAX_DAT_DW-1:0]right_dat_out[`Tout/2-1:0];
    wire [2*(`base_log2Tin+`MAX_DW2)-1:0]down_dat_out[`Tout/2-1:0];
    Systolic_PE_Column_0dsp2int8 Systolic_PE_Column0
    (
        .clk(clk),
        .rst_n(rst_n),
        .Tin_factor(Tin_factor),
            
        .wt({wt_reg2[1],wt_reg2[0]}),
        .left_dat_in(dat_to_mac),    
        .right_dat_out(right_dat_out[0]),
        
        .down_dat_out(down_dat_out[0])
    );

    Systolic_PE_Column_0dsp2int8 Systolic_PE_Column1
    (
        .clk(clk),
        .rst_n(rst_n),
        .Tin_factor(Tin_factor),
            
        .wt(wt_to_mac[1]),
        .left_dat_in(right_dat_out[0]),    
        .right_dat_out(right_dat_out[1]),
        
        .down_dat_out(down_dat_out[1])
    );
        
    generate
        for(i=2;i<`Tout/2;i=i+1)
        begin:col_pe
            Systolic_PE_Column_1dsp2int8 Systolic_PE_Column
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
    
    endgenerate
    
    
    ///start ouptut shift
    wire [`Tout*(`base_log2Tin+`MAX_DW2)-1:0]dat_to_cacc;
    wire [2*(`MAX_DW2+`base_log2Tin)-1:0] dat_out_shift[`Tout/2-1:0];
    
    generate
        for(i=0;i<`Tout/2;i=i+1)
        begin:shift_reg_b
            generate_shift_reg #
            (
                .DATA_WIDTH(2*(`MAX_DW2+`base_log2Tin)),
                .DEPTH(`Tout/2-i)
            )dat_out_shift_reg
            (
                .clk(clk),
                .rst_n(rst_n),
                .data_in(down_dat_out[i]),
                .data_out(dat_out_shift[i])
            );
            assign dat_to_cacc[(2*i+2)*(`MAX_DW2+`base_log2Tin)-1:(2*i)*(`MAX_DW2+`base_log2Tin)]=dat_out_shift[i];
        end
    endgenerate

`else

    reg [`base_Tin*`MAX_WT_DW-1:0]wt_to_mac[`Tout-1:1];
    wire [`Tout-1:1]wt_to_mac_vld;
    
    generate
        for(i=1;i<`Tout;i=i+1)
        begin:shift_reg_vld_b
             generate_shift_reg #
            (
                .DATA_WIDTH(1),
                .DEPTH(i)
            )wt_shift_reg
            (
                .clk(clk),
                .rst_n(rst_n),
                .data_in(wt_load_reg2),
                .data_out(wt_to_mac_vld[i])
            );
        end
    endgenerate
    
    generate
        for(i=1;i<`Tout;i=i+1)
        begin:wt_to_mac_b
            always @(posedge clk or negedge rst_n)
            if(~rst_n)
                wt_to_mac[i]<='d0;
            else
                if(wt_to_mac_vld[i])
                    wt_to_mac[i]<=wt_reg2[i];
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
        for(i=1;i<`Tout;i=i+1)
        begin:col_pe
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
    
    endgenerate
    
    ///start ouptut shift
    wire [`Tout*(`base_log2Tin+`MAX_DW2)-1:0]dat_to_cacc;
    wire [(`MAX_DW2+`base_log2Tin)-1:0] dat_out_shift[`Tout-1:0];
    
    generate
        for(i=0;i<`Tout;i=i+1)
        begin:shift_reg_b
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
    endgenerate


`endif
assign dat_o=dat_to_cacc;

endmodule
