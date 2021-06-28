`timescale 1ns / 1ns

`include "srcs/microcode_mod.v"

module control_unit_mod(
    input clock,
    input reset,

    input flag_adv,
    input [7:0]inst_buffer,

    input [1:0]adv_sel,
    input toggle_cb,

    input int_in,
    input int_if_in,
    input set_halt,

    output [75:0]control_signals
    );

    parameter adv_signal_mux_zero = 'd0,
              adv_signal_mux_one = 'd1,
              adv_signal_mux_flag = 'd2;

    reg [15:0]metadata_table[0:511];
    reg [4:0]opcode_offset_counter = 'd0;
    reg adv_buffer;

    reg adv_toggle = 'd0;

    reg [4:0]int_opcode = 'd2;

    wire [15:0]metadata_output;
    wire [15:0]metadata_w_offset;
    wire [15:0]opcode_input;

    wire adv_signal;
    wire should_int;

    reg halted;
    reg leave_halted;

    wire [75:0]control_signals_wire;
    reg [75:0]control_signals_reg;

    // Stays active for the 20 clock cycles it takes to enter an interrupt
    reg run_int;

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

    wire should_int = int_in == 'b1 && adv_buffer == 'd1;

    assign opcode_input = (leave_halted == 'd1) ? {15'b0, adv_toggle} :
                          (run_int == 'b1) ? {11'b0, int_opcode} :
                          (adv_buffer == 'd0) ? metadata_w_offset :
                          {15'b0, adv_toggle};

    assign adv_signal = (adv_sel == adv_signal_mux_zero) ? 'd0 :
                        (adv_sel == adv_signal_mux_one) ? 'd1 :
                        (adv_sel == adv_signal_mux_flag) ? flag_adv :
                        'd0; // Should never reach this state

    // TODO: Autocode this
    assign control_signals = (halted == 'd1) ? 76'h4000000040 : control_signals_wire;

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

        if (run_int == 'd0)
        begin
            int_opcode <= 'd2;
        end
        else
        begin
            int_opcode <= int_opcode + 'd1;
        end

        if (should_int == 'd1)
        begin
            run_int = 'd1;
        end
        else if (should_int == 'd0 && adv_signal == 'd1)
        begin
            run_int = 'd0;
        end
        else
        begin
            run_int = run_int;
        end
    end

    always @(posedge clock)
    begin
        if (reset == 'd0)
        begin
            halted <= 'd0;
            leave_halted <= 'd0;
        end else begin
            if (set_halt) begin
                halted <= 'd1;
            end
            else if (int_if_in == 'd1 && adv_toggle == 'd1)
            begin
                halted <= 'd0;
            end else begin
                halted <= halted;
            end

            if (halted == 'd1 && int_if_in == 'd1 && adv_toggle == 'd1)
            begin
                leave_halted <= 'd1;
            end else if (leave_halted == 'd1 && adv_toggle == 'd1)
            begin
                leave_halted <= 'd0;
            end else begin
                leave_halted <= leave_halted;
            end
        end

    end

endmodule

    


