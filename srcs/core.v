`timescale 1ns / 1ps

`include "srcs/alu_mod.v"
`include "srcs/control_unit_mod.v"
`include "srcs/pc_mod.v"
`include "srcs/reg_file.v"
`include "srcs/sp_mod.v"

`include "srcs/cs_mapper_mod.v"

module core(
    input clock,
    input reset,

    output [15:0]db_address,
    inout  [7:0]db_data,
    output db_nread,
    output db_nwrite
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
    wire [1:0]cs_db_address_sel;
    wire [1:0]cs_db_data_sel;
    wire cs_db_nwrite;
    wire cs_db_nread;

    parameter db_addr_buffer = 'd0,
              db_addr_pc_offset = 'd1,
              db_addr_sp = 'd2;

    parameter db_data_reg_file_out2 = 'd0,
              db_data_alu = 'd1,
              db_data_pc_offset_p = 'd2,
              db_data_pc_offset_c = 'd3;

    assign db_address = (cs_db_address_sel == db_addr_buffer) ? addr_buffer :
                        (cs_db_address_sel == db_addr_pc_offset) ? pc_out_w_offset :
                        (cs_db_address_sel == db_addr_sp) ? sp_out :
                        'hEEEE; // Should never occur

    assign db_data = (cs_db_nwrite == 'd1) ? 'dZ :
                     (cs_db_data_sel == db_data_reg_file_out2) ? reg_file_out2 :
                     (cs_db_data_sel == db_data_alu) ? alu_out :
                     (cs_db_data_sel == db_data_pc_offset_p) ? pc_out_w_offset[15:8] :
                     (cs_db_data_sel == db_data_pc_offset_c) ? pc_out_w_offset[7:0] :
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
    wire [1:0]cs_flag_z_sel;
    wire cs_flag_n_sel;
    wire [1:0]cs_flag_h_sel;

    parameter flag_c_zero = 'd0,
              flag_c_one = 'd1,
              flag_c_alu = 'd2,
              flag_c_shift = 'd3,
              flag_c_toggle = 'd4;
    
    parameter flag_z_zero = 'd0,
              flag_z_one = 'd1,
              flag_z_alu = 'd2,
              flag_z_shift = 'd3;

    parameter flag_n_zero = 'd0,
              flag_n_one = 'd1;

    parameter flag_h_zero = 'd0,
              flag_h_one = 'd1,
              flag_h_alu = 'd2;

     // Flag muxes
     always @(posedge clock)
     begin         
        if (reset <= 'd0)
        begin
            flag_c <= 'd0;
            flag_z <= 'd0;
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
                    flag_c_shift: flag_c <= 'd0; // TODO
                    flag_c_toggle: flag_c <= ~flag_c;
                    default: flag_c <= 'd1; // Should never occur
                endcase
            end

            if (cs_write_flag_z == 'd0)
            begin
                flag_z <= flag_z;
            end else begin
                case (cs_flag_z_sel)
                    flag_z_zero:  flag_z <= 'd0;
                    flag_z_one:   flag_z <= 'd1;
                    flag_z_alu:   flag_z <= alu_out_flags[3];
                    flag_z_shift: flag_z <= 'd0; // TODO
                    default: flag_z <= 'd1; // Can never occur
                endcase
            end

            if (cs_write_flag_n == 'd0)
            begin
                flag_n <= flag_n;
            end else begin
                case (cs_flag_n_sel)
                    flag_n_zero: flag_n <= 'd0;
                    flag_n_one:  flag_n <= 'd1;
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
              alu_in_B_data_bus_temp = 'd3;

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
    wire [1:0]cs_alu_in_B_sel;
    wire [2:0]cs_alu_op_sel;
    wire [1:0]cs_alu_in_C_sel;

    assign alu_in_A = (cs_alu_in_A_sel == alu_in_A_reg_out1) ? reg_file_out1 :
                      (cs_alu_in_A_sel == alu_in_A_SP_S) ? sp_out[15:8] :
                      (cs_alu_in_A_sel == alu_in_A_SP_P) ? sp_out[7:0] :
                      (cs_alu_in_A_sel == alu_in_A_data_bus_temp) ? data_bus_buffer :
                      'hEE; // Can never occur

    assign alu_in_B = (cs_alu_in_B_sel == alu_in_B_zero) ? 'd0 :
                      (cs_alu_in_B_sel == alu_in_B_one) ? 'd1 :
                      (cs_alu_in_B_sel == alu_in_B_reg_out2) ? reg_file_out2 :
                      (cs_alu_in_B_sel == alu_in_B_data_bus_temp) ? data_bus_buffer :
                      'hEE; // Can never occur

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

    alu_mod alu_m(
        .clock(clock),
        .in_A(alu_in_A),
        .in_B(alu_in_B),
        .alu_op(alu_op),
        .in_C(alu_in_C),
        .out(alu_out),
        .out_flags(alu_out_flags)
    );
    
    // Control Signals for PC
    wire [2:0]pc_rst_in;
    wire [2:0]pc_int_in;

    wire [2:0]cs_pc_sel;
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
        .pc_sel(cs_pc_sel),
        .offset_sel(cs_pc_offset_sel),
        .write_temp_buf(cs_pc_write_temp_buf),
        .pc_w_offset(pc_out_w_offset),
        .pc(pc_out_direct)
    );

    // Control Signals for SP
    wire [2:0]cs_sp_sel;
    wire cs_sp_write_temp_buf;

    wire [15:0]sp_out;

    sp_mod sp_mod(
        .clock(clock),
        .reset(reset),
        .sp_sel(cs_sp_sel),
        .data_bus(db_data),
        .write_temp_buf(cs_sp_write_temp_buf),
        .sp(sp_out)
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

    parameter reg_file_out1_inst53 = 'd0,
              reg_file_out1_inst54_zero = 'd1,
              reg_file_out1_inst54_one  = 'd2,
              reg_file_out1_A = 'd3,
              reg_file_out1_H = 'd4,
              reg_file_out1_L = 'd5;

    parameter reg_file_out2_inst20 = 'd0,
              reg_file_out2_inst53 = 'd1,
              reg_file_out2_inst54_zero = 'd2,
              reg_file_out2_inst54_one = 'd3,
              reg_file_out2_H = 'd4,
              reg_file_out2_L = 'd5;

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
              reg_file_data_in_sel_L = 'd5;

    assign reg_file_out1_sel = (cs_reg_file_out1_sel_sel == reg_file_out1_inst53) ? inst_buffer[5:3] :
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
                               'b110; // Should never occur

    assign reg_file_data_in = (cs_reg_file_data_in_sel == reg_file_data_in_data_bus) ? db_data :
                              (cs_reg_file_data_in_sel == reg_file_data_in_alu) ? alu_out :
                              (cs_reg_file_data_in_sel == reg_file_data_in_shift) ? 'd0 : // TODO
                              (cs_reg_file_data_in_sel == reg_file_data_in_daa) ? 'd0 : // TODO
                              (cs_reg_file_data_in_sel == reg_file_data_in_cpl) ? 'd0 : // TODO
                              (cs_reg_file_data_in_sel == reg_file_data_in_out2) ? reg_file_out2 :
                              'hEE; // Should never occur

    assign reg_file_data_in_sel = (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_inst53) ? inst_buffer[5:3] :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_inst54_zero) ? {inst_buffer[5:4], 1'd0} :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_inst54_one)  ? {inst_buffer[5:4], 1'd1} :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_A) ? 'b111 :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_H) ? 'b100 :
                                  (cs_reg_file_data_in_sel_sel == reg_file_data_in_sel_L) ? 'b101 :
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
    
    // Control signals for Control Unit
    wire [1:0]cs_cu_adv_sel;

    wire flag_adv;
    wire [59:0]control_signals;

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
        .control_signals(control_signals)
    );

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

        .control_signals(control_signals)
    );


endmodule

