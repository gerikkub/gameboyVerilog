`timescale 1ns / 1ps

`include "srcs/pc_mod.v"

`define CHECK(condition) if (!(condition)) begin $display("[%d] Failed: condition ", `__LINE__); end

`define CHECK_PC(value) \
`CHECK(pc_out === value)


`define CHECK_OFFSET(value) \
`CHECK(pc_w_offset_out === value)

module pc_mod_sim();

    reg clock = 'd0;
    reg reset = 'd1;

    reg [2:0]rst_pc_in = 'd0;
    reg [2:0]int_pc_in = 'd0;
    reg [7:0]data_bus = 'd0;
    reg [2:0]pc_sel = 'd0;

    reg [1:0]offset_sel = 'd0;

    reg write_temp_buf = 'd0;

    wire [15:0]pc_w_offset_out;
    wire [15:0]pc_out;

    pc_mod pc_m(
        .clock(clock),
        .reset(reset),
        .rst_pc_in(rst_pc_in),
        .int_pc_in(int_pc_in),
        .data_bus(data_bus),
        .pc_sel(pc_sel),
        .offset_sel(offset_sel),
        .write_temp_buf(write_temp_buf),
        .pc_w_offset(pc_w_offset_out),
        .pc(pc_out)
    );

    parameter pc_sel_pc = 'd0,
              pc_sel_pc_incr = 'd1,
              pc_sel_rst_mod = 'd2,
              pc_sel_int_mod = 'd3,
              pc_sel_zero = 'd4,
              pc_sel_data_bus = 'd5,
              pc_sel_data_bus_rel = 'd6;

    parameter offset_sel_offset = 'd0,
              offset_sel_offset_incr = 'd1,
              offset_sel_zero = 'd0;


    task run_cycle;
        input dummy;
    begin
        #1
        clock = 'd1;
        #1
        clock = 'd0;
    end
    endtask

    // Reset the pc module
    task reset_pc_mod;
        input dummy;
    begin
        reset = 'd0;

        run_cycle('d0);

        reset = 'd1;
    end
    endtask

    // Write addr to the pc register
    task write_pc;
        input [15:0]addr;
    begin

        data_bus = addr[7:0];
        write_temp_buf = 'd1;

        run_cycle('d0);

        data_bus = addr[15:8];
        write_temp_buf = 'd0;
        pc_sel = pc_sel_data_bus;

        run_cycle('d0);
    end
    endtask

    task write_pc_incr;
        input dummy;
    begin
        pc_sel = pc_sel_data_bus_rel;

        run_cycle('d0);
    end
    endtask

    // Write a rst instruction address to the pc register
    task write_pc_rst;
        input [7:0]rst_addr;
    begin
        rst_pc_in = rst_addr[5:3];
        pc_sel = pc_sel_rst_mod;

        run_cycle('d0);
    end
    endtask

    // Write an int instruction address to the pc register
    task write_pc_int;
        input [7:0]int_addr;
    begin
        int_pc_in = int_addr[5:3];
        pc_sel = pc_sel_int_mod;

        run_cycle('d0);
    end
    endtask

    // Write a relative address to the pc register
    task write_pc_data_bus_rel;
        input [7:0]rel_addr;
    begin
        data_bus = rel_addr;
        pc_sel = pc_sel_data_bus_rel;

        run_cycle('d0);
    end
    endtask

    // Increment the offset register
    task offset_incr;
        input dummy;
    begin
        offset_sel = offset_sel_offset_incr;

        run_cycle('d0);
    end
    endtask

    // Reset the offset register
    task offset_reset;
        input dummy;
    begin
        offset_sel = offset_sel_zero;

        run_cycle('d0);
    end
    endtask

    task test_write_pc;
        input dummy;
    begin

        $display("Running Write PC Test");

        write_pc('hABCD);

        `CHECK_PC('hABCD);

        write_pc('h0000);

        `CHECK_PC('h0000);

        write_pc('hFFFF);

        `CHECK_PC('hFFFF);

        reset_pc_mod('d0);

        `CHECK_PC('h0000);
    end
    endtask

    task test_pc_rst;
        input dummy;
    begin

        $display("Running Rst Test");

        write_pc_rst('h0);
        `CHECK_PC('h0);

        write_pc_rst('h8);
        `CHECK_PC('h8);

        write_pc_rst('h10);
        `CHECK_PC('h10);

        write_pc_rst('h18);
        `CHECK_PC('h18);

        write_pc_rst('h20);
        `CHECK_PC('h20);

        write_pc_rst('h28);
        `CHECK_PC('h28);

        write_pc_rst('h30);
        `CHECK_PC('h30);

        write_pc_rst('h38);
        `CHECK_PC('h38);
    end
    endtask

    task test_pc_int;
        input dummy;
    begin

        $display("Running Int Test");

        write_pc_int('h40);
        `CHECK_PC('h40);

        write_pc_int('h48);
        `CHECK_PC('h48);

        write_pc_int('h50);
        `CHECK_PC('h50);

        write_pc_int('h58);
        `CHECK_PC('h58);

        write_pc_int('h60);
        `CHECK_PC('h60);
    end
    endtask

    task test_pc_rel;
        input dummy;
    begin
        $display("Running Rel Test");

        write_pc('h4567);
        `CHECK_PC('h4567);

        write_pc_data_bus_rel('h03);
        `CHECK_PC('h456A);

        write_pc_data_bus_rel('hFF);
        `CHECK_PC('h4569);

        write_pc_data_bus_rel('h7F);
        `CHECK_PC('h45E8);

        write_pc_data_bus_rel('h80);
        `CHECK_PC('h4568);

        offset_reset('d0);
        offset_incr('d0);
        offset_incr('d0);

        write_pc_data_bus_rel('h2);
        `CHECK_PC('h456A);

        write_pc_data_bus_rel('hFC);
        `CHECK_PC('h4566);

        write_pc('h0001);
        write_pc_data_bus_rel('hFE);
        `CHECK_PC('hFFFF);

        write_pc_data_bus_rel('hA);
        `CHECK_PC('h0009);

        write_pc('h80);
        write_pc_data_bus_rel('h80);
        `CHECK_PC('h0000);

        write_pc('h80);
        write_pc_data_bus_rel('h7F);
        `CHECK_PC('h00FF);

        write_pc_data_bus_rel('h1);
        `CHECK_PC('h0100);
    end
    endtask

    task test_offset;
        input dummy;
    begin
        $display("Running Offset Test");

        write_pc('h0100);

        offset_reset('d0);
        `CHECK_OFFSET('h0100);

        offset_incr('d0);
        `CHECK_OFFSET('h0101);

        offset_incr('d0);
        `CHECK_OFFSET('h0102);

        offset_incr('d0);
        `CHECK_OFFSET('h0103);

        offset_incr('d0); // Should overflow
        `CHECK_OFFSET('h0100);

        write_pc('hFFFE);
        offset_reset('d0);
        offset_incr('d0);
        `CHECK_OFFSET('hFFFF);

        offset_incr('d0);
        `CHECK_OFFSET('h0000);

        offset_incr('d0);
        `CHECK_OFFSET('h0001);
    end
    endtask

    task test_pc_incr;
        input dummy;
    begin
        $display("Running PC Incr Test");

        write_pc('h0FFC);
        offset_reset('d0);
        offset_incr('d0);
        offset_incr('d0);
        `CHECK_OFFSET('h0FFE);

        write_pc_incr('d0);
        `CHECK_OFFSET('h0FFF);

        offset_reset('d0);
        offset_incr('d0);

        write_pc_incr('d0);
        `CHECK_OFFSET('h1001);

        write_pc('hFFFE);
        offset_reset('d0);
        offset_incr('d0);
        offset_incr('d0);
        offset_incr('d0);

        write_pc_incr('d0);
        `CHECK_OFFSET('h0002);
    end
    endtask

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars;

        test_write_pc('d0);
        test_pc_rst('d0);
        test_pc_int('d0);
        test_pc_rel('d0);
        test_offset('d0);
        test_pc_incr('d0);

    end

endmodule
