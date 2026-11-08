`timescale 1ns/1ps

module tb_apb_alu_slave;

    // APB SIGNALS  

    reg         PCLK;
    reg         PRESETn;

    reg  [31:0] PADDR;
    reg         PWRITE;
    reg         PSEL;
    reg         PENABLE;
    reg  [31:0] PWDATA;

    wire [31:0] PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    wire        Difference_unused;
    wire        Bout_unused;


    apb_alu_slave DUT (

        .PCLK     (PCLK),
        .PRESETn  (PRESETn),

        .PADDR    (PADDR),
        .PWRITE   (PWRITE),
        .PSEL     (PSEL),
        .PENABLE  (PENABLE),
        .PWDATA   (PWDATA),

        .PRDATA   (PRDATA),
        .PREADY   (PREADY),
        .PSLVERR  (PSLVERR)
    );

    // ADDRESS MAP

    localparam ADDR_A      = 32'h0000_0000;
    localparam ADDR_B      = 32'h0000_0004;
    localparam ADDR_OP     = 32'h0000_0008;
    localparam ADDR_RESULT = 32'h0000_000C;

    // ALU OPERATION CODES


    localparam OP_ADD = 2'b00;
    localparam OP_SUB = 2'b01;
    localparam OP_AND = 2'b10;
    localparam OP_OR  = 2'b11;

    // CLOCK GENERATION
    // 10 ns clock period

    initial begin
        PCLK = 1'b0;
        forever #5 PCLK = ~PCLK;
    end

    
    initial begin
        $dumpfile("apb_alu_waveform.vcd");
        $dumpvars(0, tb_apb_alu_slave);
    end

    // RESET TASK
   
    task reset_dut;
    begin

        PADDR   = 32'h0;
        PWRITE  = 1'b0;
        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWDATA  = 32'h0;

        PRESETn = 1'b0;

        repeat(2)
            @(posedge PCLK);

        PRESETn = 1'b1;

        @(posedge PCLK);

        $display("----------------------------------------");
        $display("RESET COMPLETED");
        $display("----------------------------------------");

    end
    endtask

    // APB WRITE TASK
    
    task apb_write;

        input [31:0] address;
        input [31:0] data;

    begin

      // SETUP PHASE
        
        @(negedge PCLK);

        PADDR   = address;
        PWDATA  = data;
        PWRITE  = 1'b1;
        PSEL    = 1'b1;
        PENABLE = 1'b0;

        @(posedge PCLK);

       // ACCESS PHASE
     
        @(negedge PCLK);

        PENABLE = 1'b1;

        @(posedge PCLK);

        // Check APB completion/error
        if (!PREADY)
            $display("ERROR: Write transaction not ready at address %h",
                     address);

        if (PSLVERR)
            $display("APB ERROR: Invalid write address = %h",
                     address);
        else
            $display("APB WRITE: Address = %h, Data = %h",
                     address, data);

        // Return to IDLE
      
        @(negedge PCLK);

        PSEL    = 1'b0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PADDR   = 32'h0;
        PWDATA  = 32'h0;

    end
    endtask

    // APB READ TASK
   

    task apb_read;

        input  [31:0] address;
        output [31:0] data;

    begin

       
        // SETUP PHASE
     
        @(negedge PCLK);

        PADDR   = address;
        PWDATA  = 32'h0;
        PWRITE  = 1'b0;
        PSEL    = 1'b1;
        PENABLE = 1'b0;

        @(posedge PCLK);

        
        // ACCESS PHASE
       

        @(negedge PCLK);

        PENABLE = 1'b1;

        @(posedge PCLK);

        if (!PREADY)
            $display("ERROR: Read transaction not ready at address %h",
                     address);

        data = PRDATA;

        if (PSLVERR) begin

            $display("APB ERROR: Invalid read address = %h",
                     address);

        end
        else begin

            $display("APB READ : Address = %h, Data = %h",
                     address, data);

        end

      
        // Return to IDLE
        
        @(negedge PCLK);

        PSEL    = 1'b0;
        PENABLE = 1'b0;

    end
    endtask

    
    // ALU OPERATION TASK
    

    task test_alu;

        input [3:0] A;
        input [3:0] B;
        input [1:0] OP;
        input [3:0] expected;

        reg [31:0] result;

    begin

        $display("");
        $display("========================================");
        $display("ALU TEST");
        $display("A = %d, B = %d, OP = %b",
                 A, B, OP);
        $display("========================================");

        // Write operand A
        apb_write(ADDR_A, {28'b0, A});

        // Write operand B
        apb_write(ADDR_B, {28'b0, B});

        // Write operation
        apb_write(ADDR_OP, {30'b0, OP});

        // Read result
        apb_read(ADDR_RESULT, result);

        // Compare result
        if (result[3:0] == expected) begin

            $display("PASS: Expected = %h, Received = %h",
                     expected, result[3:0]);

        end
        else begin

            $display("FAIL: Expected = %h, Received = %h",
                     expected, result[3:0]);

        end

    end
    endtask

    
    // MAIN TEST SEQUENCE
   
    reg [31:0] read_value;

    initial begin

        
        // RESET
      
        reset_dut;


        // TEST 1: ADD
        // 5 + 3 = 8
     
        test_alu(
            4'd5,
            4'd3,
            OP_ADD,
            4'd8
        );


        // TEST 2: SUBTRACT
        // 9 - 4 = 5
 
        test_alu(
            4'd9,
            4'd4,
            OP_SUB,
            4'd5
        );

        // TEST 3: AND
        // 1010 & 1100 = 1000
        
        test_alu(
            4'b1010,
            4'b1100,
            OP_AND,
            4'b1000
        );

        // TEST 4: OR
        // 1010 | 0101 = 1111
    

        test_alu(
            4'b1010,
            4'b0101,
            OP_OR,
            4'b1111
        );

        // TEST 5: READ BACK OPERAND A
        

        $display("");
        $display("========================================");
        $display("REGISTER READ-BACK TEST");
        $display("========================================");

        apb_write(
            ADDR_A,
            32'h0000_0007
        );

        apb_read(
            ADDR_A,
            read_value
        );

        if (read_value[3:0] == 4'd7)
            $display("PASS: Register A read-back successful");
        else
            $display("FAIL: Register A read-back");


         // TEST 6: INVALID ADDRESS READ
        $display("");
        $display("========================================");
        $display("INVALID ADDRESS READ TEST");
        $display("========================================");

        apb_read(
            32'h0000_0020,
            read_value
        );

        if (PSLVERR === 1'b1)
            $display("PASS: Invalid address generated PSLVERR");
        else
            $display("FAIL: PSLVERR was not asserted");


     
        // TEST 7: INVALID ADDRESS WRITE
      

        $display("");
        $display("========================================");
        $display("INVALID ADDRESS WRITE TEST");
        $display("========================================");

        apb_write(
            32'h0000_0020,
            32'h0000_00AA
        );


        // END SIMULATION
      

        $display("");
        $display("========================================");
        $display("ALL APB ALU TESTS COMPLETED");
        $display("========================================");

        #20;

        $finish;

    end
  
    

endmodule
