`timescale 1ns / 1ns

`include "srcs/microcode_mod.v"

module control_unit_mod(
    input clock,
    input reset,

    input flag_adv,
    input [7:0]inst_buffer,

    input [1:0]adv_sel,
    input toggle_cb,

    output [70:0]control_signals
    );

    parameter adv_signal_mux_zero = 'd0,
              adv_signal_mux_one = 'd1,
              adv_signal_mux_flag = 'd2;

    reg [15:0]metadata_table[0:511];
    reg [4:0]opcode_offset_counter = 'd0;
    reg adv_buffer;

    reg adv_toggle = 'd0;


    wire [15:0]metadata_output;
    wire [15:0]metadata_w_offset;
    wire [15:0]opcode_input;

    wire adv_signal;
    wire [70:0]control_signals_wire;
    reg [70:0]control_signals_reg;

    initial $readmemh("srcs/metadata_vector.txt", metadata_table);

    microcode_mod microcode(
        .opcode(opcode_input[9:0]),
        .control_signals(control_signals_wire)
    );

    reg cb_inst_active = 'd0;

    assign metadata_output = metadata_table[{cb_inst_active, inst_buffer}];
    
    // Metadata_w_offset is the output of the metadata table + the offset
    // counter
    assign metadata_w_offset = metadata_output + {11'b0, opcode_offset_counter};

    assign opcode_input = (adv_buffer == 'd0) ? metadata_w_offset :
                          {15'b0, adv_toggle};

    assign adv_signal = (adv_sel == adv_signal_mux_zero) ? 'd0 :
                        (adv_sel == adv_signal_mux_one) ? 'd1 :
                        (adv_sel == adv_signal_mux_flag) ? flag_adv :
                        'd0; // Should never reach this state

    //assign control_signals = control_signals_reg;
    assign control_signals = control_signals_wire;

    always @(posedge clock)
    begin
        if (adv_buffer == 'd0)
        begin
            opcode_offset_counter <= opcode_offset_counter + 'd1;
        end else begin
            opcode_offset_counter <= 'd0;
        end

        if (toggle_cb == 'd0)
        begin
            cb_inst_active = cb_inst_active;
        end else begin
            cb_inst_active = ~cb_inst_active;
        end

        if (reset == 'd0)
        begin
            adv_buffer <= 'd1;
            adv_toggle <= 'd0;
        end else begin
            adv_buffer <= adv_signal;

            adv_toggle <= ~adv_toggle;
        end

        //control_signals_reg <= control_signals_wire;
    end

endmodule

    


