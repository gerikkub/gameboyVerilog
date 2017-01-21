`timescale 1ns / 1ps

`include "srcs/memory_rom.v"

`define CHECK(condition) if (!(condition)) begin $display("[%d] Failed: condition ", `__LINE__); end

`define CHECK_ROM(value) \
`CHECK(data_bus === value)

module memory_rom_sim();

    reg clock = 'd0;

    reg [15:0]address_bus = 'd0;
    reg nread = 'd1;
    reg nwrite = 'd1;
    reg nsel = 'd1;

    wire [7:0]data_bus;

    memory_rom rom(
        .clock(clock),
        .address_bus(address_bus),
        .nread(nread),
        .nwrite(nwrite),
        .nsel(nsel),
        .data_bus(data_bus)
    );

    task read_rom;
        input [13:0]address;
        input nvalid;
    begin
        address_bus = address;
        nsel = nvalid;
        nread = nvalid;
        #1
        clock = 'd0;
    end
    endtask

    task test_read;
        input dummy;
    begin
        $display("Running Read Test");

        read_rom('d0, 'd0);
        `CHECK_ROM('hAB)

        read_rom('h10, 'd0);
        `CHECK_ROM('h88)

        read_rom('h0, 'd1);
        `CHECK_ROM(8'bZZZZZZZZ)
    end
    endtask

    initial
    begin
        
        $dumpfile("dump.vcd");
        $dumpvars;

        test_read('d0);
    end

endmodule



