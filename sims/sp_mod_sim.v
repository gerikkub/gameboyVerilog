`timescale 1ns / 1ps

`include "srcs/sp_mod.v"

`define CHECK(condition) if (!(condition)) begin $display("[%d] Failed: condition ", `__LINE__); end

`define CHECK_SP(value) \
`CHECK(sp_out === value)

module sp_mod_sim();

    reg clock = 'd0;
    reg reset = 'd1;

    reg [2:0]sp_sel = 'd0;
    reg [7:0]data_bus = 'd0;
    reg write_temp_buf = 'd0;

    wire [15:0]sp_out;

    sp_mod sp_m(
        .clock(clock),
        .reset(reset),
        .sp_sel(sp_sel),
        .data_bus(data_bus),
        .write_temp_buf(write_temp_buf),
        .sp(sp_out)
    );

    parameter sp_sel_sp = 'd0,
              sp_sel_sp_incr = 'd1,
              sp_sel_sp_decr = 'd2,
              sp_sel_data_bus = 'd3,
              sp_sel_data_bus_rel = 'd4;


    task run_cycle;
        input dummy;
    begin
        #1
        clock = 'd1;
        #1
        clock = 'd0;
    end
    endtask

    // Reset the sp module
    task reset_sp_mod;
        input dummy;
    begin
        reset = 'd0;

        run_cycle('d0);

        reset = 'd1;
    end
    endtask

    // Write addr to the sp register
    task write_sp;
        input [15:0]addr;
    begin
        data_bus = addr[7:0];
        write_temp_buf = 'd1;

        run_cycle('d0);

        data_bus = addr[15:8];
        write_temp_buf = 'd0;
        sp_sel = sp_sel_data_bus;

        run_cycle('d0);
    end
    endtask

    // Increment the sp register
    task write_sp_incr;
        input dummy;
    begin
        sp_sel = sp_sel_sp_incr;

        run_cycle('d0);

        sp_sel = sp_sel_sp;
    end
    endtask

    // Decrement the sp register
    task write_sp_decr;
        input dummy;
    begin
        sp_sel = sp_sel_sp_decr;

        run_cycle('d0);

        sp_sel = sp_sel_sp;
    end
    endtask

    // Write relative value to sp
    task write_sp_data_bus_rel;
        input [7:0]rel;
    begin
        data_bus = rel;
        sp_sel = sp_sel_data_bus_rel;

        run_cycle('d0);

        sp_sel = sp_sel_sp;
    end
    endtask

    task test_write_sp;
        input dummy;
    begin
        $display("Running Write SP Test");

        write_sp('hABCD);
        `CHECK_SP('hABCD);

        reset_sp_mod('d0);
        `CHECK_SP('h0000);

        write_sp('hFFFF);
        `CHECK_SP('hFFFF);
    end
    endtask

    task test_sp_incr;
        input dummy;
    begin
        $display("Running Incr SP Test");

        write_sp('h0000);
        `CHECK_SP('h0000);

        write_sp_incr('d0);
        `CHECK_SP('h0001);

        write_sp_incr('d0);
        `CHECK_SP('h0002);

        write_sp('h00FF);
        write_sp_incr('d0);
        `CHECK_SP('h0100);

        write_sp('hFFFE);
        write_sp_incr('d0);
        `CHECK_SP('hFFFF);

        write_sp_incr('d0);
        `CHECK_SP('h0000);
    end
    endtask

    task test_sp_decr;
        input dummy;
    begin
        $display("Running Decr SP Test");

        write_sp('h0002);
        `CHECK_SP('h0002);

        write_sp_decr('d0);
        `CHECK_SP('h0001);

        write_sp_decr('d0);
        write_sp_decr('d0);
        `CHECK_SP('hFFFF);

        write_sp('hABCD);
        write_sp_decr('d0);
        write_sp_decr('d0);
        write_sp_decr('d0);
        write_sp_decr('d0);
        `CHECK_SP('hABC9);

        write_sp('h0100);
        write_sp_decr('d0);
        `CHECK_SP('h00FF);
    end
    endtask

    task test_sp_rel;
        input dummy;
    begin
        $display("Running SP Rel Test");

        write_sp('h4567);
        `CHECK_SP('h4567);

        write_sp_data_bus_rel('h03);
        `CHECK_SP('h456A);

        write_sp_data_bus_rel('hFF);
        `CHECK_SP('h4569);

        write_sp_data_bus_rel('h7F);
        `CHECK_SP('h45E8);

        write_sp_data_bus_rel('h80);
        `CHECK_SP('h4568);

        write_sp('h0001);
        write_sp_data_bus_rel('hFE);
        `CHECK_SP('hFFFF);

        write_sp_data_bus_rel('hA);
        `CHECK_SP('h0009);

        write_sp('h80);
        write_sp_data_bus_rel('h80);
        `CHECK_SP('h0000);

        write_sp('h80);
        write_sp_data_bus_rel('h7F);
        `CHECK_SP('h00FF);

        write_sp_data_bus_rel('h1);
        `CHECK_SP('h0100);
    end
    endtask

    initial
    begin
        
        $dumpfile("dump.vcd");
        $dumpvars;

        reset_sp_mod('d0);

        test_write_sp('d0);
        test_sp_incr('d0);
        test_sp_decr('d0);
        test_sp_rel('d0);
    end

endmodule


