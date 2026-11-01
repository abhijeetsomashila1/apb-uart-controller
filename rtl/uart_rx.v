
`timescale 1ns / 1ps

module uart_rx (
    input wire clk,
    input wire rst_n,
    input wire rx,
    input wire [31:0] baud_div,

    output reg [7:0] rx_data,
    output reg rx_valid
);

    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] state;
    reg [31:0] baud_count;
    reg [2:0] bit_index;
    reg [7:0] rx_shift;

    reg rx_sync1;
    reg rx_sync2;

    // Synchronize asynchronous UART input
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_sync1 <= 1'b1;
            rx_sync2 <= 1'b1;
        end else begin
            rx_sync1 <= rx;
            rx_sync2 <= rx_sync1;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            baud_count <= 0;
            bit_index  <= 0;
            rx_shift   <= 0;
            rx_data    <= 0;
            rx_valid   <= 0;
        end else begin

            rx_valid <= 1'b0;

            case (state)

                IDLE: begin
                    baud_count <= 0;
                    bit_index <= 0;

                    if (rx_sync2 == 1'b0)
                        state <= START;
                end

                START: begin
                    if (baud_count >= (baud_div / 2)) begin
                        baud_count <= 0;

                        if (rx_sync2 == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                DATA: begin
                    if (baud_count >= baud_div - 1) begin
                        baud_count <= 0;
                        rx_shift[bit_index] <= rx_sync2;

                        if (bit_index == 7)
                            state <= STOP;
                        else
                            bit_index <= bit_index + 1;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                STOP: begin
                    if (baud_count >= baud_div - 1) begin
                        baud_count <= 0;
                        rx_data <= rx_shift;
                        rx_valid <= 1'b1;
                        state <= IDLE;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                default: state <= IDLE;

            endcase
        end
    end

endmodule
