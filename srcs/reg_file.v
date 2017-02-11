`timescale 1ns / 1ns

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

    initial
    begin
        true_registers[0] = 'h00;
        true_registers[1] = 'h00;
        true_registers[2] = 'hFF;
        true_registers[3] = 'h56;
        true_registers[4] = 'h00;
        true_registers[5] = 'h0D;
        true_registers[6] = 'h11;
    end

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

    always @(posedge clock)
    begin

        for (i = 0; i < 7; i++)
        begin
            true_registers[i] = true_registers[i];
        end

        if (write_reg == 'd1)
        begin
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

    end

    wire [7:0]reg_b;
    wire [7:0]reg_c;
    wire [7:0]reg_d;
    wire [7:0]reg_e;
    wire [7:0]reg_h;
    wire [7:0]reg_l;
    wire [7:0]reg_a;

    assign reg_b = true_registers[0];
    assign reg_c = true_registers[1];
    assign reg_d = true_registers[2];
    assign reg_e = true_registers[3];
    assign reg_h = true_registers[4];
    assign reg_l = true_registers[5];
    assign reg_a = true_registers[6];

    wire [15:0]debug_reg_bc;
    wire [15:0]debug_reg_de;
    wire [15:0]debug_reg_hl;

    assign debug_reg_bc = {reg_b, reg_c};
    assign debug_reg_de = {reg_d, reg_e};
    assign debug_reg_hl = {reg_h, reg_l};

endmodule

