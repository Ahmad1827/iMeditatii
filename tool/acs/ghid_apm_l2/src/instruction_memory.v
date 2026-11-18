// Cerinta 1c: Memoria de instructiuni cu citire asincrona (fara clk)
// 1024 de cuvinte a cate 32 de biti, incarcate din fisierul code.mem
//
// PC-ul creste din 4 in 4 (0, 4, 8, ...), dar memoria are o instructiune pe linie (0, 1, 2, ...).
// Varianta cu shiftare ar fi: codeMemory[(address >> 2)] (pe 10 biti).
// Raspuns la "Obs": luam direct bitii [11:2] ai adresei. Ignorarea ultimilor 2 biti
// inseamna exact impartirea la 4, deci nu mai e nevoie de shiftare.
module instruction_memory(
    input      [9:0]  address,      // primeste deja PC[11:2]
    output reg [31:0] instruction
);
    reg [31:0] codeMemory [0:1023];

    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1)
            codeMemory[i] = 32'h00000000;
        $readmemh("code_stud.mem", codeMemory);
    end

    always @(*) begin
        instruction = codeMemory[address];
    end
endmodule
