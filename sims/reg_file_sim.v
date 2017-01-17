`timescale 1ns / 1ps

`include "srcs/reg_file.v"

`define CHECK(condition) if (!(condition)) begin $display("[%d] Failed: condition ", `__LINE__); end


module reg_file_sim();

    reg clock = 'd0;

    reg [2:0]out1_sel;
    reg [2:0]out2_sel;

    reg [7:0]data_in;
    reg [2:0]data_in_sel;
    reg write_reg;

    wire [7:0]out1;
    wire [7:0]out2;

    reg_file rf(
        .clock(clock),
        .out1_sel(out1_sel),
        .out2_sel(out2_sel),
        .data_in(data_in),
        .data_in_sel(data_in_sel),
        .write_reg(write_reg),
        .out1(out1),
        .out2(out2)
    );

    task run_clock;
        input dummy;
    begin
        #1
        clock = 'd1;
        #1
        clock = 'd0;
    end
    endtask

    task test_initial;
        input dummy;
        integer i;
    begin

        $display("Running Initial Value Test");

        i = 0;
        for (i = 0; i < 7; i++)
        begin
            out1_sel = i;

            #1

            `CHECK(out1 === 'd0)
        end
    end
    endtask

    task test_output;
        input [2:0]register;
        input [7:0]data;
    begin
        out1_sel = register;
        out2_sel = 'd0;

        #1

        `CHECK(out1 === data)

        #1

        out1_sel = 'd0;
        out2_sel = register;

        #1

        `CHECK(out2 === data)
    end
    endtask


    task test_write;
        input [2:0]register;
        input [7:0]data;
    begin

        data_in_sel = register;
        data_in = data;
        write_reg = 'd1;

        run_clock('d0);

        write_reg = 'd0;
    end
    endtask
       
    task test_outputs;
        input dummy;
    begin

        $display("Running Register File Test");

        test_write('d0, 'hAB);

        test_output('d0, 'hAB);

        test_write('d1, 'h46);
        test_write('d2, 'h9F);

        test_output('d2, 'h9F);
        test_output('d1, 'h46);

        test_write('d3, 'hFF);
        test_write('d4, 'hDE);
        test_write('d5, 'h99);

        test_output('d3, 'hFF);
        test_output('d4, 'hDE);
        test_output('d5, 'h99);

        test_write('d6, 'hFF); // Should stay at 0
        test_write('d7, 'h12);

        test_output('d6, 'd0);
        test_output('d7, 'h12);

        test_output('d0, 'hAB);

        test_write('d0, 'h37);

        test_output('d0, 'h37);

    end
    endtask

    initial begin

        $dumpfile("dump.vcd");
        $dumpvars;

        test_initial('d0);
        test_outputs('d0);

    end


endmodule
