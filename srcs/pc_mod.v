`timescale 1ns / 1ns

module pc_mod(
    input clock,
    input reset,

    input [2:0]rst_pc_in,
    input [2:0]int_pc_in,
    input [7:0]data_bus,
    input [15:0]reg_file_in,
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
              pc_sel_data_bus_rel = 'd6,
              pc_sel_reg_file = 'd7;

    parameter offset_sel_offset = 'd0,
              offset_sel_offset_incr = 'd1,
              offset_sel_zero = 'd2;




    reg [15:0] pc_register;
    reg [1:0] offset_register;
    reg [7:0] data_bus_buffer;

    wire [15:0]pc_reg_mux_out;
    wire [1:0]offset_reg_mux_out;
    
    wire [15:0]rst_addr;
    wire [15:0]int_addr;
    wire [15:0]data_bus_rel_value;


    assign pc = pc_register;

    assign pc_w_offset = pc_register + offset_register;

    // PC register input mux
    assign pc_reg_mux_out = (pc_sel == pc_sel_pc) ? pc_register :
                            (pc_sel == pc_sel_pc_incr) ? (pc_w_offset + 'd1) :
                            (pc_sel == pc_sel_rst_mod) ? rst_addr :
                            (pc_sel == pc_sel_int_mod) ? int_addr :
                            (pc_sel == pc_sel_zero) ? 16'd0 :
                            (pc_sel == pc_sel_data_bus) ? {data_bus, data_bus_buffer} :
                            (pc_sel == pc_sel_data_bus_rel) ? data_bus_rel_value :
                            (pc_sel == pc_sel_reg_file) ? reg_file_in :
                            'hFACE; // Can never occur!!!!!


    // Offset register input mux 
    assign offset_reg_mux_out = (offset_sel == offset_sel_offset) ? offset_register :
                                (offset_sel == offset_sel_offset_incr) ? offset_register + 'd1 :
                                (offset_sel == offset_sel_zero) ? 'd0 :
                                'b11; // Should never occur!!!!

    // Expand the given rst value to an address
    assign rst_addr = {10'd0, rst_pc_in, 3'd0};
    
    // Expand the given interrupt value to an address
    assign int_addr = {9'd0, 1'd1, int_pc_in, 3'd0};

    // Perform a signed addition to pc + offset
    assign data_bus_rel_value = (data_bus[7] == 'd0) ? pc_w_offset + {9'd0, data_bus[6:0]} :
                                pc_w_offset + {9'h1FF, data_bus[6:0]};

    always @(posedge clock)
    begin
        if (reset == 'd0)
        begin
            pc_register <= 'h100;
            offset_register <= 'd0;
            data_bus_buffer <= 'd0;
        end else begin
            pc_register <= pc_reg_mux_out;
            offset_register <= offset_reg_mux_out;

            if (write_temp_buf == 'd1)
            begin
                data_bus_buffer <= data_bus;
            end else begin
                data_bus_buffer <= data_bus_buffer;
            end
        end
    end


endmodule



