`timescale 1ns / 1ps

`include "srcs/microcode_mod.v"

module control_unit_mod(
    input clock,
    input reset,

    input flag_adv,
    input [7:0]inst_buffer,

    input [1:0]adv_sel,

    output [58:0]control_signals
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

    initial $readmemh("srcs/metadata_table.txt", metadata_table);

    microcode_mod microcode(
        .opcode(opcode_input[3:0]),
        .control_signals(control_signals)
    );


    assign metadata_output = metadata_table[inst_buffer];
    
    // Metadata_w_offset is the output of the metadata table + the offset
    // counter
    assign metadata_w_offset = metadata_output + opcode_offset_counter;

    assign opcode_input = (adv_buffer == 'd0) ? metadata_w_offset :
                          adv_toggle;

    assign adv_signal = (adv_sel == adv_signal_mux_zero) ? 'd0 :
                        (adv_sel == adv_signal_mux_one) ? 'd1 :
                        (adv_sel == adv_signal_mux_flag) ? flag_adv :
                        'd0; // Should never reach this state


    always @(posedge clock)
    begin
        if (adv_buffer == 'd0)
        begin
            opcode_offset_counter <= opcode_offset_counter + 'd1;
        end else begin
            opcode_offset_counter <= 'd0;
        end

        if (reset == 'd0)
        begin
            adv_buffer <= 'd1;
            adv_toggle <= 'd0;
        end else begin
            adv_buffer <= adv_signal;

            adv_toggle <= ~adv_toggle;
        end
    end

endmodule

    


