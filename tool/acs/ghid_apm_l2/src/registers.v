// Cerinta 3: Bancul de registri (32 de registri x 32 de biti, x0..x31)
// - 2 porturi de citire ASINCRONE (read_data1, read_data2 se schimba imediat cu adresa)
// - 1 port de scriere SINCRON (pe frontul pozitiv, cand reg_write = 1)
// - x0 este mereu 0 (nu se poate scrie in el)
module registers(
    input         clk,
    input         reg_write,
    input  [4:0]  read_reg1,
    input  [4:0]  read_reg2,
    input  [4:0]  write_reg,
    input  [31:0] write_data,
    output [31:0] read_data1,
    output [31:0] read_data2
);
    reg [31:0] regs [0:31];

    // pentru simulare: registrul xi primeste valoarea i
    integer i;
    initial begin
        for (i = 0; i < 32; i = i + 1)
            regs[i] = i;
    end

    // scriere sincrona; scrierea in x0 este ignorata
    always @(posedge clk) begin
        if (reg_write && write_reg != 5'd0)
            regs[write_reg] <= write_data;
    end

    // citire asincrona
    assign read_data1 = regs[read_reg1];
    assign read_data2 = regs[read_reg2];
endmodule
