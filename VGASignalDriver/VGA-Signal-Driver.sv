/* ========== VGA Signal Driver Module ==========
    Author: Jack Barnard
    Date: 2026-08-26
    Description: This module is responsible for generating the VGA signals for running a VGA display.
                 It takes in the pixel data from the frame buffer.
                 It outputs the VGA signals to the top level module.
    Change Log:
        2026-08-26: Initial creation of the module.
   =============================================== */
/* ========== PIO Table ==========
    | Type   | Name       | Width | Description                       |
    |--------|------------|-------|-----------------------------------|
    | Param  | SystemClk  |       | System clock frequency in Hz.     |
    | Input  | clk        | 1     | Clock signal for the VGA driver.  |
    | Input  | rst        | 1     | Reset signal for the VGA driver.  |
    | Input  | pixel_data | 24    | RGB data from the frame buffer.   |
    | Output | hsync      | 1     | Horizontal sync signal for VGA.   |
    | Output | vsync      | 1     | Vertical sync signal for VGA.     |
    | Output | pixel_x    | 10    | Current pixel x coordinate.       |
    | Output | pixel_y    | 10    | Current pixel y coordinate.       |
    | Output | red        | 8     | Red color signal for VGA.         |
    | Output | green      | 8     | Green color signal for VGA.       |
    | Output | blue       | 8     | Blue color signal for VGA.        |
    ========================================== */

module VGA_Signal_Driver #(
    parameter SystemClk = 50_000_000
) (
    input logic clk,
    input logic n_rst,
    input logic [23:0] pixel_data,

    output logic vga_clk,
    output logic hsync,
    output logic vsync,
    output logic blank_n,
    output logic sync_n,
    output logic [7:0] red,
    output logic [7:0] green,
    output logic [7:0] blue,

    output logic [9:0] pixel_x,
    output logic [9:0] pixel_y
);

// VGA parameters for 640x480 @ 60Hz
localparam VGA_H_ACTIVE      = 640;
localparam VGA_H_FRONT_PORCH = 16;
localparam VGA_H_SYNC_PULSE  = 96;
localparam VGA_H_BACK_PORCH  = 48;

localparam VGA_V_ACTIVE      = 480;
localparam VGA_V_FRONT_PORCH = 10;
localparam VGA_V_SYNC_PULSE  = 2;
localparam VGA_V_BACK_PORCH  = 33;

localparam VGA_H_TOTAL = VGA_H_ACTIVE + VGA_H_FRONT_PORCH + VGA_H_SYNC_PULSE + VGA_H_BACK_PORCH;
localparam VGA_V_TOTAL = VGA_V_ACTIVE + VGA_V_FRONT_PORCH + VGA_V_SYNC_PULSE + VGA_V_BACK_PORCH;

logic [9:0] x_counter, y_counter;

// Clock generator IP module (creates 25.175MHz / 25MHz pixel clock)
vga_clk_gen vga_clk_gen_inst (
    .refclk(clk),
    .rst(!n_rst),
    .outclk_0(vga_clk)
);

always_ff @(posedge vga_clk or negedge n_rst) begin
    if (!n_rst) begin
        x_counter <= 10'd0;
        y_counter <= 10'd0;
    end else begin
        if (x_counter < VGA_H_TOTAL - 1) begin
            x_counter <= x_counter + 1'b1;
        end else begin
            x_counter <= 10'd0;
            if (y_counter < VGA_V_TOTAL - 1) begin
                y_counter <= y_counter + 1'b1;
            end else begin
                y_counter <= 10'd0;
            end
        end
    end
end

assign hsync   = ~((x_counter >= VGA_H_ACTIVE + VGA_H_FRONT_PORCH) && (x_counter < VGA_H_ACTIVE + VGA_H_FRONT_PORCH + VGA_H_SYNC_PULSE));
assign vsync   = ~((y_counter >= VGA_V_ACTIVE + VGA_V_FRONT_PORCH) && (y_counter < VGA_V_ACTIVE + VGA_V_FRONT_PORCH + VGA_V_SYNC_PULSE));
assign blank_n = (x_counter < VGA_H_ACTIVE) && (y_counter < VGA_V_ACTIVE);
assign sync_n  = 1'b0; // Active low on ADV7123 DACs
assign pixel_x = x_counter;
assign pixel_y = y_counter;

assign red   = blank_n ? pixel_data[23:16] : 8'h00;
assign green = blank_n ? pixel_data[15:8]  : 8'h00;
assign blue  = blank_n ? pixel_data[7:0]   : 8'h00;

endmodule
