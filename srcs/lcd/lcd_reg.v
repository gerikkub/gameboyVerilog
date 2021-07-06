`timescale 1ns / 1ns

module lcd_reg(
    input clock,
    input nreset,
    inout [7:0]db_data,
    input [15:0]db_address,

    input nread,
    input nwrite,

    // LCD Control
    output lcd_en,
    output window_map_sel,
    output window_en,
    output bg_window_data_sel,
    output bg_map_sel,
    output obj_size_sel,
    output obj_en,
    output bg_window_prio,

    // LCD Status
    output stat_int_lyc_lc_en,
    output stat_int_mode2_en,
    output stat_int_mode1_en,
    output stat_int_mode0_en,
    input  flag_lyc_ly_eq,
    input  [1:0]flag_mode_n,

    // Scroll X/Y
    output [7:0]bg_scroll_y,
    output [7:0]bg_scroll_x,

    // LY Coordinate
    input [7:0]ly_coord,

    // LY Compare
    output [7:0]ly_compare,

    // Window X/Y
    output [7:0]window_y,
    output [7:0]window_x,

    // Palettes
    output [7:0]bg_palette,
    output [7:0]obp0_palette,
    output [7:0]obp1_palette,

    // DMA
    output [7:0]dma_src,
    output dma_start
    );

    // LCD Control (FF40)
    reg [7:0]lcdc_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF40 ? lcdc_reg : 8'dZ;

    assign lcd_en = lcdc_reg[7];
    assign window_map_sel = lcdc_reg[6];
    assign window_en = lcdc_reg[5];
    assign bg_window_data_sel = lcdc_reg[4];
    assign bg_map_sel = lcdc_reg[3];
    assign obj_size_sel = lcdc_reg[2];
    assign obj_en = lcdc_reg[1];
    assign bg_window_prio = lcdc_reg[0];

    // LCD Status (FF41)
    reg [3:0]stat_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF41 ?
                     {1'b0, stat_reg, flag_lyc_ly_eq, flag_mode_n} : 8'dZ;

    assign stat_int_lyc_lc_en = stat_reg[3];
    assign stat_int_mode2_en = stat_reg[2];
    assign stat_int_mode1_en = stat_reg[1];
    assign stat_int_mode0_en = stat_reg[0];

    // Scroll Y (FF42) / Scroll X (FF43)
    reg [7:0]scy_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF42 ? scy_reg : 8'dZ;

    assign bg_scroll_y = scy_reg;

    reg [7:0]scx_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF43 ? scx_reg : 8'dZ;

    assign bg_scroll_x = scx_reg;

    // LY Coordinate (FF44)
    // No modifiable state
    assign db_data = nread == 'd0 && db_address == 'hFF44 ? ly_coord : 8'dZ;

    // LY Compare (FF45)
    reg [7:0]lyc_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF45 ? lyc_reg : 8'dZ;

    // Window Y (FF4A) / Window X (FF4B)
    reg [7:0]wy_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF4A ? wy_reg : 8'dZ;

    assign window_y = wy_reg;

    reg [7:0]wx_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF4B ? wx_reg : 8'dZ;

    assign window_x = wx_reg;

    // Background Palette (FF47)
    // Object Palette Data 0 (FF48)
    // Object Palette Data 1 (FF49)
    reg [7:0]bgp_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF47 ? bgp_reg : 8'dZ;

    assign bg_palette = bgp_reg;

    reg [7:0]obp0_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF48 ? obp0_reg : 8'dZ;

    assign obp0_palette = obp0_reg;

    reg [7:0]obp1_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF49 ? obp1_reg : 8'dZ;
    assign obp1_palette = obp1_reg;

    // DMA Transfer and Start Address (FF46)
    reg [7:0]dma_reg;
    assign db_data = nread == 'd0 && db_address == 'hFF46 ? dma_reg : 8'dZ;

    assign dma_src = dma_reg;
    assign dma_start = nwrite == 'b0 && db_address == 'hFF46;

    always @(posedge clock)
    begin
        lcdc_reg <= lcdc_reg;
        stat_reg <= stat_reg;
        scy_reg <= scy_reg;
        scx_reg <= scx_reg;
        lyc_reg <= lyc_reg;
        wy_reg <= wy_reg;
        wx_reg <= wx_reg;
        bgp_reg <= bgp_reg;
        obp0_reg <= obp0_reg;
        obp1_reg <= obp1_reg;
        dma_reg <= dma_reg;

        if (nreset == 'b0)
        begin
            lcdc_reg <= 'h91;
            stat_reg <= 'h0;
            scy_reg <= 'h0;
            scx_reg <= 'h0;
            lyc_reg <= 'h0;
            wy_reg <= 'h0;
            wx_reg <= 'h0;
            bgp_reg <= 'hFC;
            obp0_reg <= 'hFF;
            obp1_reg <= 'hFF;
            dma_reg <= 'h00;
        end else begin
            if (nwrite == 'b0)
            begin
                case (db_address)
                 'hFF40: lcdc_reg <= db_data;   
                 'hFF41: stat_reg <= db_data[6:3];
                 'hFF42: scy_reg <= db_data;
                 'hFF43: scx_reg <= db_data;
                 'hFF45: lyc_reg <= db_data;
                 'hFF4A: wy_reg <= db_data;
                 'hFF4B: wx_reg <= db_data;
                 'hFF47: bgp_reg <= db_data;
                 'hFF48: obp0_reg <= db_data;
                 'hFF49: obp1_reg <= db_data;
                 'hFF46: dma_reg <= db_data;
                endcase 
            end
        end
    end

endmodule