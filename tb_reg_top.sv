`timescale 1ns / 1ps

module tb_reg_top;

logic done_a, done_b;
 
    tb_unit #(.M(4), .W(8)) u_cfg_a (.done(done_a));
    tb_unit #(.M(8), .W(4)) u_cfg_b (.done(done_b));
 
    initial begin
        wait (done_a && done_b);
        #10;
        $display("testing complete");
        $finish;
    end
endmodule
