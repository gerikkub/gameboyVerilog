`timescale 1ns / 1ns

module memory_hram(
    input clock,

    input [15:0]address_bus,

    inout [7:0]data_bus,

    input nread,
    input nwrite,
    input nsel
    );

    reg [7:0]hram[0:126];
    integer i;

    initial
    begin
        for (i = 0; i < 127; i++)
        begin
            hram[i] = 'd0;
        end
    end

    assign data_bus = (nread == 'd0 && nsel == 'd0) ? hram[address_bus[6:0]] : 8'bZ;

    always @(posedge clock)
    begin
        if (nwrite == 'd0 && nsel == 'd0)
        begin
            hram[address_bus[6:0]] <= data_bus;
        end else begin
            hram[address_bus[6:0]] <= hram[address_bus[6:0]];
        end
    end

endmodule
