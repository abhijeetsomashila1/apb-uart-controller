`timescale 1ns / 1ps

module uart_tx (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       tx_start,
    input  wire [7:0] tx_data,
    input  wire [31:0] baud_div,
    output reg        tx,
    output reg        busy,
    output reg        tx_done
);

    reg [31:0] baud_count;
    reg [3:0]  bit_index;
    reg [9:0]  tx_shift;
    reg [3:0]  state;

    localparam IDLE  = 4'd0;
    localparam START = 4'd1;
    localparam DATA  = 4'd2;
    localparam STOP  = 4'd3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            baud_count <= 0;
            bit_index  <= 0;
            tx_shift   <= 10'h3FF;
            state      <= IDLE;
            tx         <= 1'b1;
            busy       <= 1'b0;
            tx_done    <= 1'b0;
        end else begin
            tx_done <= 1'b0;

            case (state)

                IDLE: begin
                    tx       <= 1'b1;
                    busy     <= 1'b0;
                    baud_count <= 0;

                    if (tx_start) begin
                        tx_shift <= {1'b1, tx_data, 1'b0};
                        state    <= START;
                        busy     <= 1'b1;
                    end
                end

                START: begin
                    tx <= 1'b0;

                    if (baud_count >= baud_div - 1) begin
                        baud_count <= 0;
                        bit_index  <= 0;
                        state      <= DATA;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                DATA: begin
                    tx <= tx_shift[bit_index + 1];

                    if (baud_count >= baud_div - 1) begin
                        baud_count <= 0;

                        if (bit_index == 7) begin
                            state <= STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                STOP: begin
                    tx <= 1'b1;

                    if (baud_count >= baud_div - 1) begin
                        baud_count <= 0;
                        state      <= IDLE;
                        busy       <= 1'b0;
                        tx_done    <= 1'b1;
                    end else begin
                        baud_count <= baud_count + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule
