`timescale 1ns/1ns

module tb_adc3664_spi_slave;

    reg SCLK     = 0;
    reg SEN      = 1;
    reg Reset    = 1;
    reg SDIO_drv = 1'b0;  // Internal driver from master
    reg drive_en = 1'b1;  // 1 = Master drives SDIO, 0 = Slave drives SDIO

    wire SDIO;
    assign SDIO = drive_en ? SDIO_drv : 1'bz;

    wire [7:0] data_out;
    wire data_ready;
    wire SDIO_out;
    wire drive_sdio;

    reg clk_start = 0;

    wire SDIO_line = drive_sdio ? SDIO_out : SDIO;

    // DUT instantiation
    adc3664_spi_slave dut (
        .SCLK(SCLK),
        .SEN(SEN),
        .Reset(Reset),
        .SDIO(SDIO_line),
        .SDIO_out(SDIO_out),
        .drive_sdio(drive_sdio),
        .data_out(data_out),
        .data_ready(data_ready)
    );

    // Clock generation
    always #10 if (clk_start) SCLK = ~SCLK;

    integer i;
    reg [23:0] write_frame;
    reg [23:0] read_frame;
    reg [7:0] received_data;

    initial begin
        // Write 0xA5 to address 0x015 (12-bit address)
        write_frame = {1'b0, 3'b000, 12'h015, 8'hA5};
        read_frame  = {1'b1, 3'b000, 12'h015, 8'h00};

        // Reset pulse
        Reset = 1; #5;
        Reset = 0; #5;

        // -------- WRITE FRAME --------
        SEN = 0;
        clk_start = 1;
        for (i = 0; i < 24; i = i + 1) begin
            SDIO_drv = write_frame[23 - i];
            drive_en = 1;
            @(negedge SCLK);
        end

        drive_en = 0;
        SDIO_drv = 1'bz;
        @(negedge SCLK);
        clk_start = 0;
        SCLK = 0;
        #5 SEN = 1;
        #30;

        // -------- READ FRAME --------
        SEN = 0;
        clk_start = 1;
        received_data = 0;

        for (i = 0; i < 24; i = i + 1) begin
            if (i <= 15) begin
                // Send command and address
                SDIO_drv = read_frame[23 - i];
                drive_en = 1;
            end else begin
                // Release bus for slave to send data
                drive_en = 0;
                SDIO_drv = 1'bz;
            end
            @(negedge SCLK);
        end

        // Now capture bits on posedge after bit 16
        for (i = 0; i < 8; i = i + 1) begin
            @(posedge SCLK);
            received_data = {received_data[6:0], SDIO_line};
        end

        clk_start = 0;
        SEN = 1;

        #20;
      

        $stop;
    end

endmodule

