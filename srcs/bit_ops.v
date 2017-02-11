`timescale 1ns / 1ns

module bit_ops(
    input [4:0]shift_op,
    input [7:0]reg_in,
    input c_in,

    output [7:0]reg_out,
    output c_out,
    output z_out,
    output h_out
    );

    parameter rlc_op = 0,
              rrc_op = 1,
              rl_op  = 2,
              rr_op  = 3,
              sla_op = 4,
              sra_op = 5,
              swap_op = 6,
              srl_op = 7;

    parameter bit_op = 1,
              res_op = 2,
              set_op = 3;

    wire [8:0]rlc_result;
    wire [8:0]rrc_result;
    wire [8:0]rl_result;
    wire [8:0]rr_result;
    wire [8:0]sla_result;
    wire [8:0]sra_result;
    wire [8:0]swap_result;
    wire [8:0]srl_result;

    wire [7:0]bit_result_temp;
    wire [7:0]res_result_temp;
    wire [7:0]set_result_temp;

    wire [8:0]bit_result;
    wire [8:0]res_result;
    wire [8:0]set_result;

    assign rlc_result = {reg_in[7], reg_in[6:0], reg_in[7]};
    assign rrc_result = {reg_in[0], reg_in[0], reg_in[7:1]};
    assign rl_result  = {reg_in[7], reg_in[6:0], c_in};
    assign rr_result  = {reg_in[0], c_in, reg_in[7:1]};
    assign sla_result = {reg_in[7], reg_in[6:0], 1'd0};
    assign sra_result = {reg_in[0], reg_in[7], reg_in[7:1]};
    assign swap_result = {1'd0, reg_in[3:0], reg_in[7:4]};
    assign srl_result = {reg_in[0], 1'd0, reg_in[7:1]};

    assign bit_result_temp = reg_in[7:0] & (1 << shift_op[3:0]);
    assign res_result_temp = reg_in[7:0] & (~(1 << shift_op[3:0]));
    assign set_result_temp = reg_in[7:0] | (1 << shift_op[3:0]);

    assign bit_result = {c_in, bit_result_temp};
    assign res_result = {c_in, res_result_temp};
    assign set_result = {c_in, set_result_temp};

    assign reg_out = (shift_op[4:3] == bit_op) ? reg_in :
                     (shift_op[4:3] == res_op) ? res_result[7:0] :
                     (shift_op[4:3] == set_op) ? set_result[7:0] :
                     (shift_op[2:0] == rlc_op) ? rlc_result[7:0] :
                     (shift_op[2:0] == rrc_op) ? rrc_result[7:0] :
                     (shift_op[2:0] == rl_op) ? rl_result[7:0] :
                     (shift_op[2:0] == rr_op) ? rr_result[7:0] :
                     (shift_op[2:0] == sla_op) ? sla_result[7:0] :
                     (shift_op[2:0] == sra_op) ? sra_result[7:0] :
                     (shift_op[2:0] == swap_op) ? swap_result[7:0] :
                     (shift_op[2:0] == srl_op) ? srl_result[7:0] :
                     'hee; // can never occur

    assign c_out =   (shift_op[4:3] == bit_op) ? bit_result[8] :
                     (shift_op[4:3] == res_op) ? res_result[8] :
                     (shift_op[4:3] == set_op) ? set_result[8] :
                     (shift_op[2:0] == rlc_op) ? rlc_result[8] :
                     (shift_op[2:0] == rrc_op) ? rrc_result[8] :
                     (shift_op[2:0] == rl_op) ? rl_result[8] :
                     (shift_op[2:0] == rr_op) ? rr_result[8] :
                     (shift_op[2:0] == sla_op) ? sla_result[8] :
                     (shift_op[2:0] == sra_op) ? sra_result[8] :
                     (shift_op[2:0] == swap_op) ? swap_result[8] :
                     (shift_op[2:0] == srl_op) ? srl_result[8] :
                     'h1; // can never occur

    assign z_out =   (shift_op[4:3] == bit_op) ? bit_result[7:0] == 'd1 :
                     reg_out == 'd0;

    assign h_out =   (shift_op[4:3] == bit_op) ? 'd1 : 'd0;

endmodule

