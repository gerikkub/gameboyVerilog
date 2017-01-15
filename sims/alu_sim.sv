`timescale 1ns / 1ps

module alu_sim(
    );

    parameter add_op = 0,
        adc_op = 1,
        sub_op = 2,
        sbc_op = 3,
        and_op = 4,
        xor_op = 5,
        or_op  = 6,
        cp_op  = 7;

    reg [3:0]in_A = 'd0;
    reg [3:0]in_B = 'd0;
    reg [2:0]alu_op = 'd0;
    reg in_C;

    wire [3:0]out;
    wire out_Z;
    wire out_C;

    alu a(
        .in_A(in_A),
        .in_B(in_B),
        .alu_op(alu_op),
        .in_C(in_C),
        .out(out),
        .out_Z(out_Z),
        .out_C(out_C)
    );

    task test_add;
        input dummy;
    begin
        // Add
        alu_op = add_op;
        
        in_A = 'd1;
        in_B = 'd2;
        in_C = 'd0;

        assert(out == 'd3);
        assert(out_Z == 'd0);
        assert(out_C == 'd0);

        in_C = 'd1;

        assert(out == 'd3);
        assert(out_Z == 'd0);
        assert(out_C == 'd0);

        in_A = 'hF;

        assert(out == 'd1);
        assert(out_Z == 'd0);
        assert(out_C == 'd1);

        in_B = 'd1;

        assert(out == 'd0);
        assert(out_Z == 'd1);
        assert(out_C == 'd1);

        in_A = 'd0;
        in_B = 'd0;

        assert(out == 'd0);
        assert(out_Z == 'd1);
        assert(out_C == 'd0);
    end
    endtask

    initial begin
        test_add('d0);
    end

endmodule
