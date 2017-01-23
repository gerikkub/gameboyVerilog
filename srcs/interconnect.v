`timescale 1ns / 1ps

`include "srcs/core.v"
`include "srcs/memory_rom.v"

module interconnect(
    input clock,
    input reset
    );

    wire [15:0]address;
    wire [7:0]data;
    wire nread;
    wire nwrite;

    wire nsel;

    assign nsel = nread & nwrite;

    core core(
        .clock(clock),
        .reset(reset),
        .db_address(address),
        .db_data(data),
        .db_nread(nread),
        .db_nwrite(nwrite)
    );

    memory_rom rom(
        .clock(clock),
        .address_bus(address),
        .data_bus(data),
        .nread(nread),
        .nwrite(nwrite),
        .nsel(nsel)
    );

endmodule

