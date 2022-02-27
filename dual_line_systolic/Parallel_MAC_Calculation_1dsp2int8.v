`include "CNN_defines.vh"


module Parallel_MAC_Calculation_1dsp2int8
(
    input clk,
    input rst_n,
    input [3:0]Tin_factor,// 1 meams 8bit
    input [`base_Tin*`MAX_DAT_DW-1:0]dat,
    input [`base_Tin*`MAX_WT_DW-1:0]wt0,
    input [`base_Tin*`MAX_WT_DW-1:0]wt1,
    output [2*(`MAX_DW2+`base_log2Tin)-1:0]dat_o
);

wire [`MAX_DAT_DW-1 :0] conv_dat[(`base_Tin/8)-1:0][8-1 : 0];
wire [`MAX_WT_DW-1 :0] conv_wt0[(`base_Tin/8)-1:0][8-1 : 0];
wire [`MAX_WT_DW-1 :0] conv_wt1[(`base_Tin/8)-1:0][8-1 : 0];

(* use_dsp = "yes" *)wire signed [`MAX_DW2-1:0] tp_sum  [(`base_Tin/8)-1:0][8-1 : 0][1:0];


reg signed  [`MAX_DW2+1-1 :0] sum_1 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+1-1 :0] sum_2 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+1-1 :0] sum_3 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+1-1 :0] sum_4 [(`base_Tin/8)-1:0][1:0];

reg signed  [`MAX_DW2+2-1 :0] sum_5 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+2-1 :0] sum_6 [(`base_Tin/8)-1:0][1:0];

reg signed  [`MAX_DW2+3-1 :0] sum_7 [(`base_Tin/8)-1:0][1:0];

reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out0[1:0];
reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out1[1:0];
reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out2[1:0];
reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out3[1:0];
reg signed [`MAX_DW2+`base_log2Tin-1-1:0] dat_out4[1:0];
reg signed [`MAX_DW2+`base_log2Tin-1-1:0] dat_out5[1:0];
reg signed [`MAX_DW2+`base_log2Tin-1:0]   dat_out[1:0];


genvar i,j;
generate
    for(i=0;i<(`base_Tin/8);i=i+1)
    begin:Tin_div_8
        for(j=0;j<8;j=j+1)
        begin:group_of_8
            assign conv_dat[i][j] = dat[i*`MAX_DAT_DW*8+j*`MAX_DAT_DW+`MAX_DAT_DW-1 : i*`MAX_DAT_DW*8+j*`MAX_DAT_DW];
            assign conv_wt0[i][j] = wt0[i*`MAX_WT_DW*8+j*`MAX_WT_DW+`MAX_WT_DW-1 : i*`MAX_WT_DW*8+j*`MAX_WT_DW];
            assign conv_wt1[i][j] = wt1[i*`MAX_WT_DW*8+j*`MAX_WT_DW+`MAX_WT_DW-1 : i*`MAX_WT_DW*8+j*`MAX_WT_DW];
            
//            always @(posedge clk)
//            begin
//                tp_sum[i][j][0] <=($signed(conv_dat[i][j]) * $signed(conv_wt0[i][j]));
//                tp_sum[i][j][1] <=($signed(conv_dat[i][j]) * $signed(conv_wt1[i][j]));
//            end

            dsp_for_two_int8 dsp_for_two_int8
            (
                .clk(clk),
                .din_a(conv_wt0[i][j]),
                .din_b(conv_dat[i][j]),
                .din_d(conv_wt1[i][j]),
                .dout_ab(tp_sum[i][j][0]),
                .dout_db(tp_sum[i][j][1])
            );
            
            
         end
     end
 endgenerate  

genvar k;
generate
for(k=0;k<2;k=k+1)
begin:k_loop
    for(i=0;i<(`base_Tin/8);i=i+1)
        begin:i_loop  
            always @(posedge clk)
            begin
                sum_1[i][k] <= $signed(tp_sum[i][0][k] ) + $signed(tp_sum[i][1][k]);
                sum_2[i][k] <= $signed(tp_sum[i][2][k] ) + $signed(tp_sum[i][3][k]);
                sum_3[i][k] <= $signed(tp_sum[i][4][k] ) + $signed(tp_sum[i][5][k]);
                sum_4[i][k] <= $signed(tp_sum[i][6][k] ) + $signed(tp_sum[i][7][k]);
                sum_5[i][k] <= $signed(sum_1[i][k]) + $signed(sum_2[i][k]);
                sum_6[i][k] <= $signed(sum_3[i][k]) + $signed(sum_4[i][k]);
                sum_7[i][k] <= $signed(sum_5[i][k]) + $signed(sum_6[i][k]);
                        
                dat_out0[k] <= $signed(sum_7[0][k]) + $signed(sum_7[1][k]);
                dat_out1[k] <= $signed(sum_7[2][k]) + $signed(sum_7[3][k]);
                 
//                dat_out2[k] <= $signed(sum_7[4][k]) + $signed(sum_7[5][k]);           //if base_Tin==64
//                dat_out3[k] <= $signed(sum_7[6][k]) + $signed(sum_7[7][k]);           //if base_Tin==64
//                dat_out4[k] <= $signed(dat_out0[k]) + $signed(dat_out1[k]);           //if base_Tin==64
//                dat_out5[k] <= $signed(dat_out2[k]) + $signed(dat_out3[k]);           //if base_Tin==64
//                dat_out[k] <= $signed(dat_out4[k]) + $signed(dat_out5[k]);            //if base_Tin==64
                 
                dat_out[k] <= $signed(dat_out0[k]) + $signed(dat_out1[k]);          // if base_Tin==32

//                dat_out[k] <= $signed(sum_7[0][k]) + $signed(sum_7[1][k]);          // if base_Tin==16
            end
        end
end
endgenerate     

assign dat_o={dat_out[1],dat_out[0]};

endmodule       
     


//////////////////////////////////////
module Parallel_MAC_Calculation_0dsp2int8
(
    input clk,
    input rst_n,
    input [3:0]Tin_factor,// 1 meams 8bit
    input [`base_Tin*`MAX_DAT_DW-1:0]dat,
    input [`base_Tin*`MAX_WT_DW-1:0]wt0,
    input [`base_Tin*`MAX_WT_DW-1:0]wt1,
    output [2*(`MAX_DW2+`base_log2Tin)-1:0]dat_o
);

wire [`MAX_DAT_DW-1 :0] conv_dat[(`base_Tin/8)-1:0][8-1 : 0];
wire [`MAX_WT_DW-1 :0] conv_wt0[(`base_Tin/8)-1:0][8-1 : 0];
wire [`MAX_WT_DW-1 :0] conv_wt1[(`base_Tin/8)-1:0][8-1 : 0];

(* use_dsp = "no" *)reg signed [`MAX_DW2-1:0] tp_sum  [(`base_Tin/8)-1:0][8-1 : 0][1:0];


reg signed  [`MAX_DW2+1-1 :0] sum_1 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+1-1 :0] sum_2 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+1-1 :0] sum_3 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+1-1 :0] sum_4 [(`base_Tin/8)-1:0][1:0];

reg signed  [`MAX_DW2+2-1 :0] sum_5 [(`base_Tin/8)-1:0][1:0];
reg signed  [`MAX_DW2+2-1 :0] sum_6 [(`base_Tin/8)-1:0][1:0];

reg signed  [`MAX_DW2+3-1 :0] sum_7 [(`base_Tin/8)-1:0][1:0];

reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out0[1:0];
reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out1[1:0];
reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out2[1:0];
reg signed [`MAX_DW2+`base_log2Tin-2-1:0] dat_out3[1:0];
reg signed [`MAX_DW2+`base_log2Tin-1-1:0] dat_out4[1:0];
reg signed [`MAX_DW2+`base_log2Tin-1-1:0] dat_out5[1:0];
reg signed [`MAX_DW2+`base_log2Tin-1:0]   dat_out[1:0];


genvar i,j;
generate
    for(i=0;i<(`base_Tin/8);i=i+1)
    begin:Tin_div_8
        for(j=0;j<8;j=j+1)
        begin:group_of_8
            assign conv_dat[i][j] = dat[i*`MAX_DAT_DW*8+j*`MAX_DAT_DW+`MAX_DAT_DW-1 : i*`MAX_DAT_DW*8+j*`MAX_DAT_DW];
            assign conv_wt0[i][j] = wt0[i*`MAX_WT_DW*8+j*`MAX_WT_DW+`MAX_WT_DW-1 : i*`MAX_WT_DW*8+j*`MAX_WT_DW];
            assign conv_wt1[i][j] = wt1[i*`MAX_WT_DW*8+j*`MAX_WT_DW+`MAX_WT_DW-1 : i*`MAX_WT_DW*8+j*`MAX_WT_DW];
            
            always @(posedge clk)
            begin
                tp_sum[i][j][0] <=($signed(conv_dat[i][j]) * $signed(conv_wt0[i][j]));
                tp_sum[i][j][1] <=($signed(conv_dat[i][j]) * $signed(conv_wt1[i][j]));
            end

            
         end
     end
 endgenerate  

genvar k;
generate
for(k=0;k<2;k=k+1)
begin:k_loop
    for(i=0;i<(`base_Tin/8);i=i+1)
        begin:i_loop  
            always @(posedge clk)
            begin
                sum_1[i][k] <= $signed(tp_sum[i][0][k] ) + $signed(tp_sum[i][1][k]);
                sum_2[i][k] <= $signed(tp_sum[i][2][k] ) + $signed(tp_sum[i][3][k]);
                sum_3[i][k] <= $signed(tp_sum[i][4][k] ) + $signed(tp_sum[i][5][k]);
                sum_4[i][k] <= $signed(tp_sum[i][6][k] ) + $signed(tp_sum[i][7][k]);
                sum_5[i][k] <= $signed(sum_1[i][k]) + $signed(sum_2[i][k]);
                sum_6[i][k] <= $signed(sum_3[i][k]) + $signed(sum_4[i][k]);
                sum_7[i][k] <= $signed(sum_5[i][k]) + $signed(sum_6[i][k]);
                        
                dat_out0[k] <= $signed(sum_7[0][k]) + $signed(sum_7[1][k]);
                dat_out1[k] <= $signed(sum_7[2][k]) + $signed(sum_7[3][k]);
                 
//                dat_out2[k] <= $signed(sum_7[4][k]) + $signed(sum_7[5][k]);           //if base_Tin==64
//                dat_out3[k] <= $signed(sum_7[6][k]) + $signed(sum_7[7][k]);           //if base_Tin==64
//                dat_out4[k] <= $signed(dat_out0[k]) + $signed(dat_out1[k]);           //if base_Tin==64
//                dat_out5[k] <= $signed(dat_out2[k]) + $signed(dat_out3[k]);           //if base_Tin==64
//                dat_out[k] <= $signed(dat_out4[k]) + $signed(dat_out5[k]);            //if base_Tin==64
                 
                dat_out[k] <= $signed(dat_out0[k]) + $signed(dat_out1[k]);          // if base_Tin==32

  //               dat_out[k] <= $signed(sum_7[0][k]) + $signed(sum_7[1][k]);          // if base_Tin==16
            end
        end
end
endgenerate     

assign dat_o={dat_out[1],dat_out[0]};

endmodule       