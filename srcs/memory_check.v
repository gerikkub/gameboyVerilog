`timescale 1ns / 1ns

module memory_check(
    input clock,
    input reset,

    input [15:0]address_bus,

    inout [7:0]data_bus,

    input nread,
    input nwrite,
    input nsel
    );

    reg [23:0]read_locations[0:39999999];
    reg [23:0]write_locations[0:2999999];

    initial $readmemh("sims/memread_check.txt", read_locations);
    initial $readmemh("sims/memwrite_check.txt", write_locations);

    integer read_idx = 0;
    integer write_idx = 0;

    wire [15:0]read_addr;
    wire [7:0]read_data;

    wire [15:0]write_addr;
    wire [7:0]write_data;

    assign read_addr = read_locations[read_idx][23:8];
    assign read_data = read_locations[read_idx][7:0];

    assign write_addr = write_locations[write_idx][23:8];
    assign write_data = write_locations[write_idx][7:0];

    assign data_bus = (nread == 'd0 && nsel == 'd0) ? read_data : 'dZ;

    always @(posedge clock)
    begin
        if (reset == 'd0)
        begin
            read_idx = 0;
            write_idx = 0;
        end else begin
            if (nread == 'd0 &&
                nsel == 'd0)
            begin
                if (address_bus != read_addr)
                begin
                    $display("Invalid address at read idx %d Exp %H Recv %H", read_idx, read_addr, address_bus);
                    $finish;
                end

                read_idx++;
            end else if (nwrite == 'd0 &&
                nsel == 'd0)
            begin
                if (address_bus != write_addr)
                begin
                    $display("Invalid address at write idx %d Exp %H Recv %H", write_idx, write_addr, address_bus);
                    $finish;
                end

                if (data_bus != write_data)
                begin
                    $display("Invalid data at write idx %d Exp %H Recv %H", write_idx, write_data, data_bus);
                    $finish;
                end

                write_idx++;
            end
        end
    end

endmodule
