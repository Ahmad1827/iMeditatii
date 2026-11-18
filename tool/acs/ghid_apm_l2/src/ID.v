// Cerinta 5: Etapa ID (Instruction Decode)
// Taie instructiunea in campuri, citeste registrii si genereaza imediatul.
//
//   | funct7 | rs2   | rs1   | funct3 | rd   | opcode |
//   | 31:25  | 24:20 | 19:15 | 14:12  | 11:7 | 6:0    |
//
// RegWrite_WB, RD_WB, ALU_DATA_WB vin din etapa WB (Lucrarea 3); acum le da testbench-ul.
module ID(
    input         clk,
    input  [31:0] PC_ID,
    input  [31:0] INSTRUCTION_ID,
    input         RegWrite_WB,
    input  [31:0] ALU_DATA_WB,
    input  [4:0]  RD_WB,
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
    // campurile instructiunii
    assign OPCODE_ID = INSTRUCTION_ID[6:0];
    assign RD_ID     = INSTRUCTION_ID[11:7];
    assign FUNCT3_ID = INSTRUCTION_ID[14:12];
    assign RS1_ID    = INSTRUCTION_ID[19:15];
    assign RS2_ID    = INSTRUCTION_ID[24:20];
    assign FUNCT7_ID = INSTRUCTION_ID[31:25];

    registers REG_FILE(
        .clk(clk),
        .reg_write(RegWrite_WB),
        .read_reg1(RS1_ID),
        .read_reg2(RS2_ID),
        .write_reg(RD_WB),
        .write_data(ALU_DATA_WB),
        .read_data1(REG_DATA1_ID),
        .read_data2(REG_DATA2_ID)
    );

    imm_gen IMM_GEN(
        .in(INSTRUCTION_ID),
        .out(IMM_ID)
    );
endmodule
