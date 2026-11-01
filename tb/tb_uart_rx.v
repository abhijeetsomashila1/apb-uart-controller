
`timescale 1ns / 1ps

module tb_uart_rx;

    reg clk = 0;
    reg rst_n = 0;
    reg rx = 1;

    reg [31:0] baud_div = 4;

    wire [7:0] rx_data;
    wire rx_valid;

    reg [7:0] expected_data;
    integer pass_count = 0;
    integer fail_count = 0;

    uart_rx dut (
        .clk(clk),
        .rst_n(rst_n),
        .rx(rx),
        .baud_div(baud_div),
        .rx_data(rx_data),
        .rx_valid(rx_valid)
    );

    always #5 clk = ~clk;

    task send_byte;
        input [7:0] data;
        integer i;
        begin
            rx = 0;                 // Start bit
            #(baud_div * 10);

            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];       // Data bits, LSB first
                #(baud_div * 10);
            end

            rx = 1;                 // Stop bit
            #(baud_div * 10);
        end
    endtask

    task check_byte;
        input [7:0] expected;
        begin
            // Wait for a fresh receive-valid rising edge
            @(posedge rx_valid);

            // Allow nonblocking assignments to update rx_data
            #1;

            if (rx_data === expected) begin
                $display("PASS: Expected=%h Received=%h",
                         expected, rx_data);
                pass_count = pass_count + 1;
            end
            else begin
                $display("FAIL: Expected=%h Received=%h",
                         expected, rx_data);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial begin
        $monitor("time=%0t rx=%b rx_data=%h rx_valid=%b",
                 $time, rx, rx_data, rx_valid);

        #30;
        rst_n = 1;

        #20;
        send_byte(8'h00);
        check_byte(8'h00);

        send_byte(8'hFF);
        check_byte(8'hFF);

        send_byte(8'h3C);
        check_byte(8'h3C);

        #20;

        $display("--------------------------------");
        $display("UART RX TEST SUMMARY");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $display("--------------------------------");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: Simulation timeout");
        $finish;
    end

endmodule
