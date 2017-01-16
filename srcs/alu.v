`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/05/2016 08:59:20 PM
// Design Name: 
// Module Name: alu
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module alu(
    input [3:0] in_A,
    input [3:0] in_B,
    input [2:0] alu_op,
    input in_C,

    output [3:0] out,
    output out_Z,
    output out_C
    );

    parameter add_op = 0,
              adc_op = 1,
              sub_op = 2,
              sbc_op = 3,
              and_op = 4,
              xor_op = 5,
              or_op  = 6,
              cp_op  = 7;

    wire [4:0] addResult;
    wire [4:0] adcResult;
    wire [4:0] subResult;
    wire [4:0] sbcResult;
    wire [3:0] andResult;
    wire [3:0] xorResult;
    wire [3:0] orResult;
    wire [4:0] cpResult;

    reg [3:0] result;
    reg c_result;


    // ALU Ops
    assign addResult = in_A + in_B;
    assign adcResult = in_A + in_B + in_C;
    assign subResult = in_A - in_B;
    assign sbcResult = in_A - in_B - in_C;
    assign andResult = in_A & in_B;
    assign xorResult = in_A ^ in_B;
    assign orResult = in_A | in_B;
    assign cpResult = in_A - in_B - in_C;

    // Assign result
    always @(*)
    begin
        case (alu_op)
        add_op: begin
            result <= addResult[3:0];
            c_result <= addResult[4];
        end

        adc_op: begin
            result <= adcResult[3:0];
            c_result <= adcResult[4];
        end

        sub_op: begin
            result <= subResult[3:0];
            c_result <= subResult[4];
        end

        sbc_op: begin
           result <= sbcResult[3:0];
           c_result <= sbcResult[4];
        end

        and_op: begin
           result <= andResult;
           c_result <= 'd0;
        end

        xor_op: begin
            result <= xorResult;
            c_result <= 'd0;
        end

        or_op: begin
            result <= orResult;
            c_result <= 'd0;
        end

        cp_op: begin
            result <= cpResult[3:0];
            c_result <= cpResult[4];
        end
        endcase
    end

    assign out = (alu_op == cp_op) ? in_A : result;

    // Assign Flags
    assign out_Z = result == 'd0;
    assign out_C = c_result;

endmodule
