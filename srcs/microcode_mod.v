`timescale 1ns / 1ps 
 
module microcode_mod( 
    input [8:0]opcode, 
    output [64:0]control_signals 
    ); 
 
    parameter opcode_table_size = 445; 
 
    parameter subop_table_size = 94; 
 
    reg [6:0]opcode_table[0:opcode_table_size-1]; 
    reg [64:0]subop_table[0:subop_table_size-1]; 
 
    initial $readmemh("srcs/opcode_vector.txt", opcode_table); 
    initial $readmemh("srcs/subop_vector.txt", subop_table); 
     
    wire [6:0]opcode_table_out; 
    wire [64:0]subop_table_out; 
 
    assign opcode_table_out = opcode_table[opcode]; 
 
    assign subop_table_out = subop_table[opcode_table_out]; 
 
    assign control_signals = subop_table_out; 
 
 
 endmodule