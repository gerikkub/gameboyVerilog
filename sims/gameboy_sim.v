`timescale 1ns / 1ns

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

    reg [91:0]inst_check_table[0:255];
    integer check_idx = 0;

    initial $readmemh("sims/inst_check.txt", inst_check_table);

    wire inst_tick;
    wire check_wire;

    assign inst_tick = intercon.core.cs_cu_adv_sel & intercon.core.cu_mod.adv_buffer;

    assign check_wire = { intercon.core.pc_out_direct,
                          intercon.core.sp_out,

                          intercon.core.reg_file.reg_b,
                          intercon.core.reg_file.reg_c,
                          intercon.core.reg_file.reg_d,
                          intercon.core.reg_file.reg_e,
                          intercon.core.reg_file.reg_h,
                          intercon.core.reg_file.reg_l,
                          intercon.core.reg_file.reg_a,
                          intercon.core.flag_z,
                          intercon.core.flag_n,
                          intercon.core.flag_h,
                          intercon.core.flag_c};

    initial
    begin
        $dumpfile("dump.vcd");
        $dumpvars(0, gameboy_sim);

        #25
        reset = 'd0;
        #20
        reset = 'd1;
    end

    always @(posedge clock)
    begin
        if (inst_tick === 'd1)
        begin
            if (inst_check_table[check_idx] !== check_wire)
            begin
                $display("Error checks did not match");
                $display("Expected: %H Received %H", inst_check_table[check_idx], check_wire);
                $finish;
            end
        end

        check_idx = check_idx + 1;
    end
            

endmodule

