`timescale 1ns / 1ps

module tick_gen #(
    parameter int DIVISOR = 100_000_000
)(
    input  logic clk,
    input  logic rst,
    output logic tick
);

    localparam int CNT_WIDTH = (DIVISOR > 1) ? $clog2(DIVISOR) : 1;
 
    logic [CNT_WIDTH-1:0] count;
 
    always_ff @(posedge clk) begin
        if (rst) begin
            count <= '0;
            tick  <= 1'b0;
        end
        else if (count == DIVISOR - 1) begin
            count <= '0;
            tick  <= 1'b1;   // asserted for exactly this one cycle
        end
        else begin
            count <= count + 1'b1;
            tick  <= 1'b0;
        end
    end
endmodule
