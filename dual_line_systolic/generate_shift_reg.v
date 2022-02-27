`include "CNN_defines.vh"

module generate_shift_reg #
(
	parameter DATA_WIDTH=256,
	parameter DEPTH=16
)
(
    input clk,
    input rst_n,

    input [DATA_WIDTH-1:0]data_in,
    output [DATA_WIDTH-1:0]data_out
);
reg [DATA_WIDTH-1:0]dat_reg[DEPTH-1:0];

integer i;
generate
    always@(posedge clk or negedge rst_n)
    begin
        if(!rst_n)
            dat_reg[0]<='b0;
        else begin
            dat_reg[0]<=data_in;
            for(i=1;i<DEPTH;i=i+1) begin
                dat_reg[i]<=dat_reg[i-1];
            end
        end
    end
endgenerate

assign data_out=dat_reg[DEPTH-1];

endmodule
