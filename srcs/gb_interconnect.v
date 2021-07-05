`timescale 1ns / 1ns

`include "srcs/core.v"
//`include "srcs/memory_rom.v"
`include "srcs/memory_hram.v"
`include "srcs/memory_wram.v"
`include "srcs/gb_timer.v"
`include "srcs/lcd/lcd.v"


module gb_interconnect(
    input clock,
    input reset,
    output [7:0]data_out,
    output [15:0]address_out,

    // ROM signals
    output nwrite_out,
    output nread_out,
    output nsel_rom_out,
    input [7:0]rom_data,

    // Video Signals
    output [1:0]color_out,
    output px_valid_out,
    output [7:0]x_pos_out,
    output [7:0]y_pos_out
    );

    wire [15:0]address;
    wire [7:0]data;
    wire nread;
    wire nwrite;

    wire nsel_rom;
    wire nsel_hram;
    wire nsel_wram;

    wire int_vblank;
    wire int_stat;
    wire int_timer;
    wire int_serial;
    wire int_joypad;

    assign nsel_rom = (address < 'h8000) ? (nread & nwrite) : 'd1;
    assign nsel_hram = ((address >= 'hFF80) && (address != 'hFFFF)) ? (nread & nwrite) : 'd1;
    assign nsel_wram = (address[15:13] == 'b110) ? (nread & nwrite) : 'd1;

    assign int_vblank = 'b0;
    assign int_stat = 'b0;
    assign int_serial = 'b0;
    assign int_joypad = 'b0;

    assign data_out = data;
    assign address_out = address;
    assign nread_out = nread;
    assign nwrite_out = nwrite;
    assign nsel_rom_out = nsel_rom;

    assign data = (nread == 'd0 && nsel_rom == 'd0) ? rom_data : 8'bZ;

    core core(
        .clock(clock),
        .reset(reset),
        .db_address(address),
        .db_data(data),
        .db_nread(nread),
        .db_nwrite(nwrite),
        .int_vblank(int_vblank),
        .int_stat(int_stat),
        .int_timer(int_timer),
        .int_serial(int_serial),
        .int_joypad(int_joypad)
    );

/*
    memory_rom rom(
        .clock(clock),
        .address_bus(address),
        .data_bus(data),
        .nread(nread),
        .nwrite(nwrite),
        .nsel(nsel_rom)
    );
    */

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

    gb_timer timer(
        .clock(clock),
        .nreset(reset),
        .reset_div('d0),
        .db_data(data),
        .db_address(address),
        .nread(nread),
        .nwrite(nwrite),
        .int_timer(int_timer)
    );

    lcd lcd(
        .clock(clock),
        .nreset(reset),
        .db_data(data),
        .db_address(address),
        .color_out(color_out),
        .px_valid_out(px_valid_out),
        .x_pos_out(x_pos_out),
        .y_pos_out(y_pos_out)
    );

endmodule

