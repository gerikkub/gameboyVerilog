`timescale 1ns / 1ns

`include "srcs/lcd/memory_video.v"
`include "srcs/lcd/memory_obj.v"
`include "srcs/lcd/lcd_reg.v"
`include "srcs/lcd/lcd_fsm.v"

module lcd(

    input clock,
    input nreset,
    inout [7:0]db_data,
    input [15:0]db_address,
    input db_nread,
    input db_nwrite,

    output [1:0]color_out,
    output px_valid_out,
    output [7:0]x_pos_out,
    output [7:0]y_pos_out
    );

    wire [7:0]x_pos;
    wire [7:0]y_pos;

    wire lcd_nreset;
    assign lcd_nreset = nreset == 'd0 || lcd_en == 'd0 ? 'd0 : 'd1;

    // Convert pixel FIFO values to GB colors
    wire pixel_valid;
    wire [1:0]pixel_data;
    wire [1:0]pixel_palette_n;
    wire [7:0]pixel_palette;

    assign pixel_palette = pixel_palette_n == 'd0 ? bg_palette :
                           pixel_palette_n == 'd1 ? obp0_palette :
                           pixel_palette_n == 'd2 ? obp1_palette :
                           'hFF;

    assign color_out = pixel_data == 'd0 ? pixel_palette[1:0] :
                       pixel_data == 'd1 ? pixel_palette[3:2] :
                       pixel_data == 'd2 ? pixel_palette[5:4] :
                       pixel_palette[7:6];
    assign px_valid_out = pixel_valid;
    assign x_pos_out = x_pos;
    assign y_pos_out = y_pos;

    // Registers
    // LCD Control
    wire lcd_en;
    wire window_map_sel;
    wire window_en;
    wire bg_window_data_sel;
    wire bg_map_sel;
    wire obj_size_sel;
    wire obj_en;
    wire bg_window_prio;

    // LCD Status
    wire stat_int_lyc_lc_en;
    wire stat_int_mode2_en;
    wire stat_int_mode1_en;
    wire stat_int_mode0_en;
    wire flag_lyc_ly_eq;
    wire [1:0]flag_mode_n;

    // Scroll X/Y
    wire [7:0]bg_scroll_y;
    wire [7:0]bg_scroll_x;

    // LY Coordinate
    wire [7:0]ly_coord;
    assign ly_coord = y_pos_out;

    // LY Compare
    wire [7:0]ly_compare;

    // Window X/Y
    wire [7:0]window_y;
    wire [7:0]window_x;

    // Palettes
    wire [7:0]bg_palette;
    wire [7:0]obp0_palette;
    wire [7:0]obp1_palette;

    // DMA
    wire [7:0]dma_src;
    wire dma_start;

    lcd_reg lcd_reg(
        .clock(clock),
        .nreset(nreset),
        .db_data(db_data),
        .db_address(db_address),
        .nread(db_nread),
        .nwrite(db_nwrite),

        .lcd_en(lcd_en),
        .window_map_sel(window_map_sel),
        .window_en(window_en),
        .bg_window_data_sel(bg_window_data_sel),
        .bg_map_sel(bg_map_sel),
        .obj_size_sel(obj_size_sel),
        .obj_en(obj_en),
        .bg_window_prio(bg_window_prio),

        .stat_int_lyc_lc_en(stat_int_lyc_lc_en),
        .stat_int_mode2_en(stat_int_mode2_en),
        .stat_int_mode1_en(stat_int_mode1_en),
        .stat_int_mode0_en(stat_int_mode0_en),
        .flag_lyc_ly_eq(flag_lyc_ly_eq),
        .flag_mode_n(flag_mode_n),

        .bg_scroll_y(bg_scroll_y),
        .bg_scroll_x(bg_scroll_x),

        .ly_coord(ly_coord),

        .ly_compare(ly_compare),

        .window_y(window_y),
        .window_x(window_x),

        .bg_palette(bg_palette),
        .obp0_palette(obp0_palette),
        .obp1_palette(obp1_palette),

        .dma_src(dma_src),
        .dma_start(dma_start)
    );

    lcd_fsm lcd_fsm(
        .clock(clock),
        .nreset(lcd_nreset),
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

        .vram_db_address(int_vram_db_address),
        .vram_db_data(vram_db_data_read),
        .vram_db_nread(int_vram_nread),

        .objram_db_address(int_objram_db_address),
        .objram_db_data(objram_db_data_read),
        .objram_db_nread(int_objram_nread),

        .mode_n(flag_mode_n),
        .x_pos_out(x_pos_out),
        .y_pos_out(y_pos_out),

        .pixel_valid(pixel_valid),
        .pixel_data(pixel_data),
        .palette(pixel_palette_n)
    );

    wire ext_vram_access;
    wire ext_objram_access;

    wire [15:0]int_vram_db_address;
    wire [15:0]int_objram_db_address;

    // Arbitrate access to VRAM and OAM ram depending
    // on internal access state, driven by
    //  ext_vram_access
    //  ext_objram_access

    wire [15:0]vram_db_address;
    wire [7:0]vram_db_data_read;
    wire [15:0]objram_db_address;
    wire [7:0]objram_db_data_read;

    wire int_vram_nread;
    wire int_objram_nread;

    wire vram_nread;
    wire vram_nwrite;
    wire objram_nread;
    wire objram_nwrite;

    assign ext_vram_access = (flag_mode_n == 'd0 || flag_mode_n == 'd1 || flag_mode_n == 'd2 || lcd_en == 'd0);
    assign ext_objram_access = (flag_mode_n == 'd0 || flag_mode_n == 'd1 || lcd_en == 'd0);

    assign vram_nread = ext_vram_access == 'b1 ? db_nread : int_vram_nread;
    assign objram_nread = ext_objram_access == 'b1 ? db_nread : int_objram_nread;

    assign vram_nwrite = ext_vram_access == 'b1 ? db_nwrite : 'b1;
    assign objram_nwrite = ext_objram_access == 'b1 ? db_nwrite : 'b1;

    assign vram_db_address = ext_vram_access == 'b1 ? db_address : int_vram_db_address;
    assign objram_db_address = ext_objram_access == 'b1 ? db_address : int_objram_db_address;

    assign db_data = ext_vram_access == 'b1 && vram_nread == 'b0 ? vram_db_data_read :
                     ext_objram_access == 'b1 && objram_nread == 'b0 ? objram_db_data_read :
                     8'bZ;

    memory_video memory_video(
        .clock(clock),
        .address_bus(vram_db_address),
        .data_bus_read(vram_db_data_read),
        .data_bus_write(db_data),
        .nread(vram_nread),
        .nwrite(vram_nwrite)
    );

    memory_obj memory_obj(
        .clock(clock),
        .address_bus(objram_db_address),
        .data_bus_read(objram_db_data_read),
        .data_bus_write(db_data),
        .nread(objram_nread),
        .nwrite(objram_nwrite)
    );

endmodule;