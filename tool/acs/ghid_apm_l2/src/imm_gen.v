// Cerinta 4: Generatorul de valori imediate
// Se uita la opcode (si la funct3 pentru shiftari), reasambleaza bitii imediatului
// si face extensie de semn pana la 32 de biti (copiaza bitul in[31] in bitii de sus).
//
//   Tip I  (lw, addi, andi, ori, xori, slti, sltiu): imm = in[31:20]
//   Shift  (slli, srli, srai):                      imm = shamt = in[24:20]
//   Tip S  (sw):                                    imm = {in[31:25], in[11:7]}
//   Tip B  (beq, bne, blt, bge, bltu, bgeu):        imm = {in[31], in[7], in[30:25], in[11:8], 0}
module imm_gen(
    input      [31:0] in,
    output reg [31:0] out
);
    wire [6:0] opcode = in[6:0];
    wire [2:0] funct3 = in[14:12];

    always @(*) begin
        case (opcode)
            7'b0000011: // lw (tip I)
                out = {{20{in[31]}}, in[31:20]};

            7'b0010011: // addi, slti, sltiu, xori, ori, andi, slli, srli, srai
                if (funct3 == 3'b001 || funct3 == 3'b101)
                    out = {27'b0, in[24:20]};          // slli / srli / srai -> shamt
                else
                    out = {{20{in[31]}}, in[31:20]};   // tip I obisnuit

            7'b0100011: // sw (tip S)
                out = {{20{in[31]}}, in[31:25], in[11:7]};

            7'b1100011: // beq, bne, blt, bge, bltu, bgeu (tip B)
                out = {{19{in[31]}}, in[31], in[7], in[30:25], in[11:8], 1'b0};

            default:    // tip R (add, and, ...) nu are imediat
                out = 32'b0;
        endcase
    end
endmodule
