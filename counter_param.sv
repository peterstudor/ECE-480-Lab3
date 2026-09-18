`timescale 1ns / 1ps

module counter_param #(parameter int WIDTH = 4)(
    input logic clk , rst , en , up ,
    output logic [WIDTH-1:0] q
    );
    
    always_ff @(posedge clk) begin
        if (rst)
            q <= 0;
        else begin
            if (en) begin
                if (up)
                    q <= q + 1;
                else
                    q <= q - 1;
            end
        end
    end
endmodule
