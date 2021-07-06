`timescale 1ns / 1ns

`include "srcs/lcd/lcd_mode3.v"

module lcd_fsm(
    input clock,
    input nreset,

    input window_map_sel,
    input window_en,
    input bg_window_data_sel,
    input bg_map_sel,
    input obj_size_sel,
    input obj_en,
    input bg_window_prio,
    input [7:0]window_y,
    input [7:0]window_x,

    input [7:0]bg_scroll_y,
    input [7:0]bg_scroll_x,

    output [15:0]vram_db_address,
    input [7:0]vram_db_data,
    output vram_db_nread,

    output [15:0]objram_db_address,
    input [7:0]objram_db_data,
    output objram_db_nread,

    output [1:0]mode_n,
    output [7:0]x_pos_out,
    output [7:0]y_pos_out,

    // Pixel Fifo output
    output pixel_valid,
    output [1:0]pixel_data,
    output [1:0]palette
    );

    reg [1:0]mode_n_reg;
    reg [7:0]x_pos;
    reg [7:0]y_pos;

    assign mode_n = mode_n_reg;
    assign y_pos_out = y_pos;
    assign x_pos_out = x_pos;

    // Connect memory buses
    assign vram_db_address = mode_n_reg == 'd3 ? mode3_vram_db_address : 'hAAAA;
    assign vram_db_nread = mode_n_reg == 'd3 ? mode3_vram_db_nread : 'd1;
    assign mode3_vram_db_data = mode_n_reg == 'd3 ? vram_db_data : 'd0;

    assign objram_db_address = mode_n_reg == 'd3 ? mode3_objram_db_address : 'd0;
    assign objram_db_nread = mode_n_reg == 'd3 ? mode3_objram_db_nread : 'd1;
    assign mode3_objram_db_data = mode_n_reg == 'd3 ? objram_db_data : 'd0;

    // States for Mode State Machine
    reg [9:0]line_dot_num;

    wire x_pos_inc;

    // Mode State Machine and y_pos update
    always @(posedge clock)
    begin
        mode_n_reg <= mode_n_reg;
        x_pos <= x_pos;
        line_dot_num <= line_dot_num + 'd1;
        
        if (nreset == 'd0)
        begin
            mode_n_reg <= 'd0;
            y_pos <= 'd0;
            x_pos <= 'd0;
            line_dot_num <= 'd0;
        end else begin
            if (line_dot_num == 'd79 &&
                y_pos <= 'd143)
            begin
                // Start Screen Draw
                mode_n_reg <= 'd3;
            end else if (x_pos == 'd160 &&
                         y_pos <= 'd143)
            begin
                // Start HBlank
                mode_n_reg <= 'd0;
            end else if (line_dot_num == 'd455)
            begin
                if (y_pos >= 'd143 &&
                    y_pos < 'd154)
                begin
                    // Start VBlank
                    mode_n_reg <= 'd1;
                end else begin
                    // Start next line (OAM Search)
                    mode_n_reg <= 'd2;
                    line_dot_num <= 'd0;
                end
            end

            if (line_dot_num == 'd455)
            begin
                x_pos <= 'd0;
                if (y_pos == 'd155)
                begin
                    y_pos <= 'd0;
                end else begin
                    y_pos <= y_pos + 'd1;
                end
            end else begin
                if (x_pos_inc == 'b1)
                begin
                    x_pos <= x_pos + 'd1;
                end
                y_pos <= y_pos;
            end
        end

    end

    wire [15:0]mode3_vram_db_address;
    wire [7:0]mode3_vram_db_data;
    wire mode3_vram_db_nread;

    wire [15:0]mode3_objram_db_address;
    wire [7:0]mode3_objram_db_data;
    wire mode3_objram_db_nread;

    lcd_mode3 lcd_mode3(
        .clock(clock),
        .nreset(nreset),
        .mode_n(mode_n_reg),
        .x_pos(x_pos),
        .y_pos(y_pos),
        .x_inc(x_pos_inc),
        .window_map_sel(window_map_sel),
        .window_en(window_en),
        .bg_window_data_sel(bg_window_data_sel),
        .bg_map_sel(bg_map_sel),
        .obj_size_sel(obj_size_sel),
        .obj_en(obj_en),
        .bg_window_prio(bg_window_prio),
        .window_y(window_y),
        .window_x(window_x),
        .bg_scroll_y(bg_scroll_y),
        .bg_scroll_x(bg_scroll_x),
        .vram_db_address(mode3_vram_db_address),
        .vram_db_data(mode3_vram_db_data),
        .vram_db_nread(mode3_vram_db_nread),
        .objram_db_address(mode3_objram_db_address),
        .objram_db_data(mode3_objram_db_data),
        .objram_db_nread(mode3_objram_db_nread),
        .pixel_valid(pixel_valid),
        .pixel_data(pixel_data),
        .pixel_palette(palette)
    );

endmodule