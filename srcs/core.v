`timescale 1ns / 1ns

`include "srcs/alu_mod.v"
`include "srcs/control_unit_mod.v"
`include "srcs/pc_mod.v"
`include "srcs/reg_file.v"
`include "srcs/sp_mod.v"
`include "srcs/bit_ops.v"
`include "srcs/daa_mod.v"

`include "srcs/cs_mapper_mod.v"

module core(
    input clock,
    input reset,

    output [15:0]db_address,
    inout  [7:0]db_data,
    output db_nread,
    output db_nwrite,

    input int_vblank,
    input int_stat,
    input int_timer,
    input int_serial,
    input int_joypad
    );

    reg [7:0]inst_buffer = 'd0;
    reg [7:0]inst_data_buffer1 = 'd0;
    reg [7:0]inst_data_buffer2 = 'd0;
    reg temp_flag_c = 'd0;
    reg flag_c = 'd0;
    reg flag_z = 'd0;
    reg flag_n = 'd0;
    reg flag_h = 'd0;


    wire [7:0]flags;

    reg [15:0]addr_buffer = 'd0;

    reg [7:0]data_bus_buffer = 'd0;

    // Control signals for core temp registers
    wire cs_write_inst_buffer;
    wire cs_write_data_buffer1;
    wire cs_write_data_buffer2;
    wire cs_write_addr_buffer;
    wire cs_write_data_bus_buffer;
    wire [1:0]cs_addr_buffer_sel;

    wire [7:0]addr_bus_buffer_in;
   
    parameter addr_buffer_reg_file_out2 = 'd0,
              addr_buffer_data_bus = 'd1,
              addr_buffer_ff = 'd2;

    assign addr_bus_buffer_in  = (cs_addr_buffer_sel == addr_buffer_reg_file_out2) ? reg_file_out2 :
                                 (cs_addr_buffer_sel == addr_buffer_data_bus) ? db_data :
                                 (cs_addr_buffer_sel == addr_buffer_ff) ? 'hFF :
                                 'hEE; // Should never occur


    always @(posedge clock)
    begin
        if (reset == 'd0)
        begin
            inst_buffer <= 'd0;
            inst_data_buffer1 <= 'd0;
            inst_data_buffer2 <= 'd0;
            addr_buffer <= 'd0;
            data_bus_buffer <= 'd0;
        end else begin

            if (cs_write_inst_buffer == 'd0)
            begin
                inst_buffer <= inst_buffer;
            end else begin
                inst_buffer <= db_data;
            end

            if (cs_write_data_buffer1 == 'd0)
            begin
                inst_data_buffer1 <= inst_data_buffer1;
            end else begin
                inst_data_buffer1 <= db_data;
            end

            if (cs_write_data_buffer2 == 'd0)
            begin
                inst_data_buffer2 <= inst_data_buffer2;
            end else begin
                inst_data_buffer2 <= db_data;
            end

            if (cs_write_addr_buffer == 'd0)
            begin
                addr_buffer <= addr_buffer;
            end else begin
                // Writing the addr buffer shifts the lower byte to the upper byte
                // and loads the bottom byte
                addr_buffer <= {addr_buffer[7:0], addr_bus_buffer_in};
            end

            if (cs_write_data_bus_buffer == 'd0)
            begin
                data_bus_buffer <= data_bus_buffer;
            end else begin
                data_bus_buffer <= db_data;
            end
        end
    end

    // Control signals for data bus
    wire [2:0]cs_db_address_sel;
    wire [3:0]cs_db_data_sel;
    wire cs_db_nwrite;
    wire cs_db_nread;

    parameter db_addr_buffer = 'd0,
              db_addr_pc_offset = 'd1,
              db_addr_sp = 'd2,
              db_addr_buffer_swap = 'd3,
              db_addr_buffer_swap_1 = 'd4;

    parameter db_data_reg_file_out1 = 'd0,
              db_data_alu = 'd1,
              db_data_pc_offset_p = 'd2,
              db_data_pc_offset_c = 'd3,
              db_data_sp_s = 'd4,
              db_data_sp_p = 'd5,
              db_data_data_bus_temp = 'd6,
              db_data_flags = 'd7,
              db_data_shift = 'd8;

    assign db_address = (cs_db_address_sel == db_addr_buffer) ? addr_buffer :
                        (cs_db_address_sel == db_addr_pc_offset) ? pc_out_w_offset :
                        (cs_db_address_sel == db_addr_sp) ? sp_out :
                        (cs_db_address_sel == db_addr_buffer_swap) ? {addr_buffer[7:0], addr_buffer[15:8]} :
                        (cs_db_address_sel == db_addr_buffer_swap_1) ? {addr_buffer[7:0], addr_buffer[15:8]} + 'd1 :
                        'hEEEE; // Should never occur

    assign db_data = (cs_db_nwrite == 'd1) ? 8'bZ :
                     (cs_db_data_sel == db_data_reg_file_out1) ? reg_file_out1 :
                     (cs_db_data_sel == db_data_alu) ? alu_out :
                     (cs_db_data_sel == db_data_pc_offset_p) ? pc_out_w_offset[15:8] :
                     (cs_db_data_sel == db_data_pc_offset_c) ? pc_out_w_offset[7:0] :
                     (cs_db_data_sel == db_data_sp_s) ? sp_out[15:8] :
                     (cs_db_data_sel == db_data_sp_p) ? sp_out[7:0] :
                     (cs_db_data_sel == db_data_data_bus_temp) ? inst_data_buffer1 :
                     (cs_db_data_sel == db_data_flags) ? {flag_z, flag_n, flag_h, flag_c, 4'd0} :
                     (cs_db_data_sel == db_data_shift) ? shift_out :
                     'hEE; // Should never occur

    assign db_nwrite = cs_db_nwrite;
    assign db_nread = cs_db_nread;


    // Control signals for flags
    wire cs_write_flag_c;
    wire cs_write_flag_z;
    wire cs_write_flag_n;
    wire cs_write_flag_h;
    wire cs_write_temp_flag_c;

    wire [2:0]cs_flag_c_sel;
    wire [2:0]cs_flag_z_sel;
    wire [1:0]cs_flag_n_sel;
    wire [2:0]cs_flag_h_sel;

    parameter flag_c_zero = 'd0,
              flag_c_one = 'd1,
              flag_c_alu = 'd2,
              flag_c_shift = 'd3,
              flag_c_toggle = 'd4,
              flag_c_data_bus = 'd5,
              flag_c_daa = 'd6;
    
    parameter flag_z_zero = 'd0,
              flag_z_data_bus = 'd1,
              flag_z_alu = 'd2,
              flag_z_shift = 'd3,
              flag_z_daa = 'd4;

    parameter flag_n_zero = 'd0,
              flag_n_one = 'd1,
              flag_n_data_bus = 'd2;

    parameter flag_h_zero = 'd0,
              flag_h_one = 'd1,
              flag_h_alu = 'd2,
              flag_h_data_bus = 'd3,
              flag_h_shift = 'd4;

     // Flag muxes
     always @(posedge clock)
     begin         
        if (reset <= 'd0)
        begin
            flag_c <= 'd0;
            flag_z <= 'd1;
            flag_n <= 'd0;
            flag_h <= 'd0;
            temp_flag_c <= 'd0;
        end else begin

            if (cs_write_flag_c == 'd0)
            begin
                flag_c <= flag_c;
            end else begin
                case (cs_flag_c_sel)
                    flag_c_zero:  flag_c <= 'd0;
                    flag_c_one:   flag_c <= 'd1;
                    flag_c_alu:   flag_c <= alu_out_flags[0];
                    flag_c_shift: flag_c <= shift_c_out;
                    flag_c_toggle: flag_c <= ~flag_c;
                    flag_c_data_bus: flag_c <= db_data[4];
                    flag_c_daa:   flag_c <= daa_c_out;
                    default: flag_c <= 'd1; // Should never occur
                endcase
            end

            if (cs_write_flag_z == 'd0)
            begin
                flag_z <= flag_z;
            end else begin
                case (cs_flag_z_sel)
                    flag_z_zero:  flag_z <= 'd0;
                    flag_z_data_bus: flag_z <= db_data[7];
                    flag_z_alu:   flag_z <= alu_out_flags[3];
                    flag_z_shift: flag_z <= shift_z_out;
                    flag_z_daa:   flag_z <= daa_z_out;
                    default: flag_z <= 'd1; // Should never occur
                endcase
            end

            if (cs_write_flag_n == 'd0)
            begin
                flag_n <= flag_n;
            end else begin
                case (cs_flag_n_sel)
                    flag_n_zero: flag_n <= 'd0;
                    flag_n_one:  flag_n <= 'd1;
                    flag_n_data_bus: flag_n <= db_data[6];
                    default: flag_n <= 'd1; // Can never occur
                endcase
            end

            if (cs_write_flag_h == 'd0)
            begin
                flag_h <= flag_h;
            end else begin
                case (cs_flag_h_sel)
                    flag_h_zero: flag_h <= 'd0;
                    flag_h_one:  flag_h <= 'd1;
                    flag_h_alu:  flag_h <= alu_out_flags[1];
                    flag_h_data_bus: flag_h <= db_data[5];
                    flag_h_shift: flag_h <= shift_h_out;
                    default: flag_h <= 'd1; // Could occur, but should not
                endcase
            end

            if (cs_write_temp_flag_c == 'd0)
            begin
                temp_flag_c <= temp_flag_c;
            end else begin
                temp_flag_c <= alu_out_flags[0];
            end
        end
    end


    // Control signals for ALU
    wire [7:0]alu_in_A;
    wire [7:0]alu_in_B;
    wire [2:0]alu_op;
    wire alu_in_C;

    wire [7:0]alu_out;
    wire [3:0]alu_out_flags;

    parameter add_op = 0,
              adc_op = 1,
              sub_op = 2,
              sbc_op = 3,
              and_op = 4,
              xor_op = 5,
              or_op  = 6,
              cp_op  = 7;

    parameter alu_in_A_reg_out1 = 'd0,
              alu_in_A_SP_S = 'd1,
              alu_in_A_SP_P = 'd2,
              alu_in_A_data_bus_temp = 'd3;

    parameter alu_in_B_zero = 'd0,
              alu_in_B_one  = 'd1,
              alu_in_B_reg_out2 = 'd2,
              alu_in_B_data_bus_temp = 'd3,
              alu_in_B_data_bus_temp_sgn = 'd4;

    parameter alu_op_inst = 'd0,
              alu_op_add  = 'd1,
              alu_op_adc  = 'd2,
              alu_op_sub  = 'd3,
              alu_op_sbc  = 'd4;

    parameter alu_in_C_flag = 'd0,
              alu_in_C_temp = 'd1,
              alu_in_C_zero = 'd2,
              alu_in_C_one  = 'd3;


    wire [1:0]cs_alu_in_A_sel;
    wire [2:0]cs_alu_in_B_sel;
    wire [2:0]cs_alu_op_sel;
    wire [1:0]cs_alu_in_C_sel;

    wire [7:0]alu_data_bus_sgn;

    assign alu_in_A = (cs_alu_in_A_sel == alu_in_A_reg_out1) ? reg_file_out1 :
                      (cs_alu_in_A_sel == alu_in_A_SP_S) ? sp_out[15:8] :
                      (cs_alu_in_A_sel == alu_in_A_SP_P) ? sp_out[7:0] :
                      (cs_alu_in_A_sel == alu_in_A_data_bus_temp) ? inst_data_buffer1 :
                      'hEE; // Can never occur

    assign alu_in_B = (cs_alu_in_B_sel == alu_in_B_zero) ? 'd0 :
                      (cs_alu_in_B_sel == alu_in_B_one) ? 'd1 :
                      (cs_alu_in_B_sel == alu_in_B_reg_out2) ? reg_file_out2 :
                      (cs_alu_in_B_sel == alu_in_B_data_bus_temp) ? inst_data_buffer1 :
                      (cs_alu_in_B_sel == alu_in_B_data_bus_temp_sgn) ? alu_data_bus_sgn :
                      'hEE; // Should never occur

    assign alu_op = (cs_alu_op_sel == alu_op_inst) ? inst_buffer[5:3] :
                    (cs_alu_op_sel == alu_op_add) ? add_op :
                    (cs_alu_op_sel == alu_op_adc) ? adc_op :
                    (cs_alu_op_sel == alu_op_sub) ? sub_op :
                    (cs_alu_op_sel == alu_op_sbc) ? sbc_op :
                    'b111; // Should never occur

    assign alu_in_C = (cs_alu_in_C_sel == alu_in_C_flag) ? flag_c :
                      (cs_alu_in_C_sel == alu_in_C_temp) ? temp_flag_c :
                      (cs_alu_in_C_sel == alu_in_C_zero) ? 'd0 :
                      (cs_alu_in_C_sel == alu_in_C_one) ? 'd1 :
                      'b1; // Can never occur

    assign alu_data_bus_sgn = ((inst_data_buffer1 & 'h80) == 'h80) ? 'hFF : 'h00;

    alu_mod alu_m(
        .clock(clock),
        .in_A(alu_in_A),
        .in_B(alu_in_B),
        .alu_op(alu_op),
        .in_C(alu_in_C),
        .out(alu_out),
        .out_flags(alu_out_flags)
    );
    


    // Control Signals for Register File
    wire [2:0]reg_file_out1_sel;
    wire [2:0]reg_file_out2_sel;
    wire [7:0]reg_file_data_in;
    wire [2:0]reg_file_data_in_sel;

    wire [7:0]reg_file_out1;
    wire [7:0]reg_file_out2;

    wire [2:0]cs_reg_file_out1_sel_sel;
    wire [2:0]cs_reg_file_out2_sel_sel;
    wire [2:0]cs_reg_file_data_in_sel;
    wire [2:0]cs_reg_file_data_in_sel_sel;
    wire cs_reg_file_write_reg;

    parameter reg_file_out1_inst20 = 'd0,
              reg_file_out1_inst53 = 'd1,
              reg_file_out1_inst54_zero = 'd2,
              reg_file_out1_inst54_one  = 'd3,
              reg_file_out1_A = 'd4,
              reg_file_out1_H = 'd5,
              reg_file_out1_L = 'd6;

    parameter reg_file_out2_inst20 = 'd0,
              reg_file_out2_inst53 = 'd1,
              reg_file_out2_inst54_zero = 'd2,
              reg_file_out2_inst54_one = 'd3,
              reg_file_out2_H = 'd4,
              reg_file_out2_L = 'd5,
              reg_file_out2_C = 'd6;

    parameter reg_file_data_in_data_bus = 'd0,
              reg_file_data_in_alu = 'd1,
              reg_file_data_in_shift = 'd2,
              reg_file_data_in_daa = 'd3,
              reg_file_data_in_cpl = 'd4,
              reg_file_data_in_out2 = 'd5;

    parameter reg_file_data_in_sel_inst53 = 'd0,
              reg_file_data_in_sel_inst54_zero = 'd1,
              reg_file_data_in_sel_inst54_one = 'd2,
              reg_file_data_in_sel_A = 'd3,
              reg_file_data_in_sel_H = 'd4,
              reg_file_data_in_sel_L = 'd5,
              reg_file_data_in_sel_inst20 = 'd6;

    assign reg_file_out1_sel = (cs_reg_file_out1_sel_sel == reg_file_out1_inst20) ? inst_buffer[2:0] :
                               (cs_reg_file_out1_sel_sel == reg_file_out1_inst53) ? inst_buffer[5:3] :
                               (cs_reg_file_out1_sel_sel == reg_file_out1_inst54_zero) ? {inst_buffer[5:4], 1'd0} :
                               (cs_reg_file_out1_sel_sel == reg_file_out1_inst54_one)  ? {inst_buffer[5:4], 1'd1} :
                               (cs_reg_file_out1_sel_sel == reg_file_out1_A) ? 'b111 :
                               (cs_reg_file_out1_sel_sel == reg_file_out1_H) ? 'b100 :
                               (cs_reg_file_out1_sel_sel == reg_file_out1_L) ? 'b101 :
                               'b110; // Should never occur

    assign reg_file_out2_sel = (cs_reg_file_out2_sel_sel == reg_file_out2_inst20) ? inst_buffer[2:0] :
                               (cs_reg_file_out2_sel_sel == reg_file_out2_inst53) ? inst_buffer[5:3] :
                               (cs_reg_file_out2_sel_sel == reg_file_out2_inst54_zero) ? {inst_buffer[5:4], 1'd0} :
                               (cs_reg_file_out2_sel_sel == reg_file_out2_inst54_one)  ? {inst_buffer[5:4], 1'd1} :
                               (cs_reg_file_out2_sel_sel == reg_file_out2_H) ? 'b100 :
                               (cs_reg_file_out2_sel_sel == reg_file_out2_L) ? 'b101 :
                               (cs_reg_file_out2_sel_sel == reg_file_out2_C) ? 'b001 :
                               'b110; // Should never occur

    assign reg_file_data_in = (cs_reg_file_data_in_sel == reg_file_data_in_data_bus) ? db_data :
                              (cs_reg_file_data_in_sel == reg_file_data_in_alu) ? alu_out :
                              (cs_reg_file_data_in_sel == reg_file_data_in_shift) ? shift_out :
                              (cs_reg_file_data_in_sel == reg_file_data_in_daa) ? daa_out :
                              (cs_reg_file_data_in_sel == reg_file_data_in_cpl) ? (reg_file_out1 ^ 'hFF) :
                              (cs_reg_file_data_in_sel == reg_file_data_in_out2) ? reg_file_out2 :
                              'hEE; // Should never occur

    assign reg_file_data_in_sel = (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_inst53) ? inst_buffer[5:3] :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_inst54_zero) ? {inst_buffer[5:4], 1'd0} :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_inst54_one)  ? {inst_buffer[5:4], 1'd1} :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_A) ? 'b111 :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_H) ? 'b100 :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_L) ? 'b101 :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_inst20) ? inst_buffer[2:0] :
                                  'b110; // Should never occur

    reg_file reg_file(
        .clock(clock),
        .out1_sel(reg_file_out1_sel),
        .out2_sel(reg_file_out2_sel),
        .data_in(reg_file_data_in),
        .data_in_sel(reg_file_data_in_sel),
        .write_reg(cs_reg_file_write_reg),
        .out1(reg_file_out1),
        .out2(reg_file_out2)
    );

    // Control Signals for Shift Unit
    wire [7:0]shift_out;
    wire shift_c_out;
    wire shift_z_out;
    wire shift_h_out;
    wire [7:0]shift_in;

    wire cs_shift_in_sel;

    parameter shift_in_sel_reg_file = 'd0,
              shift_in_sel_data_bus = 'd1;

    assign shift_in = (cs_shift_in_sel == shift_in_sel_reg_file) ? reg_file_out1 :
                      (cs_shift_in_sel == shift_in_sel_data_bus) ? inst_data_buffer1 :
                      'hEE; // Can never occur

    bit_ops shift_unit(
        .shift_op(inst_buffer[7:3]),
        .reg_in(shift_in),
        .c_in(flag_c),
        .reg_out(shift_out),
        .c_out(shift_c_out),
        .z_out(shift_z_out),
        .h_out(shift_h_out)
    );

    // Control Signals for DAA
    wire [7:0]daa_out;
    wire daa_c_out;
    wire daa_z_out;
    wire daa_h_out;

    daa_mod daa(
        .in(reg_file_out1),
        .c_in(flag_c),
        .h_in(flag_h),
        .n_in(flag_n),
        .out(daa_out),
        .c_out(daa_c_out),
        .z_out(daa_z_out)
    );

    // Control Signals for PC
    wire [2:0]pc_rst_in;
    wire [2:0]pc_int_in;

    wire [3:0]cs_pc_sel;
    wire [1:0]cs_pc_offset_sel;
    wire cs_pc_write_temp_buf;

    wire [15:0]pc_out_w_offset;
    wire [15:0]pc_out_direct;

    assign pc_rst_in = inst_buffer[5:3];
    
    assign pc_int_in = 'd0; // TODO

    pc_mod pc_mod(
        .clock(clock),
        .reset(reset),
        .rst_pc_in(pc_rst_in),
        .int_pc_in(pc_int_in),
        .data_bus(inst_data_buffer1),
        .reg_file_in({reg_file_out1, reg_file_out2}),
        .pc_sel(cs_pc_sel),
        .offset_sel(cs_pc_offset_sel),
        .write_temp_buf(cs_pc_write_temp_buf),
        .int_active_prio(int_active_prio),
        .pc_w_offset(pc_out_w_offset),
        .pc(pc_out_direct)
    );

    // Control Signals for SP
    wire [2:0]cs_sp_sel;
    wire cs_sp_write_temp_buf;
    wire [1:0]cs_sp_temp_buf_sel;

    wire [15:0]sp_out;

    sp_mod sp_mod(
        .clock(clock),
        .reset(reset),
        .sp_sel(cs_sp_sel),
        .data_bus(db_data),
        .alu_in(alu_out),
        .reg_file_out2(reg_file_out2),
        .temp_buf_sel(cs_sp_temp_buf_sel),
        .write_temp_buf(cs_sp_write_temp_buf),
        .sp(sp_out)
    );
    
    // Control signals for Control Unit
    wire [1:0]cs_cu_adv_sel;
    wire cs_cu_toggle_cb;
    wire cs_set_halt;

    wire flag_adv;
    wire [75:0]control_signals;

    // Used for coditional operation to skip the rest
    // of the instruction
    assign flag_adv = ~((inst_buffer[4:3] == 'b00) ? ~flag_z :
                        (inst_buffer[4:3] == 'b01) ? flag_z :
                        (inst_buffer[4:3] == 'b10) ? ~flag_c :
                        (inst_buffer[4:3] == 'b11) ? flag_c :
                        'b1); // Can never occur

    control_unit_mod cu_mod(
        .clock(clock),
        .reset(reset),
        .flag_adv(flag_adv),
        .inst_buffer(inst_buffer),
        .adv_sel(cs_cu_adv_sel),
        .toggle_cb(cs_cu_toggle_cb),
        .int_in(int_cu),
        .int_if_in(int_if_cu),
        .set_halt(cs_set_halt),
        .control_signals(control_signals)
    );

    // Control signals for IME
    reg ime = 'd0;

    wire cs_set_ime;
    wire cs_clear_ime;
    wire cs_ack_interrupt;

    // Need to delay IME set by two clock cycles
    reg ime_buffer1 = 'd0;
    reg ime_buffer2 = 'd0;

    wire ime_buffer_in;

    reg [4:0]int_ie;
    reg [4:0]int_if;

    wire [4:0]int_if_in;
    wire [4:0]int_active;

    wire int_cu;
    wire int_if_cu;

    assign ime_buffer_in = (cs_set_ime == 'd1) ? 'b1:
                           (cs_clear_ime == 'd1) ? 'b0:
                           ime_buffer1;

    assign int_active = int_ie & int_if;

    assign int_cu = (int_active & {5{ime}}) != 'd0;
    assign int_if_cu = int_if != 'd0;

    wire [2:0]int_active_prio;

    assign int_active_prio = (int_active[0] == 'b1) ? 3'd0 :
                             (int_active[1] == 'b1) ? 3'd1 :
                             (int_active[2] == 'b1) ? 3'd2 :
                             (int_active[3] == 'b1) ? 3'd3 :
                             (int_active[4] == 'b1) ? 3'd4 :
                             3'h7;

    // Ime buffering
    always @(posedge clock)
    begin
        if (reset == 'd0)
        begin
            ime <= 'd0;
            ime_buffer1 <= 'd0;
            ime_buffer2 <= 'd0;
        end
        else
        begin
            ime_buffer1 <= ime_buffer_in;
            ime_buffer2 <= ime_buffer1;
            ime <= ime_buffer2;
        end
    end

    // Interrupt register handling
    assign int_if_in = {int_joypad, int_serial, int_timer, int_stat, int_vblank};

    always @(posedge clock)
    begin
        if (db_nwrite == 'd0 && db_address == 'hFFFF)
        begin
            int_ie = db_data[4:0];
        end
        else
        begin
            int_ie = int_ie;
        end
    end

    always @(posedge clock)
    begin
        if (db_nwrite == 'd0 && db_address == 'hFF0F)
        begin
            // TODO: It's unclear if writing this register
            // only sets bits, or can clear bits as well
            int_if <= db_data[4:0];
        end
        else if (cs_ack_interrupt == 'd1)
        begin
            // Clear the active interrupt
            int_if <= int_if & ~('b1 << int_active_prio);
        end
        else
        begin
            int_if <= int_if | int_if_in;
        end
        
    end

    assign db_data = (db_nread == 'b1) ? 8'bZ :
                     (db_address == 'hFFFF) ? {3'b0, int_ie} :
                     (db_address == 'hFF0F) ? {3'b0, int_if} :
                     8'bZ;

    // Control signal mapper

    cs_mapper_mod cs_mapper_mod(
        .cs_flag_z_sel(cs_flag_z_sel),
        .cs_db_nwrite(cs_db_nwrite),
        .cs_alu_in_C_sel(cs_alu_in_C_sel),
        .cs_alu_op_sel(cs_alu_op_sel),
        .cs_pc_offset_sel(cs_pc_offset_sel),
        .cs_flag_h_sel(cs_flag_h_sel),
        .cs_reg_file_out2_sel_sel(cs_reg_file_out2_sel_sel),
        .cs_reg_file_data_in_sel_sel(cs_reg_file_data_in_sel_sel),
        .cs_sp_sel(cs_sp_sel),
        .cs_write_inst_buffer(cs_write_inst_buffer),
        .cs_pc_sel(cs_pc_sel),
        .cs_reg_file_data_in_sel(cs_reg_file_data_in_sel),
        .cs_write_data_buffer2(cs_write_data_buffer2),
        .cs_write_data_buffer1(cs_write_data_buffer1),
        .cs_cu_adv_sel(cs_cu_adv_sel),
        .cs_write_data_bus_buffer(cs_write_data_bus_buffer),
        .cs_db_address_sel(cs_db_address_sel),
        .cs_db_data_sel(cs_db_data_sel),
        .cs_db_nread(cs_db_nread),
        .cs_alu_in_A_sel(cs_alu_in_A_sel),
        .cs_write_temp_flag_c(cs_write_temp_flag_c),
        .cs_alu_in_B_sel(cs_alu_in_B_sel),
        .cs_sp_write_temp_buf(cs_sp_write_temp_buf),
        .cs_reg_file_out1_sel_sel(cs_reg_file_out1_sel_sel),
        .cs_write_addr_buffer(cs_write_addr_buffer),
        .cs_addr_buffer_sel(cs_addr_buffer_sel),
        .cs_write_flag_z(cs_write_flag_z),
        .cs_write_flag_c(cs_write_flag_c),
        .cs_flag_n_sel(cs_flag_n_sel),
        .cs_flag_c_sel(cs_flag_c_sel),
        .cs_pc_write_temp_buf(cs_pc_write_temp_buf),
        .cs_write_flag_h(cs_write_flag_h),
        .cs_write_flag_n(cs_write_flag_n),
        .cs_reg_file_write_reg(cs_reg_file_write_reg),
        .cs_sp_temp_buf_sel(cs_sp_temp_buf_sel),
        .cs_cu_toggle_cb(cs_cu_toggle_cb),
        .cs_shift_in_sel(cs_shift_in_sel),
        .cs_set_ime(cs_set_ime),
        .cs_clear_ime(cs_clear_ime),
        .cs_ack_interrupt(cs_ack_interrupt),
        .cs_set_halt(cs_set_halt),

        .control_signals(control_signals)
    );


endmodule

