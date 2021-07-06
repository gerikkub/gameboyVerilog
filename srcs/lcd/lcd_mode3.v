`timescale 1ns / 1ns

module lcd_mode3(
    input clock,
    input nreset,

    input [1:0]mode_n,
    input [7:0]y_pos,
    input [7:0]x_pos,

    output x_inc,

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

    output pixel_valid,
    output [1:0]pixel_data,
    output [1:0]pixel_palette
    );

    // Pixel FIFO
    // Fifo value: [3:2] owner
    // Fifo value: [1:0] data
    reg [3:0]pixel_fifo[15:0];
    reg [4:0]pixel_fifo_len;

    assign pixel_valid = mode_n == 'd3 && pixel_fifo_len > 'd8;
    assign pixel_data = pixel_fifo[0][1:0];
    //assign pixel_owner = pixel_fifo[0][3:2];

    assign x_inc = pixel_valid;

    // TODO: Only background right now
    assign pixel_palette = 'd0;

    integer i;

    always @(posedge clock)
    begin
        pixel_fifo_len <= pixel_fifo_len;
        
        if (nreset == 'd0 ||
            mode_n != 'd3)
        begin
            pixel_fifo_len <= 'd0;
        end

        for (i = 0; i < 16; i++)
        begin
            pixel_fifo[i] <= pixel_fifo[i];
        end

        if (pixel_valid)
        begin
            pixel_fifo_len <= pixel_fifo_len - 'd1;
            for (i = 0; i < 15; i++)
            begin
                pixel_fifo[i] <= pixel_fifo[i+1];
            end
        end

        if (fetch_state == FETCH_WRITE && odd_cycle)
        begin
            if (pixel_valid)
            begin
                pixel_fifo_len <= pixel_fifo_len + 'd7;
            end else begin
                pixel_fifo_len <= pixel_fifo_len + 'd8;
            end
            for (i = 0; i < 8; i++)
            begin
                pixel_fifo[i + {27'b0, pixel_fifo_len}] <= {2'b00, fetch_data1_vram_data_flip[i], fetch_data0_vram_data_flip[i]};
            end
        end
    end

    parameter FETCH_IDLE = 0;
    parameter FETCH_TILE = 1;
    parameter FETCH_DATA0 = 2;
    parameter FETCH_DATA1 = 3;
    parameter FETCH_WRITE = 4;

    reg [2:0]fetch_state;
    reg [4:0]x_tile_num;
    reg odd_cycle;

    always @(posedge clock)
    begin
        odd_cycle <= ~odd_cycle;
        x_tile_num <= x_tile_num;
        if (nreset == 'd0 ||
            mode_n != 'd3)
        begin
            fetch_state <= FETCH_IDLE;
            odd_cycle <= 'd0;
        end else begin
            if (fetch_state == FETCH_IDLE && mode_n == 'd3) begin
                // Just switch to mode 3. Start fetching
                fetch_state <= FETCH_TILE;
                x_tile_num <= 'd0;
            end else if (odd_cycle == 'd0) begin
                // Hold the state through consecutive clocks
                fetch_state <= fetch_state;
            end else begin
                // Advance the state machine
                case (fetch_state)
                 FETCH_TILE: fetch_state <= FETCH_DATA0;
                 FETCH_DATA0: fetch_state <= FETCH_DATA1;
                 FETCH_DATA1: fetch_state <= FETCH_WRITE;
                 FETCH_WRITE: begin
                     fetch_state <= FETCH_TILE;
                     x_tile_num <= x_tile_num + 'd1;
                 end
                 default: fetch_state <= FETCH_IDLE;
                endcase
            end
        end
    end

    assign vram_db_nread = ~(odd_cycle == 'b1 &&
                             (fetch_state == FETCH_TILE ||
                              fetch_state == FETCH_DATA0 ||
                              fetch_state == FETCH_DATA1));

    // FETCH_TILE state
    wire [15:0]fetch_tile_vram_addr = bg_map_sel == 'd0 ?
                                      {6'h26, y_pos[7:3], x_tile_num} :
                                      {6'h27, y_pos[7:3], x_tile_num};

    reg [7:0]fetch_tile_vram_data;
    wire [7:0]fetch_tile_vram_data_twos;
    assign fetch_tile_vram_data_twos = ~(fetch_tile_vram_data + 'd1);

    // FETCH_DATA0 state
    wire [15:0]fetch_data0_vram_addr = bg_window_data_sel == 'd1 ?
                                       {4'h8, fetch_tile_vram_data, y_pos[2:0], 1'b0} : // Unsigned addressing
                                       fetch_tile_vram_data[7] == 'b1 ?
                                       {5'h11, fetch_tile_vram_data_twos[6:0], y_pos[2:0], 1'b0}: // Signed
                                       {5'h12, fetch_tile_vram_data[6:0], y_pos[2:0], 1'b0}; // Unsigned
    reg [7:0]fetch_data0_vram_data;
    wire [7:0]fetch_data0_vram_data_flip;
    assign fetch_data0_vram_data_flip = {fetch_data0_vram_data[0], fetch_data0_vram_data[1],
                                         fetch_data0_vram_data[2], fetch_data0_vram_data[3],
                                         fetch_data0_vram_data[4], fetch_data0_vram_data[5],
                                         fetch_data0_vram_data[6], fetch_data0_vram_data[7]};

    // FETCH_DATA1 state
    wire [15:0]fetch_data1_vram_addr = bg_window_data_sel == 'd1 ?
                                       {4'h8, fetch_tile_vram_data, y_pos[2:0], 1'b1} : // Unsigned addressing
                                       fetch_tile_vram_data[7] == 'b1 ?
                                       {5'h11, fetch_tile_vram_data_twos[6:0], y_pos[2:0], 1'b1}: // Signed
                                       {5'h12, fetch_tile_vram_data[6:0], y_pos[2:0], 1'b1}; // Unsigned
    reg [7:0]fetch_data1_vram_data;
    wire [7:0]fetch_data1_vram_data_flip;
    assign fetch_data1_vram_data_flip = {fetch_data1_vram_data[0], fetch_data1_vram_data[1],
                                         fetch_data1_vram_data[2], fetch_data1_vram_data[3],
                                         fetch_data1_vram_data[4], fetch_data1_vram_data[5],
                                         fetch_data1_vram_data[6], fetch_data1_vram_data[7]};

    // FETCH_WRITE state
    // Nothing to do here explicitly

    assign vram_db_address = fetch_state == FETCH_IDLE ? 'd0 :
                             fetch_state == FETCH_TILE ? fetch_tile_vram_addr :
                             fetch_state == FETCH_DATA0 ? fetch_data0_vram_addr :
                             fetch_state == FETCH_DATA1 ? fetch_data1_vram_addr :
                             'd0;

    always @(posedge clock)
    begin
        fetch_tile_vram_data <= fetch_tile_vram_data;
        fetch_data0_vram_data <= fetch_data0_vram_data;
        fetch_data1_vram_data <= fetch_data1_vram_data;

        case (fetch_state)
         FETCH_TILE: fetch_tile_vram_data <= vram_db_data;
         FETCH_DATA0: fetch_data0_vram_data <= vram_db_data;
         FETCH_DATA1: fetch_data1_vram_data <= vram_db_data;
        endcase
    end

endmodule
