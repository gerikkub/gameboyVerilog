`timescale 1ns / 1ps 
 
module microcode_mod( 
    input [5:0]opcode, 
    output [58:0]control_signals 
    ); 
 
    parameter opcode_table_size = 61; 
 
    parameter subop_table_size = 27; 
 
    reg [4:0]opcode_table[0:opcode_table_size-1]; 
    reg [58:0]subop_table[0:subop_table_size-1]; 
 
    initial $readmemh("srcs/opcode_vector.txt", opcode_table); 
    initial $readmemh("srcs/subop_vector.txt", subop_table); 
     
    wire [4:0]opcode_table_out; 
    wire [58:0]subop_table_out; 
 
    assign opcode_table_out = opcode_table[opcode]; 
 
    assign subop_table_out = subop_table[opcode_table_out]; 
 
    assign control_signals = subop_table_out; 
 
 
 endmodule