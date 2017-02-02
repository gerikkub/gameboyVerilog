`timescale 1ns / 1ns

module memory_rom(
    input clock,

    input [15:0]address_bus,

    inout [7:0]data_bus,

    input nread,
    input nwrite,
    input nsel
    );

    reg [7:0]rom[0:32767];

    initial $readmemh("srcs/rom.txt", rom);

    assign data_bus = (nread == 'd0 && nsel == 'd0) ? rom[address_bus[13:0]] : 'dZ;

endmodule
