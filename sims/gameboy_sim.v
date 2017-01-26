`timescale 1ns / 1ps

`include "srcs/interconnect.v"

module gameboy_sim(
    );

    reg clock = 'd0;
    reg reset = 'd1;

    interconnect intercon(
        .clock(clock),
        .reset(reset)
    );

    always #10 clock = ~clock;

    initial
    begin
        $dumpfile("dump.vcd");
        $dumpvars(0, gameboy_sim);

        #25
        reset = 'd0;
        #20
        reset = 'd1;

        #4000
        $finish;
    end

endmodule

