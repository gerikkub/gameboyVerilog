`timescale 1ns / 1ps

module sp_mod(
    input clock,
    input reset,

    input [2:0]sp_sel,
    input [7:0]data_bus,
    input write_temp_buf,

    output [15:0]sp
    );

    parameter sp_sel_sp = 'd0,
              sp_sel_sp_incr = 'd1,
              sp_sel_sp_decr = 'd2,
              sp_sel_data_bus = 'd3,
              sp_sel_data_bus_rel = 'd4;

    reg [15:0] sp_register;
    reg [7:0] data_bus_buffer;

    wire [15:0]sp_reg_mux_out;
    wire [15:0]data_bus_rel_value;

    assign sp = sp_register;

    // SP register input mux
    assign sp_reg_mux_out = 
        (sp_sel == sp_sel_sp) ? sp_register :
        (sp_sel == sp_sel_sp_incr) ? sp_register + 'd1 :
        (sp_sel == sp_sel_sp_decr) ? sp_register + 'hFFFF :
        (sp_sel == sp_sel_data_bus) ? {data_bus, data_bus_buffer} :
        (sp_sel == sp_sel_data_bus_rel) ? data_bus_rel_value :
        'hFACE; // Should never occur!!!
    
    // Perform a signed addition to the sp register
    assign data_bus_rel_value = 
        (data_bus[7] == 'd0) ? sp_register + {9'd0, data_bus[6:0]} :
                               sp_register + {9'h1FF, data_bus[6:0]};

    always @(posedge clock)
    begin
        if (reset == 'd0)
        begin
            sp_register <= 'd0;
            data_bus_buffer <= 'd0;
        end else begin
            sp_register <= sp_reg_mux_out;

            if (write_temp_buf == 'd1)
            begin
                data_bus_buffer <= data_bus;
            end else begin
                data_bus_buffer <= data_bus_buffer;
            end
        end
    end

endmodule
