// Cerinta 1d: Sumator pe 32 de biti (folosit pentru PC + 4)
module adder(
    input  [31:0] ina,
    input  [31:0] inb,
    output [31:0] out
);
    assign out = ina + inb;
endmodule
