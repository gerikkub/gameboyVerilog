`timescale 1ns / 1ns

module memory_wram(
    input clock,

    input [15:0]address_bus,

    inout [7:0]data_bus,

    input nread,
    input nwrite,
    input nsel
    );

    reg [7:0]wram[0:8191];
    integer i;

    initial
    begin
        for (i = 0; i < 8192; i++)
        begin
            wram[i] = 'd0;
        end
    end

    assign data_bus = (nread == 'd0 && nsel == 'd0) ? wram[address_bus[12:0]] : 8'bZ;

    always @(posedge clock)
    begin
        if (nwrite == 'd0 && nsel == 'd0)
        begin
            wram[address_bus[12:0]] <= data_bus;
        end else begin
            wram[address_bus[12:0]] <= wram[address_bus[12:0]];
        end
    end

endmodule
