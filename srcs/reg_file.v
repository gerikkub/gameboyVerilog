`timescale 1ns / 1ps

module reg_file(
    input clock,

    input [2:0]out1_sel,
    input [2:0]out2_sel,

    input [7:0]data_in,
    input [2:0]data_in_sel,
    input write_reg,

    output [7:0]out1,
    output [7:0]out2
    );


    reg [7:0]true_registers[6:0];

    wire [7:0]registers[7:0];

    assign registers[0] = true_registers[0];
    assign registers[1] = true_registers[1];
    assign registers[2] = true_registers[2];
    assign registers[3] = true_registers[3];
    assign registers[4] = true_registers[4];
    assign registers[5] = true_registers[5];
    assign registers[6] = 'd0; // Use (HL) as a zero register
    assign registers[7] = true_registers[6];

    assign out1 = registers[out1_sel];
    assign out2 = registers[out2_sel];

    integer i;

    initial
    begin
        for (i = 0; i < 7; i++)
        begin
            true_registers[i] = 'd0;
        end
    end


    always @(posedge clock)
    begin

        for (i = 0; i < 7; i++)
        begin
            true_registers[i] = true_registers[i];
        end

        case (data_in_sel)
            'd0: true_registers[0] = data_in;
            'd1: true_registers[1] = data_in;
            'd2: true_registers[2] = data_in;
            'd3: true_registers[3] = data_in;
            'd4: true_registers[4] = data_in;
            'd5: true_registers[5] = data_in;
            'd6: true_registers[0] = true_registers[0];
            'd7: true_registers[6] = data_in;
        endcase

    end

endmodule

