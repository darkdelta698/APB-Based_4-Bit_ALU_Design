`timescale 1ns/1ps

// 4-BIT ALU IP

module alu_4bit (
    input  wire [3:0] A,
    input  wire [3:0] B,
    input  wire [1:0] OP,

    output reg  [3:0] RESULT
);

    always @(*) begin

        case (OP)

            2'b00: RESULT = A + B;  // ADD
            2'b01: RESULT = A - B;  // SUB
            2'b10: RESULT = A & B;  // AND
            2'b11: RESULT = A | B;  // OR

            default: RESULT = 4'b0000;

        endcase

    end

endmodule

// APB SLAVE WRAPPER

module apb_alu_slave (

    // APB interface
    input  wire        PCLK,
    input  wire        PRESETn,

    input  wire [31:0] PADDR,
    input  wire        PWRITE,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire [31:0] PWDATA,

    output wire [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR
);

    // Register storage

    reg [3:0] operand_A;
    reg [3:0] operand_B;
    reg [1:0] operation;

    wire [3:0] alu_result;

    // Address definitions


    localparam ADDR_A      = 32'h0000_0000;
    localparam ADDR_B      = 32'h0000_0004;
    localparam ADDR_OP     = 32'h0000_0008;
    localparam ADDR_RESULT = 32'h0000_000C;


    // ALU IP instantiation

    alu_4bit U_ALU (

        .A      (operand_A),
        .B      (operand_B),
        .OP     (operation),
        .RESULT (alu_result)

    );

    // APB READY
    // Zero-wait-state slave

    assign PREADY = PSEL && PENABLE;

    // Address validity

    wire valid_address;

    assign valid_address =
           (PADDR == ADDR_A)      ||
           (PADDR == ADDR_B)      ||
           (PADDR == ADDR_OP)     ||
           (PADDR == ADDR_RESULT);

    // APB ERROR
  
    assign PSLVERR =
           PSEL && PENABLE && !valid_address;

    // WRITE OPERATION
   
    always @(posedge PCLK) begin

        if (!PRESETn) begin

            operand_A <= 4'b0000;
            operand_B <= 4'b0000;
            operation <= 2'b00;

        end

        else begin

            if (PSEL && PENABLE && PWRITE) begin

                case (PADDR)

                    ADDR_A: begin
                        operand_A <= PWDATA[3:0];
                    end

                    ADDR_B: begin
                        operand_B <= PWDATA[3:0];
                    end

                    ADDR_OP: begin
                        operation <= PWDATA[1:0];
                    end

                    ADDR_RESULT: begin
                        // RESULT is read-only
                    end

                    default: begin
                        // Invalid address
                    end

                endcase

            end

        end

    end

    // READ OPERATION
   
    reg [31:0] read_data;

    always @(*) begin

        read_data = 32'h0000_0000;

        if (PSEL && PENABLE && !PWRITE) begin

            case (PADDR)

                ADDR_A: begin
                    read_data = {28'b0, operand_A};
                end

                ADDR_B: begin
                    read_data = {28'b0, operand_B};
                end

                ADDR_OP: begin
                    read_data = {30'b0, operation};
                end

                ADDR_RESULT: begin
                    read_data = {28'b0, alu_result};
                end

                default: begin
                    read_data = 32'h0000_0000;
                end

            endcase

        end

    end

    assign PRDATA = read_data;

endmodule




/*
| Address | Register    | Function                        |
| ------- | ----------- | ------------------------------- |
| `0x00`  | `OPERAND_A` | 4-bit operand A                 |
| `0x04`  | `OPERAND_B` | 4-bit operand B                 |
| `0x08`  | `OPERATION` | `00=ADD, 01=SUB, 10=AND, 11=OR` |
| `0x0C`  | `RESULT`    | 4-bit ALU result                |
| Other   | Invalid     | `PSLVERR=1`  */