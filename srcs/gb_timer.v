`timescale 1ns / 1ns


module gb_timer(
    input clock,
    input nreset,

    input reset_div,

    input [15:0]db_address,
    inout [7:0]db_data,

    input nread,
    input nwrite,

    output int_timer
    );

    reg [7:0]reg_div;
    reg [7:0]reg_tima;
    reg [7:0]reg_tma;
    reg [2:0]reg_tac;

    reg [7:0]div_prescale_counter;

    reg [9:0]tma_prescale_counter;
    wire [9:0]tma_prescale_compare;

    // Register reads
    assign db_data = (nread == 'd1) ? 8'bz :
                     (db_address == 'hFF04) ? reg_div :
                     (db_address == 'hFF05) ? reg_tima :
                     (db_address == 'hFF06) ? reg_tma :
                     (db_address == 'hFF07) ? {5'b0, reg_tac} :
                     8'bz;

    // DIV register logic
    always @(posedge clock)
    begin
        if (nreset == 'd0 || reset_div == 'd1)
        begin
            reg_div <= 'd0;
            div_prescale_counter <= 'd0;
        end else begin
            if (nwrite == 'd0 && db_address == 'hFF04)
            begin
                reg_div <= 'd0;
                div_prescale_counter <= 'd0;
            end else begin
                if (div_prescale_counter == 'hFF)
                begin
                    reg_div <= reg_div + 'd1;
                end else begin
                    reg_div <= reg_div;
                end

                div_prescale_counter <= div_prescale_counter + 'd1;
            end
        end
    end

    // TIMA logic
    wire tac_tima_enable;
    wire [1:0]tac_tima_select;

    assign tac_tima_enable = reg_tac[2];
    assign tac_tima_select = reg_tac[1:0];

    assign tma_prescale_compare = (tac_tima_select == 'd0) ? 'd1023 :
                                  (tac_tima_select == 'd1) ? 'd15 :
                                  (tac_tima_select == 'd2) ? 'd63 :
                                  'd255;
    
    assign int_timer = nreset == 'd1 && 
                       tac_tima_enable == 'd1 &&
                       reg_tima == 'hFF &&
                       (tma_prescale_counter & tma_prescale_compare) == tma_prescale_compare;



    // TMA and TAC register writes
    always @(posedge clock)
    begin
        if (nreset == 'd0)
        begin
            reg_tma <= 'd0;
            reg_tac <= 'd0;
        end else begin
            // TMA
            if (nwrite == 'd0 && db_address == 'hFF06)
            begin
                reg_tma <= db_data;
            end else begin
                reg_tma <= reg_tma;
            end

            if (nwrite == 'd0 && db_address == 'hFF07)
            begin
                reg_tac <= db_data[2:0];
            end else begin
                reg_tac <= reg_tac;
            end
        end
    end

    // TIMA counting and interrupt
    always @(posedge clock)
    begin
        if (nreset == 'd0)
        begin
            reg_tima <= 'd0;
        end else begin
            if (tac_tima_enable == 'd0)
            begin
                reg_tima <= reg_tima;
            end else begin
                if ((tma_prescale_counter & tma_prescale_compare) == tma_prescale_compare)
                begin
                    // Increment the counter
                    if (reg_tima == 'hFF)
                    begin
                        // Overflow Interrupt
                        reg_tima <= reg_tma;
                    end else begin
                        reg_tima <= reg_tima + 'd1;
                    end
                end
            end
        end
    end

    // TIMA prescaler counting
    always @(posedge clock)
    begin
        if (nreset == 'd0)
        begin
            tma_prescale_counter <= 'd0;
        end else begin
            tma_prescale_counter <= tma_prescale_counter + 'd1;
        end
    end


endmodule