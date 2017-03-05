`timescale 1ns / 1ns

`include "srcs/core.v"
`include "srcs/memory_check.v"


module interconnect_memcheck(
    input clock,
    input reset
    );

    wire [15:0]address;
    wire [7:0]data;
    wire nread;
    wire nwrite;

    wire nsel;

    assign nsel = nread & nwrite;

    reg mem_clk = 'd1;

    always @(posedge clock)
    begin
        mem_clk <= ~mem_clk;
    end

    core core(
        .clock(clock),
        .reset(reset),
        .db_address(address),
        .db_data(data),
        .db_nread(nread),
        .db_nwrite(nwrite)
    );

    memory_check mcheck(
        .clock(mem_clk),
        .reset(reset),
        .address_bus(address),
        .data_bus(data),
        .nread(nread),
        .nwrite(nwrite),
        .nsel(nsel)
    );

    always @(posedge mem_clk)
    begin
        if (address == 'hFF01)
        begin
            $display("Data: %c", data);
        end
    end

endmodule
