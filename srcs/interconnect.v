`timescale 1ns / 1ns

`include "srcs/core.v"
`include "srcs/memory_rom.v"
`include "srcs/memory_hram.v"
`include "srcs/memory_wram.v"


module interconnect(
    input clock,
    input reset
    );

    wire [15:0]address;
    wire [7:0]data;
    wire nread;
    wire nwrite;

    wire nsel_rom;
    wire nsel_hram;
    wire nsel_wram;

    assign nsel_rom = (address < 'h8000) ? (nread & nwrite) : 'd1;
    assign nsel_hram = ((address >= 'hFF80) && (address != 'hFFFF)) ? (nread & nwrite) : 'd1;
    assign nsel_wram = (address[15:13] == 'b110) ? (nread & nwrite) : 'd1;

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
        .nsel(nsel_rom)
    );

    memory_hram hram(
        .clock(clock),
        .address_bus(address),
        .data_bus(data),
        .nread(nread),
        .nwrite(nwrite),
        .nsel(nsel_hram)
    );

    memory_wram wram(
        .clock(clock),
        .address_bus(address),
        .data_bus(data),
        .nread(nread),
        .nwrite(nwrite),
        .nsel(nsel_wram)
    );

    always @(posedge clock)
    begin
        if (address == 'hFF01 &&
            nwrite == 'd0)
        begin
            $display("%c", data);
        end
    end
    

endmodule

