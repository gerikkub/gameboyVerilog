`timescale 1ns / 1ns

module daa_mod(
    input [7:0] in,
    input c_in,
    input h_in,
    input n_in,

    output [7:0]out,
    output c_out,
    output z_out
    );

    reg [7:0]add_num;
    reg c_out_reg;

    assign out = in + add_num;

    assign z_out = out == 'd0;
    assign c_out = c_out_reg;

    always @(*)
    begin

        if (n_in == 0)
        begin

            if (c_in == 'd0)
            begin
                if (h_in == 'd0)
                begin
                    
                    if (in[7:4] <= 'h9 &&
                        in[3:0] <= 'h9)
                    begin
                        add_num = 'h00;
                        c_out_reg = 'd0;
                    end else if (in[7:4] <= 'h8)
                    begin
                        add_num = 'h06;
                        c_out_reg = 'd0;
                    end else if (in[3:0] <= 'h9)
                    begin
                        add_num = 'h60;
                        c_out_reg = 'd1;
                    end else
                    begin
                        add_num = 'h66;
                        c_out_reg = 'd1;
                    end
                                 

                end else begin

                    if (in[7:4] <= 'h9)
                    begin
                        if (in[7:4] == 'h9 &&
                            in[3:0] >= 'hA)
                        begin
                            add_num = 'h66;
                            c_out_reg = 'd1;
                        end else begin
                            add_num = 'h06;
                            c_out_reg = 'd0;
                        end
                    end else begin
                        add_num = 'h66;
                        c_out_reg = 'd1;
                    end
                end
            end else begin
                c_out_reg = 'd1;

                if (h_in == 'd0)
                begin

                    if (in[3:0] <= 'h9)
                    begin
                        add_num = 'h60;
                    end else begin
                        add_num = 'h66;
                    end
                end else begin
                    add_num = 'h66;
                end
            end
        end else begin

            if (c_in == 'd0)
            begin

                if (h_in == 'd0)
                begin
                    add_num = 'd0;
                    c_out_reg = 'd0;
                end else begin
                    add_num = 'hFA;
                    c_out_reg = 'd0;
                end
            end else begin

                if (h_in <= 'd0)
                begin
                    add_num = 'hA0;
                    c_out_reg = 'd1;
                end else begin
                    add_num = 'h9A;
                    c_out_reg = 'd1;
                end
            end
        end
    end

endmodule
