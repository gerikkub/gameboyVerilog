`timescale 1ns / 1ns

module sp_mod(
    input clock,
    input reset,

    input [2:0]sp_sel,
    input [7:0]data_bus,
    input [7:0]alu_in,
    input [7:0]reg_file_out2,
    input [1:0]temp_buf_sel,
    input write_temp_buf,

    output [15:0]sp
    );

    parameter sp_sel_sp = 'd0,
              sp_sel_sp_incr = 'd1,
              sp_sel_sp_decr = 'd2,
              sp_sel_temp_buf = 'd3,
              sp_sel_data_bus_rel = 'd4;

    parameter sp_temp_sel_data_bus = 'd0,
              sp_temp_sel_alu = 'd1,
              sp_temp_sel_reg_file_out2 = 'd2;

    reg [15:0] sp_register;
    reg [7:0] sp_temp_buffer;

    wire [15:0]sp_reg_mux_out;
    wire [15:0]data_bus_rel_value;

    assign sp = sp_register;

    wire [7:0]temp_buf_in;

    // SP register input mux
    assign sp_reg_mux_out = 
        (sp_sel == sp_sel_sp) ? sp_register :
        (sp_sel == sp_sel_sp_incr) ? sp_register + 'd1 :
        (sp_sel == sp_sel_sp_decr) ? sp_register + 'hFFFF :
        (sp_sel == sp_sel_temp_buf) ? {temp_buf_in, sp_temp_buffer} :
        (sp_sel == sp_sel_data_bus_rel) ? data_bus_rel_value :
        'hFACE; // Should never occur!!!
    
    assign temp_buf_in =
        (temp_buf_sel == sp_temp_sel_data_bus) ? data_bus :
        (temp_buf_sel == sp_temp_sel_alu) ? alu_in :
        (temp_buf_sel == sp_temp_sel_reg_file_out2) ? reg_file_out2 :
        'hEE; // Should never occur

    // Perform a signed addition to the sp register
    assign data_bus_rel_value = 
        (data_bus[7] == 'd0) ? sp_register + {9'd0, data_bus[6:0]} :
                               sp_register + {9'h1FF, data_bus[6:0]};

    always @(posedge clock)
    begin
        if (reset == 'd0)
        begin
            sp_register <= 'hFFFE;
            sp_temp_buffer <= 'd0;
        end else begin
            sp_register <= sp_reg_mux_out;

            if (write_temp_buf == 'd1)
            begin
                sp_temp_buffer <= temp_buf_in;
            end else begin
                sp_temp_buffer <= sp_temp_buffer;
            end
        end
    end

endmodule
