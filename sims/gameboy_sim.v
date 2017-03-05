`timescale 1ns / 1ns

`include "sims/interconnect_memcheck.v"

module gameboy_sim(
    );

    reg clock = 'd0;
    reg reset = 'd1;

    interconnect_memcheck intercon(
        .clock(clock),
        .reset(reset)
    );

    always #10 clock = ~clock;

    reg [91:0]inst_check_table[0:7999999];
    integer check_idx = 0;

    initial $readmemh("sims/inst_check.txt", inst_check_table);

    wire inst_tick;
    wire [91:0]check_wire;

    assign inst_tick = intercon.core.cs_cu_adv_sel & intercon.core.cu_mod.adv_buffer & (~intercon.core.cu_mod.cb_inst_active);

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
        check_idx = 0;
    end

    integer percent = 0;
    integer old_percent = 0;

    always @(posedge clock)
    begin
        if (inst_tick === 'd1)
        begin

            percent = (check_idx * 100) / 7475931;
            //$display("%d %d %d", percent, old_percent, check_idx);
            if (percent > old_percent)
            begin
                $display("%d%%", percent);
                old_percent = percent;
            end
            
            //$display("Expected: %H Received %H", inst_check_table[check_idx], check_wire);

            if (inst_check_table[check_idx] !== check_wire)
            begin
                $display("Error checks did not match at idx %d", check_idx);
                $display("Expected: %H Received %H", inst_check_table[check_idx], check_wire);
                $finish;
            end
            check_idx = check_idx + 1;
        end

    end
            

endmodule

