`timescale 1ns/1ns

module tb_adc3664_spi_slave;

    reg SCLK    = 0;
    reg SEN     = 1;
    reg Reset   = 1;
    reg SDIO_tb = 1'bz;

    wire rw_flag;
    wire [11:0] address;
    wire [7:0]  data_out;
    wire data_ready;

    reg [23:0] frame = 24'b0;
  reg clk_start = 0;
    // DUT instance
    adc3664_spi_slave dut (
        .SCLK(SCLK),
        .SEN(SEN),
        .Reset(Reset),
        .SDIO(SDIO_tb),
        .rw_flag(rw_flag),
        .address(address),
        .data_out(data_out),
        .data_ready(data_ready)
    );

    integer i;
    
    // Clock generation
    always #5 if(clk_start == 1) SCLK = ~SCLK;// 100 MHz clock

    initial begin
        // Frame = 1(read) + 3b000 + address(12b) + data(8b)
        frame = 24'b1_000_101010101010_11001100;

        // Apply Reset
        #5 Reset = 1;
        #5 Reset = 0;

        // Start Transmission
        #5 SEN = 0;
  	     clk_start = 1;
        // Transmit 24 bits, one per posedge
        for (i = 0; i < 24; i = i + 1) begin
             // Place data before posedge
            SDIO_tb = frame[23 - i];
            @(negedge SCLK);
        end

        // Release Bus
        @(negedge SCLK);
        SDIO_tb = 1'bz;
        SEN = 1;

        // Wait to observe final outputs
        #100 $finish;
    end

endmodule

