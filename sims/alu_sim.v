`timescale 1ns / 1ps

`include "srcs/alu.v"

`define CHECK(condition) if (!(condition)) begin $display("[%d] Failed: condition ", `__LINE__); end

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

        $display("Running Add Test");
        alu_op = add_op;
        
        in_A = 'd1;
        in_B = 'd2;
        in_C = 'd0;

        #1

        `CHECK(out == 'd3)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'd3)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hF;

        #1

        `CHECK(out == 'd1)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_B = 'd1;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd1)

        in_A = 'd0;
        in_B = 'd0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)
        
    end
    endtask

    task test_adc;
        input dummy;
    begin
        // Adc
        
        $display("Running Adc Test");

        alu_op = adc_op;

        in_A = 'd1;
        in_B = 'd2;
        in_C = 'd0;

        #1

        `CHECK(out == 'd3)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'd4)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hF;

        #1

        `CHECK(out == 'd2)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_A = 'hD;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd1)

        in_A = 'h0;
        in_B = 'h0;

        #1

        `CHECK(out == 'd1)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_C = 'h0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

    end
    endtask

    task test_sub;
        input dummy;
    begin
        // Sub

        $display("Running Sub Test");

        alu_op = sub_op;

        in_A = 'd2;
        in_B = 'd1;
        in_C = 'd0;
        
        #1

        `CHECK(out == 'd1)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'd1)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'd0;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_C = 'd0;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_A = 'hC;
        in_B = 'hC;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

    end
    endtask

    task test_sbc;
        input dummy;
    begin
        // Sbc

        $display("Running Sbc Test");

        alu_op = sbc_op;

        in_A = 'd2;
        in_B = 'd1;
        in_C = 'd0;

        #1

        `CHECK(out == 'd1)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'd0;

        #1

        `CHECK(out == 'hE)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_C = 'd0;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_A = 'hC;
        in_B = 'hC;
        in_C = 'd0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

    end
    endtask

    task test_and;
        input dummy;
    begin
        // And
        
        $display("Running And Test");

        alu_op = and_op;

        in_A = 'd0;
        in_B = 'd0;
        in_C = 'd0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'hF;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'h0;
        in_B = 'hF;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'hF;
        in_B = 'hA;

        #1

        `CHECK(out == 'hA)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_B = 'h5;

        #1

        `CHECK(out == 'h5)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hA;
        in_B = 'hF;

        #1

        `CHECK(out == 'hA)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'h5;

        #1

        `CHECK(out == 'h5)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hC;
        in_B = 'h9;

        #1

        `CHECK(out == 'h8)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hF;
        in_B = 'hF;
        in_C = 'd0;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'h0;
        in_B = 'h0;
        in_C = 'd1;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)
    end
    endtask

    task test_xor;
        input dummy;
    begin
        // Xor
        
        $display("Running Xor Test");

        alu_op = xor_op;

        in_A = 'h0;
        in_B = 'h0;
        in_C = 'h0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'hF;
        in_B = 'hF;
        
        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'h0;
        in_B = 'hF;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hF;
        in_B = 'h0;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hA;
        in_B = 'hC;

        #1

        `CHECK(out == 'h6)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'h9;
        in_B = 'h6;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

    end
    endtask

    task test_or;
        input dummy;
    begin
        // Or

        $display("Running Or Test");

        alu_op = or_op;

        in_A = 'h0;
        in_B = 'h0;
        in_C = 'd0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'hF;
        in_B = 'h0;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'h0;
        in_B = 'hF;

        #1

        `CHECK(out == 'hF)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hA;
        in_B = 'h3;

        #1

        `CHECK(out == 'hB)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_A = 'hC;
        in_B = 'h1;

        #1

        `CHECK(out == 'hD)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

    end
    endtask

    task test_cp;
        input dummy;
    begin
        // Cp

        $display("Running Cp Test");

        alu_op = cp_op;

        in_A = 'd2;
        in_B = 'd1;
        in_C = 'd0;

        #1

        `CHECK(out == 'd2)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd0)

        in_C = 'd1;

        #1

        `CHECK(out == 'd2)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)

        in_A = 'd0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_C = 'd0;

        #1

        `CHECK(out == 'd0)
        `CHECK(out_Z == 'd0)
        `CHECK(out_C == 'd1)

        in_A = 'hC;
        in_B = 'hC;
        in_C = 'd0;

        #1

        `CHECK(out == 'hC)
        `CHECK(out_Z == 'd1)
        `CHECK(out_C == 'd0)




    end
    endtask


    initial begin
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
