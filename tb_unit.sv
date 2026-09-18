`timescale 1ns / 1ps

module tb_unit #(parameter int WIDTH = 4)(
    output logic done
    );
    
    logic clk = 0;
    logic rst , en , up;
    logic [WIDTH-1:0] q;
    logic [WIDTH-1:0] expected;
    
    int errors = 0;
    int checks = 0;
    
    always #1 clk = ~clk; // clock example for testing
    
    // dut
    counter_param #(.WIDTH(WIDTH)) dut (
    .clk(clk) , .rst(rst) , .en(en) , .up(up) , .q(q)
    );
    
    // expected
    always_ff @(posedge  clk) begin
        if (rst)
            expected <= 0;
        else begin
            case ({en , up})
                2'b00: expected <= expected;
                2'b01: expected <= expected;
                2'b10: expected <= expected - 1;
                2'b11: expected <= expected + 1;
            endcase
        end
    end
    
    // track errors
    always @(posedge clk) begin
        #1; // let both dut and model settle
        checks++;
        if (q !== expected) begin
            errors++;
            $display("[WIDTH=%0d] t=%0t mismatch: q=%0d expected=%0d (rst=%b en=%b up=%b)",
                      WIDTH, $time, q, expected, rst, en, up);
        end
    end
    
    // preform tests
    initial begin
        done = 0;
        rst = 1; en = 0; up = 1;
        repeat (2) @(negedge clk);
        
        rst = 0;
        repeat (2) @(negedge clk);
 
        // up wraparound
        en = 1; up = 1;
        repeat ((1 << WIDTH) * 2 + 3) @(negedge clk);
        
        if (errors == 0)
            $display("up wraparound passed for WIDTH=%0d" , WIDTH);
 
        // down wraparound
        up = 0;
        repeat ((1 << WIDTH) * 2 + 3) @(negedge clk);

        if (errors == 0)
            $display("down wraparound passed for WIDTH=%0d" , WIDTH);

 
        // en low
        en = 0;
        repeat (5) @(negedge clk);
        
        if (errors == 0)
            $display("en low passed for WIDTH=%0d" , WIDTH);        
        
        // up counting and down counting with resets
        en = 1; up = 1;
        repeat(5) @(negedge clk);
        rst = 1; @(negedge clk);
        rst = 0; @(negedge clk);
        
        en = 1; up = 1;
        repeat(10) @(negedge clk);
        en = 1; up = 0;
        repeat(5) @(negedge clk);
        rst = 1; @(negedge clk);
        rst = 0; @(negedge clk);
        
        if (errors == 0)
            $display("changing direction and reset passed for WIDTH=%0d" , WIDTH);
 
 
        #20;
        if (errors == 0)
            $display("WIDTH=%0d passed all %0d checks matched", WIDTH, checks);
        else
            $display("WIDTH=%0d failed %0d/%0d checks mismatched", WIDTH, errors, checks);
 
        done = 1;
    end
endmodule
