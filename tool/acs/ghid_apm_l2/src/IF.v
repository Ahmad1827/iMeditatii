// Cerinta 2: Etapa IF (Instruction Fetch)
// Leaga: mux -> PC -> memoria de instructiuni, plus sumatorul PC + 4
//
//            PC_Branch --+
//                        v
//   PC+4 -------------> MUX --> PC --+--> memorie --> INSTRUCTION_IF
//     ^                (PCSrc)       |
//     +------- sumator (+4) <--------+--> PC_IF
module IF(
    input         clk,
    input         reset,
    input         PCSrc,          // 1 = saltul e luat, PC ia PC_Branch
    input         PC_write,       // 0 = PC-ul sta pe loc (stall)
    input  [31:0] PC_Branch,      // adresa de salt (vine din EX, simulata in testbench)
    output [31:0] PC_IF,          // adresa instructiunii curente
    output [31:0] INSTRUCTION_IF  // instructiunea curenta
);
    wire [31:0] PC_plus4;
    wire [31:0] PC_next;

    mux2_1 MUX_PC(
        .ina(PC_plus4),
        .inb(PC_Branch),
        .sel(PCSrc),
        .out(PC_next)
    );

    PC PC_REG(
        .clk(clk),
        .res(reset),
        .write(PC_write),
        .in(PC_next),
        .out(PC_IF)
    );

    adder ADD4(
        .ina(PC_IF),
        .inb(32'd4),
        .out(PC_plus4)
    );

    instruction_memory INSTR_MEM(
        .address(PC_IF[11:2]),
        .instruction(INSTRUCTION_IF)
    );
endmodule
