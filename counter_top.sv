`timescale 1ns / 1ps

module counter_top #(
    parameter WIDTH = 4,
    parameter DIVISOR = 100000000
) (
    input logic clk , 
    input logic en ,
    input logic up ,
    input logic rst ,
    output logic [WIDTH-1:0] q
);
    logic tick;
    logic tick_en;
    
    tick_gen #(.DIVISOR(DIVISOR)) tg (.clk(clk) , .rst(rst) , .tick(tick));
    
    assign tick_en = tick & en;
    
    counter_param #(.WIDTH(WIDTH)) counter (.clk(clk) , .rst(rst) , .en(tick_en) , .up(up) , .q(q));
endmodule
