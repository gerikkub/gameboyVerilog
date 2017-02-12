`timescale 1ns / 1ps 
 
module cs_mapper_mod( 
 
output [1:0]cs_sp_temp_buf_sel,
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
output [2:0]cs_pc_sel,
output [2:0]cs_reg_file_data_in_sel,
output cs_write_data_buffer2,
output cs_write_data_buffer1,
output [1:0]cs_cu_adv_sel,
output cs_db_nread,
output [2:0]cs_db_address_sel,
output [2:0]cs_db_data_sel,
output cs_reg_file_write_reg,
output cs_write_temp_flag_c,
output cs_write_data_bus_buffer,
output [1:0]cs_alu_in_A_sel,
output cs_cu_toggle_cb,
output [1:0]cs_alu_in_B_sel,
output cs_sp_write_temp_buf,
output [2:0]cs_reg_file_out1_sel_sel,
output cs_write_addr_buffer,
output [1:0]cs_addr_buffer_sel,
output cs_write_flag_z,
output cs_write_flag_c,
output [1:0]cs_flag_n_sel,
output [2:0]cs_flag_c_sel,
output cs_pc_write_temp_buf,
output cs_write_flag_h,
output cs_write_flag_n,
input [68:0]control_signals 
        ); 
        
assign cs_sp_temp_buf_sel = control_signals[1:0];
assign cs_flag_z_sel = control_signals[4:2];
assign cs_db_nwrite = control_signals[5];
assign cs_alu_in_C_sel = control_signals[52:51];
assign cs_alu_op_sel = control_signals[8:6];
assign cs_pc_offset_sel = control_signals[10:9];
assign cs_flag_h_sel = control_signals[13:11];
assign cs_reg_file_out2_sel_sel = control_signals[16:14];
assign cs_shift_in_sel = control_signals[17];
assign cs_reg_file_data_in_sel_sel = control_signals[20:18];
assign cs_sp_sel = control_signals[23:21];
assign cs_write_inst_buffer = control_signals[24];
assign cs_pc_sel = control_signals[27:25];
assign cs_reg_file_data_in_sel = control_signals[30:28];
assign cs_write_data_buffer2 = control_signals[31];
assign cs_write_data_buffer1 = control_signals[32];
assign cs_cu_adv_sel = control_signals[34:33];
assign cs_db_nread = control_signals[35];
assign cs_db_address_sel = control_signals[38:36];
assign cs_db_data_sel = control_signals[41:39];
assign cs_reg_file_write_reg = control_signals[43];
assign cs_write_temp_flag_c = control_signals[44];
assign cs_write_data_bus_buffer = control_signals[45];
assign cs_alu_in_A_sel = control_signals[47:46];
assign cs_cu_toggle_cb = control_signals[48];
assign cs_alu_in_B_sel = control_signals[50:49];
assign cs_sp_write_temp_buf = control_signals[42];
assign cs_reg_file_out1_sel_sel = control_signals[55:53];
assign cs_write_addr_buffer = control_signals[56];
assign cs_addr_buffer_sel = control_signals[58:57];
assign cs_write_flag_z = control_signals[59];
assign cs_write_flag_c = control_signals[60];
assign cs_flag_n_sel = control_signals[62:61];
assign cs_flag_c_sel = control_signals[65:63];
assign cs_pc_write_temp_buf = control_signals[66];
assign cs_write_flag_h = control_signals[67];
assign cs_write_flag_n = control_signals[68];
endmodule