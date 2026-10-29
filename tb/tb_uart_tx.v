
`timescale 1ns / 1ps

module tb_uart_tx;

    reg clk = 0;
    reg rst_n = 0;
    reg tx_start = 0;
    reg [7:0] tx_data = 0;
    reg [31:0] baud_div = 4;

    wire tx;
    wire busy;
    wire tx_done;

    uart_tx dut (
        .clk(clk),
        .rst_n(rst_n),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .baud_div(baud_div),
        .tx(tx),
        .busy(busy),
        .tx_done(tx_done)
    );

    always #5 clk = ~clk;

    initial begin
        $display("Starting UART TX test");

        repeat (3) @(negedge clk);
        rst_n = 1;

        repeat (2) @(negedge clk);

        // Send 0xA5, least-significant bit first
        tx_data = 8'hA5;
        tx_start = 1;

        @(negedge clk);
        tx_start = 0;

        // Wait for the transmitter to pull TX low
        wait (tx == 1'b0);
        $display("Start bit detected at time %0t", $time);

        // Sample the 8 data bits near their centers.
        // Each bit lasts approximately 4 clock cycles.
        repeat (6) @(negedge clk);

        begin : sample_data
            integer i;
            reg [7:0] received_byte;

            for (i = 0; i < 8; i = i + 1) begin
                received_byte[i] = tx;
                repeat (4) @(negedge clk);
            end

            if (received_byte !== 8'hA5)
                $fatal(1, "FAIL: expected A5, got %02h",
                       received_byte);

            $display("PASS: UART TX transmitted 0x%02h",
                     received_byte);
        end

        $finish;
    end

    initial begin
        #2000;
        $fatal(1, "FAIL: simulation timeout");
    end

endmodule
