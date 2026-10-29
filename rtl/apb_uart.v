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

    output reg         uart_tx,
    input  wire        uart_rx
);

    // Register addresses
    localparam ADDR_DATA    = 32'h00;
    localparam ADDR_STATUS  = 32'h04;
    localparam ADDR_CTRL    = 32'h08;
    localparam ADDR_BAUDDIV = 32'h0C;
    localparam ADDR_VERSION = 32'h10;

    // APB response
    assign PREADY  = 1'b1;
    assign PSLVERR = 1'b0;

    // Registers
    reg [7:0]  tx_data;
    reg [7:0]  rx_data;
    reg        tx_busy;
    reg        rx_valid;
    reg [1:0]  ctrl;
    reg [31:0] baud_div;

    wire apb_access = PSEL && PENABLE;
    wire apb_write  = apb_access && PWRITE;
    wire apb_read   = apb_access && !PWRITE;

    // Sequential register writes and reset
    always @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tx_data  <= 8'h00;
            rx_data  <= 8'h00;
            tx_busy  <= 1'b0;
            rx_valid <= 1'b0;
            ctrl     <= 2'b11;
            baud_div <= 32'd27;
            uart_tx  <= 1'b1;
        end else begin
            if (apb_write) begin
                case (PADDR)
                    ADDR_DATA: begin
                        tx_data <= PWDATA[7:0];
                    end

                    ADDR_CTRL: begin
                        ctrl <= PWDATA[1:0];
                    end

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

    // APB read mux
    always @(*) begin
        PRDATA = 32'h00000000;

        if (apb_read) begin
            case (PADDR)
                ADDR_DATA: begin
                    PRDATA = {24'h0, rx_data};
                end

                ADDR_STATUS: begin
                    PRDATA = {30'h0, rx_valid, tx_busy};
                end

                ADDR_CTRL: begin
                    PRDATA = {30'h0, ctrl};
                end

                ADDR_BAUDDIV: begin
                    PRDATA = baud_div;
                end

                ADDR_VERSION: begin
                    PRDATA = 32'h00010000;
                end

                default: begin
                    PRDATA = 32'h00000000;
                end
            endcase
        end
    end

endmodule

