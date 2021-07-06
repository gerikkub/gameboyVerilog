`timescale 1ns / 1ns

module memory_obj(
    input clock,
    input [15:0]address_bus,
    input [7:0]data_bus_write,
    output [7:0]data_bus_read,

    input nread,
    input nwrite
    );

    reg [7:0]objram[0:159];
    integer i;

    initial
    begin
        for (i = 0; i < 160; i++)
        begin
            objram[i] = 'd0;
        end
    end

    assign data_bus_read = nread == 'd0 &&
                           address_bus >= 'hFE00 &&
                           address_bus < 'hFEA0 ? objram[address_bus[7:0]] : 8'bZ;

    always @(posedge clock)
    begin
        if (nwrite == 'd0 &&
            address_bus >= 'hFE00 &&
            address_bus < 'hFEA0)
        begin
            objram[address_bus[7:0]] <= data_bus_write;
        end else begin
            objram[address_bus[7:0]] <= objram[address_bus[7:0]];
        end
    end

endmodule
