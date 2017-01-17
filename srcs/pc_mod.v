`timescale 1ns / 1ps

module pc_mod(
    input clock,
    input reset,

    input [2:0]rst_pc_in,
    input [2:0]int_pc_in,
    input [7:0]data_bus,
    input [2:0]pc_sel,
    input [1:0]offset_sel,
    input write_temp_buf,

    output [15:0]pc_w_offset,
    output [15:0]pc
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



    assign pc_w_offset = 'd0;
    assign pc = 'd0;

endmodule



