// Cerinta 3 cere ca bancul de registri sa fie simulat SEPARAT: un testbench al lui.
`timescale 1ns / 1ps
module tb_registers;
  reg         clk, reg_write;
  reg  [4:0]  read_reg1, read_reg2, write_reg;
  reg  [31:0] write_data;
  wire [31:0] read_data1, read_data2;

  registers dut(.clk(clk), .reg_write(reg_write),
                .read_reg1(read_reg1), .read_reg2(read_reg2), .write_reg(write_reg),
                .write_data(write_data),
                .read_data1(read_data1), .read_data2(read_data2));

  always #5 clk = ~clk;            // fronturi pozitive la 5, 15, 25, ... ns

  initial begin
    clk = 0; reg_write = 0;
    read_reg1 = 5'd1; read_reg2 = 5'd2;  // citire: x1 = 1, x2 = 2
    write_reg = 5'd0; write_data = 32'd0;

    #12 read_reg1 = 5'd7;                // t = 12: citirea e asincrona, read_data1 = 7 imediat

    #6  reg_write = 1;                   // t = 18: scriem 0xAB in x3
        write_reg = 5'd3; write_data = 32'hAB;
        read_reg2 = 5'd3;                // read_data2 = 3 pana la front, 0xAB dupa frontul de la 25 ns

    #10 write_reg = 5'd0;                // t = 28: incercam sa scriem 0xFF in x0
        write_data = 32'hFF;
        read_reg1 = 5'd0;                // read_data1 = 0 si ramane 0 (x0 nu se scrie)

    #10 reg_write = 0;                   // t = 38: scrierea e oprita
        write_reg = 5'd4; write_data = 32'h55;
        read_reg1 = 5'd4;                // read_data1 = 4: fara reg_write nu se scrie nimic

    #20 $finish;                         // t = 58
  end
endmodule
