`timescale 1ns / 1ps 
 
module cs_mapper_mod( 
 
output [1:0]cs_sp_temp_buf_sel,
output [1:0]cs_flag_z_sel,
output cs_db_nwrite,
output [1:0]cs_alu_in_C_sel,
output [2:0]cs_alu_op_sel,
output [1:0]cs_pc_offset_sel,
output [1:0]cs_flag_h_sel,
output [2:0]cs_reg_file_out2_sel_sel,
output [2:0]cs_reg_file_data_in_sel_sel,
output [2:0]cs_sp_sel,
output cs_write_inst_buffer,
output [2:0]cs_pc_sel,
output [2:0]cs_reg_file_data_in_sel,
output cs_write_data_buffer2,
output cs_write_data_buffer1,
output [1:0]cs_cu_adv_sel,
output cs_write_data_bus_buffer,
output [2:0]cs_db_address_sel,
output [2:0]cs_db_data_sel,
output cs_reg_file_write_reg,
output cs_write_temp_flag_c,
output cs_db_nread,
output [1:0]cs_alu_in_A_sel,
output [1:0]cs_alu_in_B_sel,
output cs_sp_write_temp_buf,
output [2:0]cs_reg_file_out1_sel_sel,
output cs_write_addr_buffer,
output [1:0]cs_addr_buffer_sel,
output cs_write_flag_z,
output cs_write_flag_c,
output cs_flag_n_sel,
output [2:0]cs_flag_c_sel,
output cs_pc_write_temp_buf,
output cs_write_flag_h,
output cs_write_flag_n,
input [63:0]control_signals 
        ); 
        
assign cs_sp_temp_buf_sel = control_signals[1:0];
assign cs_flag_z_sel = control_signals[3:2];
assign cs_db_nwrite = control_signals[4];
assign cs_alu_in_C_sel = control_signals[48:47];
assign cs_alu_op_sel = control_signals[7:5];
assign cs_pc_offset_sel = control_signals[9:8];
assign cs_flag_h_sel = control_signals[11:10];
assign cs_reg_file_out2_sel_sel = control_signals[14:12];
assign cs_reg_file_data_in_sel_sel = control_signals[17:15];
assign cs_sp_sel = control_signals[20:18];
assign cs_write_inst_buffer = control_signals[21];
assign cs_pc_sel = control_signals[24:22];
assign cs_reg_file_data_in_sel = control_signals[27:25];
assign cs_write_data_buffer2 = control_signals[28];
assign cs_write_data_buffer1 = control_signals[29];
assign cs_cu_adv_sel = control_signals[31:30];
assign cs_write_data_bus_buffer = control_signals[42];
assign cs_db_address_sel = control_signals[35:33];
assign cs_db_data_sel = control_signals[38:36];
assign cs_reg_file_write_reg = control_signals[40];
assign cs_write_temp_flag_c = control_signals[41];
assign cs_db_nread = control_signals[32];
assign cs_alu_in_A_sel = control_signals[44:43];
assign cs_alu_in_B_sel = control_signals[46:45];
assign cs_sp_write_temp_buf = control_signals[39];
assign cs_reg_file_out1_sel_sel = control_signals[51:49];
assign cs_write_addr_buffer = control_signals[52];
assign cs_addr_buffer_sel = control_signals[54:53];
assign cs_write_flag_z = control_signals[55];
assign cs_write_flag_c = control_signals[56];
assign cs_flag_n_sel = control_signals[57];
assign cs_flag_c_sel = control_signals[60:58];
assign cs_pc_write_temp_buf = control_signals[61];
assign cs_write_flag_h = control_signals[62];
assign cs_write_flag_n = control_signals[63];
endmodule