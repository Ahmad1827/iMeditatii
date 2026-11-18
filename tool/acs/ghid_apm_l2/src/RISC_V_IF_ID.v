`timescale 1ns / 1ps

module RISC_V_IF_ID(
    input         clk,
    input         reset,
    input         IF_ID_write,
    input         PCSrc, PC_write,
    input  [31:0] PC_Branch,
    input         RegWrite_WB,
    input  [31:0] ALU_DATA_WB,
    input  [4:0]  RD_WB,
    output [31:0] PC_ID,
    output [31:0] INSTRUCTION_ID,
    output [31:0] IMM_ID,
    output [31:0] REG_DATA1_ID,
    output [31:0] REG_DATA2_ID,
    output [2:0]  FUNCT3_ID,
    output [6:0]  FUNCT7_ID,
    output [6:0]  OPCODE_ID,
    output [4:0]  RD_ID,
    output [4:0]  RS1_ID,
    output [4:0]  RS2_ID
);
    wire [31:0] PC_IF;
    wire [31:0] INSTRUCTION_IF;

    IF IF_STAGE(
        .clk(clk),
        .reset(reset),
        .PCSrc(PCSrc),
        .PC_write(PC_write),
        .PC_Branch(PC_Branch),
        .PC_IF(PC_IF),
        .INSTRUCTION_IF(INSTRUCTION_IF)
    );

    IF_ID_reg IF_ID_REGISTER(
        .clk(clk),
        .res(reset),
        .write(IF_ID_write),
        .pc_in(PC_IF),
        .instruction_in(INSTRUCTION_IF),
        .pc_out(PC_ID),
        .instruction_out(INSTRUCTION_ID)
    );

    ID ID_STAGE(
        .clk(clk),
        .PC_ID(PC_ID),
        .INSTRUCTION_ID(INSTRUCTION_ID),
        .RegWrite_WB(RegWrite_WB),
        .ALU_DATA_WB(ALU_DATA_WB),
        .RD_WB(RD_WB),
        .IMM_ID(IMM_ID),
        .REG_DATA1_ID(REG_DATA1_ID),
        .REG_DATA2_ID(REG_DATA2_ID),
        .FUNCT3_ID(FUNCT3_ID),
        .FUNCT7_ID(FUNCT7_ID),
        .OPCODE_ID(OPCODE_ID),
        .RD_ID(RD_ID),
        .RS1_ID(RS1_ID),
        .RS2_ID(RS2_ID)
    );
endmodule

// Cerinta 6: registrul de pipeline IF/ID
module IF_ID_reg(
    input             clk,
    input             res,
    input             write,
    input      [31:0] pc_in,
    input      [31:0] instruction_in,
    output reg [31:0] pc_out,
    output reg [31:0] instruction_out
);
    always @(posedge clk) begin
        if (res) begin
            pc_out          <= 32'b0;
            instruction_out <= 32'b0;
        end else if (write) begin
            pc_out          <= pc_in;
            instruction_out <= instruction_in;
        end
    end
endmodule
