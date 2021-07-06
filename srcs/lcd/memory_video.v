`timescale 1ns / 1ns

module memory_video(
    input clock,
    input [15:0]address_bus,
    output [7:0]data_bus_read,
    input [7:0]data_bus_write,

    input nread,
    input nwrite
    );

    reg [7:0]vram[0:8191];
    integer i;

    initial
    begin
        for (i = 0; i < 8192; i++)
        begin
            vram[i] = 'd0;
        end
    end

    assign data_bus_read = (nread == 'd0 && address_bus[15:13] == 'b100) ? vram[address_bus[12:0]] : 8'bZ;

    always @(posedge clock)
    begin
        if (nwrite == 'd0 && address_bus[15:13] == 'b100)
        begin
            vram[address_bus[12:0]] <= data_bus_write;
        end else begin
            vram[address_bus[12:0]] <= vram[address_bus[12:0]];
        end
    end

endmodule

