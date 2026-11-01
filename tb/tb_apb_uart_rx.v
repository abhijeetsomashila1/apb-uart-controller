
`timescale 1ns / 1ps

module tb_apb_uart_rx;

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

    reg [31:0] read_data;

    // APB UART DUT
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

    // 50 MHz clock
    always #10 PCLK = ~PCLK;

    // APB write task
    task apb_write;
        input [31:0] addr;
        input [31:0] data;
        begin
            @(negedge PCLK);
            PSEL = 1;
            PENABLE = 0;
            PWRITE = 1;
            PADDR = addr;
            PWDATA = data;

            @(negedge PCLK);
            PENABLE = 1;

            @(negedge PCLK);
            PSEL = 0;
            PENABLE = 0;
            PWRITE = 0;
        end
    endtask

    // APB read task
    task apb_read;
        input [31:0] addr;
        begin
            @(negedge PCLK);
            PSEL = 1;
            PENABLE = 0;
            PWRITE = 0;
            PADDR = addr;

            @(negedge PCLK);
            PENABLE = 1;

            @(posedge PCLK);
            #1;
            read_data = PRDATA;

            @(negedge PCLK);
            PSEL = 0;
            PENABLE = 0;
        end
    endtask

    // Send one UART byte, LSB first
    task send_uart_byte;
        input [7:0] data;
        integer i;
        begin
            uart_rx = 0;       // Start bit
            #80;

            for (i = 0; i < 8; i = i + 1) begin
                uart_rx = data[i];
                #80;
            end

            uart_rx = 1;       // Stop bit
            #100;
        end
    endtask

    initial begin

        $monitor("time=%0t RX=%b PRDATA=%h RX_DATA=%h RX_VALID=%b",
                 $time, uart_rx, PRDATA,
                 dut.rx_data, dut.rx_valid);

        // Reset
        #50;
        PRESETn = 1;

        // Set baud divisor to 4 for faster simulation
        apb_write(32'h0C, 32'd4);

        $display("Baud divisor configured.");

        // Send byte 0xA5 through UART RX
        send_uart_byte(8'hA5);

        // Read APB DATA register (address 0x00)
        apb_read(32'h00);

        // Verify received byte
        if (read_data[7:0] == 8'hA5) begin
            $display("PASS: APB received data = %h",
                     read_data[7:0]);
        end
        else begin
            $display("FAIL: Expected A5, Received %h",
                     read_data[7:0]);
        end

        #40;
        $finish;
    end

    initial begin
        #10000;
        $display("FAIL: Simulation timeout.");
        $finish;
    end

endmodule
