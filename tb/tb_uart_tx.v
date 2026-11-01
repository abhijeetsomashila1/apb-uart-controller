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
        $monitor("time=%0t rst_n=%b start=%b tx=%b busy=%b done=%b",
                 $time, rst_n, tx_start, tx, busy, tx_done);

        #30;
        rst_n = 1;
        $display("RESET RELEASED");

        #20;
        tx_data = 8'hA5;
        tx_start = 1;
        $display("TRANSMIT REQUEST");

        #10;
        tx_start = 0;

        #500;
        $display("DIAGNOSTIC FINISHED");
        $finish;
    end

endmodule