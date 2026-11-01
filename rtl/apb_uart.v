
`timescale 1ns / 1ps

module apb_uart (
    input  wire        PCLK,
    input  wire        PRESETn,
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [31:0] PADDR,
    input  wire [31:0] PWDATA,
    output reg  [31:0] PRDATA,
    output wire        PREADY,
    output wire        PSLVERR,
    output wire        uart_tx,
    input  wire        uart_rx
);

    localparam ADDR_DATA    = 32'h00;
    localparam ADDR_STATUS  = 32'h04;
    localparam ADDR_CTRL    = 32'h08;
    localparam ADDR_BAUDDIV = 32'h0C;
    localparam ADDR_VERSION = 32'h10;

    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    reg [7:0] tx_data;
    reg [7:0] rx_data;
    reg       rx_valid;
    reg [1:0] ctrl;
    reg [31:0] baud_div;

    reg tx_start;
    wire tx_busy;
    wire tx_done;

    wire apb_access = PSEL && PENABLE;
    wire apb_write  = apb_access && PWRITE;
    wire apb_read   = apb_access && !PWRITE;

    // UART transmitter instance
    uart_tx uart_tx_inst (
        .clk      (PCLK),
        .rst_n    (PRESETn),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .baud_div (baud_div),
        .tx       (uart_tx),
        .busy     (tx_busy),
        .tx_done  (tx_done)
    );

    // APB registers and transmit request
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_data  <= 8'h00;
            rx_data  <= 8'h00;
            rx_valid <= 1'b0;
            ctrl     <= 2'b11;
            baud_div <= 32'd434;
            tx_start <= 1'b0;
        end else begin
            // Default: transmit request is a one-cycle pulse
            tx_start <= 1'b0;

            if (apb_write) begin
                case (PADDR)
                    ADDR_DATA: begin
                        if (!tx_busy) begin
                            tx_data  <= PWDATA[7:0];
                            tx_start <= 1'b1;
                        end
                    end

                    ADDR_CTRL:
                        ctrl <= PWDATA[1:0];

                    ADDR_BAUDDIV: begin
                        if (PWDATA != 0)
                            baud_div <= PWDATA;
                    end

                    default: begin
                    end
                endcase
            end
        end
    end

    // APB read logic
    always @(*) begin
        PRDATA = 32'h00000000;

        if (apb_read) begin
            case (PADDR)
                ADDR_DATA:
                    PRDATA = {24'h0, rx_data};

                ADDR_STATUS:
                    PRDATA = {30'h0, rx_valid, tx_busy};

                ADDR_CTRL:
                    PRDATA = {30'h0, ctrl};

                ADDR_BAUDDIV:
                    PRDATA = baud_div;

                ADDR_VERSION:
                    PRDATA = 32'h00010000;

                default:
                    PRDATA = 32'h00000000;
            endcase
        end
    end

endmodule
