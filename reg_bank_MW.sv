`timescale 1ns / 1ps
module reg_bank_MW #(
    parameter int M = 4,
    parameter int W = 8
)(
    input  logic clk,
    input  logic rst,
    input  logic wr_en,
    input  logic [$clog2(M)-1:0] wr_addr,
    input  logic [W-1:0] wr_data,
    input  logic [$clog2(M)-1:0] rd_addr,
    output logic [W-1:0] rd_data
);
    
    logic [W-1:0] regs [0:M-1];
    
    always_ff @(posedge clk) begin
        if (rst) begin
            for (int i = 0 ; i < M ; i++) begin
                regs[i] <= '0;
            end
        end
        else if (wr_en) begin
            regs[wr_addr] <= wr_data;
        end
    end
    
    always_comb begin
        rd_data = regs[rd_addr];
    end
endmodule
