// Cerinta 1b: Registrul PC (bistabil de tip D pe 32 de biti)
// - la reset devine 0
// - pe frontul pozitiv al ceasului ia valoarea de la intrare, doar daca write = 1
//   (write = PC_Write, vine de la unitatea de detectie a hazardurilor; 0 = "ingheata" PC-ul)
module PC(
    input             clk,
    input             res,
    input             write,
    input      [31:0] in,
    output reg [31:0] out
);
    always @(posedge clk) begin
        if (res)
            out <= 32'b0;
        else if (write)
            out <= in;
    end
endmodule
