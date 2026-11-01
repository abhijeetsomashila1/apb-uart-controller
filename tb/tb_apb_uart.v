
`timescale 1ns / 1ps

module tb_apb_uart;

    reg PCLK = 0;
    reg PRESETn = 0;
    reg PSEL = 0;
    reg PENABLE = 0;
    reg PWRITE = 0;
    reg [31:0] PADDR = 0;
    reg [31:0] PWDATA = 0;

    wire [31:0] PRDATA;
    wire PREADY;
    wire PSLVERR;
    wire uart_tx;
    reg uart_rx = 1;

    apb_uart dut (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),
        .uart_tx(uart_tx),
        .uart_rx(uart_rx)
    );

    always #10 PCLK = ~PCLK;

    initial begin

        $monitor("time=%0t reset=%b APB_write=%b uart_tx=%b busy=%b done=%b",
                 $time, PRESETn, PWRITE, uart_tx,
                 dut.tx_busy, dut.tx_done);

        // Reset
        #50;
        PRESETn = 1;

        // APB setup phase
        @(negedge PCLK);
        PSEL = 1;
        PENABLE = 0;
        PWRITE = 1;
        PADDR = 32'h00;
        PWDATA = 32'h000000A5;

        // APB access phase
        @(negedge PCLK);
        PENABLE = 1;

        // End APB transaction
        @(negedge PCLK);
        PSEL = 0;
        PENABLE = 0;
        PWRITE = 0;

        // Wait for UART transmission
        wait(dut.tx_done == 1'b1);

        $display("PASS: UART transmission completed.");

        #30;
        $finish;
    end

    initial begin
        #1000000;
        $display("FAIL: Simulation timeout.");
        $finish;
    end

endmodule
