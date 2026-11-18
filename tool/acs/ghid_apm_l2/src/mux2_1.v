// Cerinta 1a: Multiplexor 2:1 pe 32 de biti
// sel = 0 -> iesirea = ina (PC + 4)
// sel = 1 -> iesirea = inb (PC_Branch, adresa de salt)
module mux2_1(
    input  [31:0] ina,
    input  [31:0] inb,
    input         sel,
    output [31:0] out
);
    assign out = sel ? inb : ina;
endmodule
