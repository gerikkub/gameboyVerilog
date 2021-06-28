`timescale 1ns / 1ps 
 
module cs_mapper_mod( 
 
output [1:0]cs_sp_temp_buf_sel,
output cs_set_ime,
output [2:0]cs_flag_z_sel,
output cs_db_nwrite,
output [1:0]cs_alu_in_C_sel,
output [2:0]cs_alu_op_sel,
output [1:0]cs_pc_offset_sel,
output [2:0]cs_flag_h_sel,
output [2:0]cs_reg_file_out2_sel_sel,
output cs_shift_in_sel,
output [2:0]cs_reg_file_data_in_sel_sel,
output [2:0]cs_sp_sel,
output cs_write_inst_buffer,
output cs_ack_interrupt,
output [3:0]cs_pc_sel,
output [2:0]cs_reg_file_data_in_sel,
output cs_write_data_buffer2,
output cs_write_data_buffer1,
output [1:0]cs_cu_adv_sel,
output cs_db_nread,
output [1:0]cs_flag_n_sel,
output [2:0]cs_db_address_sel,
output [3:0]cs_db_data_sel,
output cs_reg_file_write_reg,
output cs_write_temp_flag_c,
output cs_write_data_bus_buffer,
output [1:0]cs_alu_in_A_sel,
output cs_cu_toggle_cb,
output [2:0]cs_alu_in_B_sel,
output cs_sp_write_temp_buf,
output cs_clear_ime,
output [2:0]cs_reg_file_out1_sel_sel,
output cs_write_addr_buffer,
output [1:0]cs_addr_buffer_sel,
output cs_write_flag_z,
output cs_write_flag_c,
output cs_set_halt,
output [2:0]cs_flag_c_sel,
output cs_pc_write_temp_buf,
output cs_write_flag_h,
output cs_write_flag_n,
input [75:0]control_signals 
        ); 
        
assign cs_sp_temp_buf_sel = control_signals[1:0];
assign cs_set_ime = control_signals[2];
assign cs_flag_z_sel = control_signals[5:3];
assign cs_db_nwrite = control_signals[6];
assign cs_alu_in_C_sel = control_signals[58:57];
assign cs_alu_op_sel = control_signals[9:7];
assign cs_pc_offset_sel = control_signals[11:10];
assign cs_flag_h_sel = control_signals[14:12];
assign cs_reg_file_out2_sel_sel = control_signals[17:15];
assign cs_shift_in_sel = control_signals[18];
assign cs_reg_file_data_in_sel_sel = control_signals[21:19];
assign cs_sp_sel = control_signals[24:22];
assign cs_write_inst_buffer = control_signals[25];
assign cs_ack_interrupt = control_signals[26];
assign cs_pc_sel = control_signals[30:27];
assign cs_reg_file_data_in_sel = control_signals[33:31];
assign cs_write_data_buffer2 = control_signals[34];
assign cs_write_data_buffer1 = control_signals[35];
assign cs_cu_adv_sel = control_signals[37:36];
assign cs_db_nread = control_signals[38];
assign cs_flag_n_sel = control_signals[69:68];
assign cs_db_address_sel = control_signals[42:40];
assign cs_db_data_sel = control_signals[46:43];
assign cs_reg_file_write_reg = control_signals[48];
assign cs_write_temp_flag_c = control_signals[49];
assign cs_write_data_bus_buffer = control_signals[50];
assign cs_alu_in_A_sel = control_signals[52:51];
assign cs_cu_toggle_cb = control_signals[53];
assign cs_alu_in_B_sel = control_signals[56:54];
assign cs_sp_write_temp_buf = control_signals[47];
assign cs_clear_ime = control_signals[59];
assign cs_reg_file_out1_sel_sel = control_signals[62:60];
assign cs_write_addr_buffer = control_signals[63];
assign cs_addr_buffer_sel = control_signals[65:64];
assign cs_write_flag_z = control_signals[66];
assign cs_write_flag_c = control_signals[67];
assign cs_set_halt = control_signals[39];
assign cs_flag_c_sel = control_signals[72:70];
assign cs_pc_write_temp_buf = control_signals[73];
assign cs_write_flag_h = control_signals[74];
assign cs_write_flag_n = control_signals[75];
endmodule