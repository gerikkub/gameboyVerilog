`timescale 1ns / 1ns

`include "srcs/alu.v"

module alu_mod(
    input clock,

    input [7:0]in_A,
    input [7:0]in_B,
    input [2:0]alu_op,
    input in_C,
    
    output [7:0]out,
    output [3:0]out_flags
);

    parameter add_op = 0,
              adc_op = 1,
              sub_op = 2,
              sbc_op = 3,
              and_op = 4,
              xor_op = 5,
              or_op  = 6,
              cp_op  = 7;

    reg flag_c_temp = 'd0;
    reg flag_z_temp = 'd0;
    reg [3:0]temp_reg = 'd0;

    // Control Lines

    // 0 selects low in bits
    // 1 selects high in bits
    wire alu_high_low_sel;

    // 0 selects external flags
    // 1 selects stored flags
    wire alu_flag_sel;

    reg alu_mod_state = 'd0;

    wire [3:0] alu_in_A;
    wire [3:0] alu_in_B;
    wire [3:0] alu_out;
    wire alu_flag_c_out;
    wire alu_flag_z_out;

    wire alu_flag_c_in;

    wire flag_z_combined;

    wire [2:0]real_alu_op;


    assign flag_z_combined = alu_flag_z_out & flag_z_temp;
    assign out = {alu_out, temp_reg};
    assign out_flags = {flag_z_combined, 1'd0, flag_c_temp, alu_flag_c_out};

    assign alu_flag_sel = alu_mod_state;
    assign alu_high_low_sel = alu_mod_state;

    // Flag in switches between core flags and last ALU result flags.
    // There is a special case for the cp opcode where the c flag
    // is cleared to zero in the first operation.
    assign alu_flag_c_in = (alu_mod_state == 'd0 && alu_op == cp_op) ? 'd0 :
                           (alu_flag_sel == 'd1) ? flag_c_temp : in_C;

    assign alu_in_A = (alu_high_low_sel == 'd1) ? in_A[7:4] : in_A[3:0];
    assign alu_in_B = (alu_high_low_sel == 'd1) ? in_B[7:4] : in_B[3:0];

    // Turns add and sub opcodes into adc and sbc respectively for the second clock cycle
    // This makes sure the the carry flag is used in the second half of
    // the operation.
    assign real_alu_op = (alu_mod_state == 'd0) ? alu_op :
                         ((alu_op < and_op) ? (alu_op | 'b1) : alu_op);

    alu a (
        .in_A(alu_in_A),
        .in_B(alu_in_B),
        .alu_op(real_alu_op),
        .in_C(alu_flag_c_in),
        .out(alu_out),
        .out_Z(alu_flag_z_out),
        .out_C(alu_flag_c_out)
    );


    always @(posedge clock)
    begin
        alu_mod_state <= ~alu_mod_state;

        temp_reg <= alu_out;

        if (alu_op == and_op)
        begin
            flag_c_temp <= 'd1;
        end else if (alu_op == xor_op ||
                     alu_op == or_op)
        begin
            flag_c_temp <= 'd0;
        end else begin
            flag_c_temp <= alu_flag_c_out;
        end
        flag_z_temp <= alu_flag_z_out;
    end

endmodule


