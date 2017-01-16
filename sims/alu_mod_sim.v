`timescale 1ns / 1ps

`include "srcs/alu_mod.v"

`define CHECK(condition) if (!(condition)) begin $display("[%d] Failed: condition ", `__LINE__); end

`define CHECKALL(data_value, c_value, z_value, h_value) \
`CHECK(alu_result == data_value) \
`CHECK(c_flag_result == c_value) \
`CHECK(z_flag_result == z_value) \
`CHECK(h_flag_result == h_value)


module alu_mod_sim();

    parameter add_op = 0,
        adc_op = 1,
        sub_op = 2,
        sbc_op = 3,
        and_op = 4,
        xor_op = 5,
        or_op  = 6,
        cp_op  = 7;

    reg clock = 'd0;

    reg [7:0]in_B = 'd0;
    reg [7:0]in_A = 'd1;
    reg write_A = 'd0;
    reg [2:0]alu_op = 'd0;
    reg [3:0]in_flags = 'd0;

    reg [7:0]alu_result = 'd0;
    reg c_flag_result = 'd0;
    reg z_flag_result = 'd0;
    reg h_flag_result = 'd0;

    wire [7:0]out;
    wire [3:0]out_flags;
    wire [7:0]a_reg = 'd0;

    wire out_c_flag;
    wire out_z_flag;
    wire out_h_flag;

    alu_mod alu(
        .clock(clock),
        .in_B(in_B),
        .in_A(in_A),
        .alu_op(alu_op),
        .in_C(in_flags[0]),
        .out(out),
        .out_flags(out_flags)
        );

    assign out_c_flag = out_flags[0];
    assign out_z_flag = out_flags[3];
    assign out_h_flag = out_flags[1];

    task set_A;
        input [7:0]A;
    begin
        in_A = A;
    end
    endtask

    task run_cycle;
        input [7:0]data;
        input c_flag;
    begin
        
        in_B = data;
        in_flags = {3'd0, c_flag};

        #1
        clock = 'd1;
        #1
        clock = 'd0;
        #1

        alu_result = out;
        c_flag_result = out_c_flag;
        z_flag_result = out_z_flag;
        h_flag_result = out_h_flag;
        clock = 'd1;
        #1
        clock = 'd0;

    end
    endtask

    task test_add;
        input dummy;
    begin

        $display("Running Add Test");

        alu_op = add_op;

        set_A('d4);
        run_cycle('d5, 'd0);

        `CHECKALL('d9, 'd0, 'd0, 'd0)

        run_cycle('hF, 'd0);

        `CHECKALL('h13, 'd0, 'd0, 'd1)

        run_cycle('h10, 'd0);

        `CHECKALL('h14, 'd0, 'd0, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('h3, 'd1, 'd0, 'd1)

        run_cycle('hFC, 'd0);

        `CHECKALL('h00, 'd1, 'd1, 'd1)

        set_A('h30);
        run_cycle('h22, 'd0);

        `CHECKALL('h52, 'd0, 'd0, 'd0)

        run_cycle('hF0, 'd0);

        `CHECKALL('h20, 'd1, 'd0, 'd0)

        run_cycle('hD0, 'd0);

        `CHECKALL('h00, 'd1, 'd1, 'd0)

        set_A('h0);
        run_cycle('h0, 'd0);

        `CHECKALL('h0, 'd0, 'd1, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('hFF, 'd0, 'd0, 'd0)
    end
    endtask

    task test_adc;
        input dummy;
    begin

        $display("Running Adc Test");

        alu_op = adc_op;

        set_A('d4);
        run_cycle('d5, 'd0);

        `CHECKALL('d9, 'd0, 'd0, 'd0)

        run_cycle('hF, 'd0);

        `CHECKALL('h13, 'd0, 'd0, 'd1)

        run_cycle('h10, 'd0);

        `CHECKALL('h14, 'd0, 'd0, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('h3, 'd1, 'd0, 'd1)

        run_cycle('hFC, 'd0);

        `CHECKALL('h00, 'd1, 'd1, 'd1)

        set_A('h30);
        run_cycle('h22, 'd0);

        `CHECKALL('h52, 'd0, 'd0, 'd0)

        run_cycle('hF0, 'd0);

        `CHECKALL('h20, 'd1, 'd0, 'd0)

        run_cycle('hD0, 'd0);

        `CHECKALL('h00, 'd1, 'd1, 'd0)

        set_A('h0);
        run_cycle('h0, 'd0);

        `CHECKALL('h0, 'd0, 'd1, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('hFF, 'd0, 'd0, 'd0)

        
        set_A('d4);
        run_cycle('d5, 'd1);
        
        `CHECKALL('d10, 'd0, 'd0, 'd0)

        run_cycle('hF, 'd1);

        `CHECKALL('h14, 'd0, 'd0, 'd1)

        run_cycle('h10, 'd1);

        `CHECKALL('h15, 'd0, 'd0, 'd0)

        run_cycle('hFF, 'd1);

        `CHECKALL('h4, 'd1, 'd0, 'd1)

        run_cycle('hFB, 'd1);

        `CHECKALL('h00, 'd1, 'd1, 'd1)

        set_A('h30);
        run_cycle('h22, 'd1);

        `CHECKALL('h53, 'd0, 'd0, 'd0)

        run_cycle('hF0, 'd1);

        `CHECKALL('h21, 'd1, 'd0, 'd0)

        run_cycle('hCF, 'd1);

        `CHECKALL('h00, 'd1, 'd1, 'd1)

        set_A('h0);

        run_cycle('hFF, 'd1);

        `CHECKALL('h00, 'd1, 'd1, 'd1)
    end
    endtask

    task test_sub;
        input dummy;
    begin

        $display("Running Sub Test");

        alu_op = sub_op;

        set_A('h23);
        run_cycle('d3, 'd0);

        `CHECKALL('h20, 'd0, 'd0, 'd0)

        run_cycle('d4, 'd0);

        `CHECKALL('h1F, 'd0, 'd0, 'd1)

        run_cycle('h11, 'd0);

        `CHECKALL('h12, 'd0, 'd0, 'd0)

        run_cycle('h23, 'd0);

        `CHECKALL('h00, 'd0, 'd1, 'd0)

        run_cycle('h24, 'd0);

        `CHECKALL('hFF, 'd1, 'd0, 'd1)

        set_A('h0);

        run_cycle('h1, 'd0);

        `CHECKALL('hFF, 'd1, 'd0, 'd1)

        run_cycle('h0, 'd0);

        `CHECKALL('h00, 'd0, 'd1, 'd0)
    end
    endtask

    task test_sbc;
        input dummy;
    begin
        
        $display("Running Sbc Test");

        alu_op = sbc_op;

        set_A('h23);
        run_cycle('d3, 'd0);

        `CHECKALL('h20, 'd0, 'd0, 'd0)

        run_cycle('d4, 'd0);

        `CHECKALL('h1F, 'd0, 'd0, 'd1)

        run_cycle('h11, 'd0);

        `CHECKALL('h12, 'd0, 'd0, 'd0)

        run_cycle('h23, 'd0);

        `CHECKALL('h00, 'd0, 'd1, 'd0)

        run_cycle('h24, 'd0);

        `CHECKALL('hFF, 'd1, 'd0, 'd1)

        set_A('h0);

        run_cycle('h1, 'd0);

        `CHECKALL('hFF, 'd1, 'd0, 'd1)

        run_cycle('h0, 'd0);

        `CHECKALL('h00, 'd0, 'd1, 'd0)


        set_A('h23);
        run_cycle('d2, 'd1);

        `CHECKALL('h20, 'd0, 'd0, 'd0)

        run_cycle('d3, 'd1);

        `CHECKALL('h1F, 'd0, 'd0, 'd1)

        run_cycle('h10, 'd1);

        `CHECKALL('h12, 'd0, 'd0, 'd0)

        run_cycle('h22, 'd1);

        `CHECKALL('h00, 'd0, 'd1, 'd0)

        run_cycle('h23, 'd1);

        `CHECKALL('hFF, 'd1, 'd0, 'd1)

        set_A('h0);

        run_cycle('h0, 'd1);

        `CHECKALL('hFF, 'd1, 'd0, 'd1)
    end
    endtask

    task test_and;
        input dummy;
    begin
        
        $display("Running And Test");

        alu_op = and_op;

        set_A('h5C);
        run_cycle('h0, 'd0);

        `CHECKALL('h0, 'd0, 'd1, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('h5C, 'd0, 'd0, 'd0)

        run_cycle('hF0, 'd0);

        `CHECKALL('h50, 'd0, 'd0, 'd0)

        run_cycle('h0F, 'd0);

        `CHECKALL('h0C, 'd0, 'd0, 'd0)
    end
    endtask

    task test_xor;
        input dummy;
    begin

        $display("Running Xor Test");

        alu_op = xor_op;

        set_A('h00);

        run_cycle('h00, 'd0);

        `CHECKALL('h0, 'd0, 'd1, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('hFF, 'd0, 'd0, 'd0)

        set_A('hFF);

        run_cycle('hFF, 'd0);

        `CHECKALL('h00, 'd0, 'd1, 'd0)

        set_A('h5C);
        run_cycle('h0, 'd0);

        `CHECKALL('h5C, 'd0, 'd0, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('hA3, 'd0, 'd0, 'd0)

        run_cycle('hF0, 'd0);

        `CHECKALL('hAC, 'd0, 'd0, 'd0)

        run_cycle('h0F, 'd0);

        `CHECKALL('h53, 'd0, 'd0, 'd0)
    end
    endtask

    task test_or;
        input dummy;
    begin

        $display("Running Or Test");

        alu_op = or_op;

        set_A('h00);

        run_cycle('h00, 'd0);

        `CHECKALL('h0, 'd0, 'd1, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('hFF, 'd0, 'd0, 'd0)

        set_A('hFF);

        run_cycle('hFF, 'd0);

        `CHECKALL('hFF, 'd0, 'd0, 'd0)

        set_A('h5C);
        run_cycle('h0, 'd0);

        `CHECKALL('h5C, 'd0, 'd0, 'd0)

        run_cycle('hFF, 'd0);

        `CHECKALL('hFF, 'd0, 'd0, 'd0)

        run_cycle('hF0, 'd0);

        `CHECKALL('hFC, 'd0, 'd0, 'd0)

        run_cycle('h0F, 'd0);

        `CHECKALL('h5F, 'd0, 'd0, 'd0)
    end
    endtask

    task test_cp;
        input dummy;
    begin

        $display("Running Cp Test");

        alu_op = cp_op;

        set_A('h23);
        run_cycle('d3, 'd0);

        `CHECKALL('h23, 'd0, 'd0, 'd0)

        run_cycle('d4, 'd0);

        `CHECKALL('h23, 'd0, 'd0, 'd1)

        run_cycle('h11, 'd0);

        `CHECKALL('h23, 'd0, 'd0, 'd0)

        run_cycle('h23, 'd0);

        `CHECKALL('h23, 'd0, 'd1, 'd0)

        run_cycle('h24, 'd0);

        `CHECKALL('h23, 'd1, 'd0, 'd1)

        set_A('h0);

        run_cycle('h1, 'd0);

        `CHECKALL('h0, 'd1, 'd0, 'd1)

        run_cycle('h0, 'd0);

        `CHECKALL('h0, 'd0, 'd1, 'd0)

    end
    endtask

    initial
    begin
        
        $dumpfile("dump.vcd");
        $dumpvars;

        test_add('d0);
        test_adc('d0);
        test_sub('d0);
        test_sbc('d0);
        test_and('d0);
        test_xor('d0);
        test_or('d0);
        test_cp('d0);

        $finish;
    end

endmodule

