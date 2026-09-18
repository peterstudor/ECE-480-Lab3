`timescale 1ns / 1ps
module tb_counter_top;

    logic done4 , done8;
    
    tb_unit #(.WIDTH(4)) u_w4 (.done(done4));
    tb_unit #(.WIDTH(8)) u_w8 (.done(done8));
    
    
    initial begin
        wait (done4 && done8);
        #10;
        $display("simulation complete");
        $finish;
    end

endmodule
