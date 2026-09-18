

module tb_unit #(
parameter int M = 4 ,
parameter int W = 8
) (output logic done);
    logic clk = 0;
    logic rst, wr_en;
    logic [$clog2(M)-1:0] wr_addr, rd_addr;
    logic [W-1:0]  wr_data;
    logic [W-1:0]  rd_data;
 
    logic [W-1:0] expected [0:M-1];
    logic [$clog2(M)-1:0] order [0:M-1];   // a read order different from write order
    
    int errors = 0;
    int checks = 0;
    int build_idx;
    int watch_addr;
    int raw_addr;
    logic [W-1:0] raw_old, raw_new;

    always #1 clk = ~clk;  
    
    reg_bank_MW #(.M(M), .W(W)) dut (
        .clk(clk), .rst(rst), .wr_en(wr_en),
        .wr_addr(wr_addr), .wr_data(wr_data),
        .rd_addr(rd_addr), .rd_data(rd_data)
    );
    
    // expected model to reference dut
    always_ff @(negedge clk) begin
        if (rst) begin
            for (int i = 0; i < M; i++)
                expected[i] <= '0;
        end
        else if (wr_en) begin
            expected[wr_addr] <= wr_data;
        end
    end
    
    // build order order that is differernt from ascending write order, odd than even
    initial begin
        build_idx = 0;
        for (int k = 1; k < M; k += 2) begin
            order[build_idx] = $clog2(M)'(k);
            build_idx++;
        end
        for (int k = 0; k < M; k += 2) begin
            order[build_idx] = $clog2(M)'(k);
            build_idx++;
        end
    end
    
    // verification task
    task automatic check_read();
        #1;
        checks++;
        if (rd_data !== expected[rd_addr]) begin
            errors++;
            $display("[M=%0d W=%0d] mismatch at rd_addr=%0d rd_data=%0d expected=%0d",
                      M, W, rd_addr, rd_data, expected[rd_addr]);
        end
    endtask
    
    int old_errors = 0;
    // begin tests
    initial begin
        done = 0;
        rst = 1; wr_en = 0; wr_addr = '0; wr_data = '0; rd_addr = '0;
        repeat (2) @(negedge clk);
        
        // check reset clears registers
        for (int i = 0 ; i < M ; i++) begin
            rd_addr = $clog2(M)'(i);
            check_read();
        end
        if (errors == 0)
            $display("[M=%0d W=%0d] reset operation passed" , M , W);
        rst = 0;
        old_errors = errors;
        
        // write distinct value to register
        for (int i = 0; i < M; i++) begin
            wr_en   = 1;
            wr_addr = $clog2(M)'(i);
            wr_data = W'(i * 37 + 11);   // distinct pattern per address
            @(negedge clk);
        end
        wr_en = 0;
        for (int i = 0; i < M; i++) begin
            rd_addr = $clog2(M)'(i);
            check_read();
        end
        if (errors == old_errors)
            $display("[M=%0d W=%0d] write operation passed" , M , W);
        old_errors = errors;
        
        // read in different order
        for (int i = 0 ; i < M ; i++) begin
            rd_addr = order[i];
            check_read();
        end
        if (errors == old_errors)
            $display("[M=%0d W=%0d] read order operation passed" , M , W);
        old_errors = errors;
        
        // persistence of register
        watch_addr = 1 % M;
        rd_addr = $clog2(M)'(watch_addr);
        check_read(); // baseline value before other writes
        
        wr_en = 1; wr_addr = $clog2(M)'((watch_addr + 1) % M); wr_data = W'(8'hAA); @(negedge clk); #1;
        wr_en = 1; wr_addr = $clog2(M)'((watch_addr + 2) % M); wr_data = W'(8'h55); @(negedge clk); #1;
        wr_en = 0;
 
        rd_addr = $clog2(M)'(watch_addr);
        check_read(); // must still match - untouched register
        if (errors == old_errors)
            $display("[M=%0d W=%0d] persistence operation passed" , M , W);
        old_errors = errors;
        
        // overwriting register
         wr_en = 1; wr_addr = '0; wr_data = W'(8'hF0); @(negedge clk); #1; wr_en = 0;
        rd_addr = '0;
        check_read(); // value after first write
 
        wr_en = 1; wr_addr = '0; wr_data = W'(8'h0F); @(negedge clk); #1; wr_en = 0;
        rd_addr = '0;
        check_read(); // new value must win
        if (errors == old_errors)
            $display("[M=%0d W=%0d] overwrite operation passed" , M , W);
        old_errors = errors;
        
        // asynchronous read
        for (int i = 0; i < M; i++) begin
            rd_addr = $clog2(M)'(i); // async bc no clk modification
            check_read();
        end
        if (errors == old_errors)
            $display("[M=%0d W=%0d] combinational rd_addr (no clk edge) operation passed" , M , W);
        old_errors = errors;
 
        // read after write
        raw_addr = (M > 2) ? 2 : 0;
        raw_old  = expected[raw_addr]; // value before this write is issued
        raw_new  = raw_old ^ W'({W{1'b1}}); // guaranteed different value
 
        rd_addr = $clog2(M)'(raw_addr);
        wr_en = 1; wr_addr = $clog2(M)'(raw_addr); wr_data = raw_new;
        #1;
        checks++;
        if (rd_data !== raw_old) begin
            errors++;
            $display("[M=%0d W=%0d] RAW mismatch expected old value %0d before write commits, got %0d",
                      M, W, raw_old, rd_data);
        end
 
        @(negedge clk); wr_en = 0;
        check_read(); // new value must be visible now
        if (errors == old_errors)
            $display("[M=%0d W=%0d] read-after-write operation passed" , M , W);
        old_errors = errors;
 
        #5;
        if (errors == 0)
            $display("*** [M=%0d W=%0d] ALL CHECKS PASSED (%0d comparisons) ***" , M, W, checks);
        else
            $display("*** [M=%0d W=%0d] %0d ERROR(S) DETECTED (%0d comparisons) ***" , M, W, errors, checks);
 
        done = 1;
    end
endmodule
