`timescale 1ns/1ns

module tb_adc3664_spi_slave;

    reg SCLK     = 0;     // No Clock signal 
    reg SEN      = 1;     // Serial Data Enable ( Active Low signal )
    reg Reset    = 1;     // Reset the operation ( Active high signal )
    reg SDIO_drv = 1'b0;  // Internal driver
    reg drive_en = 1'b1;  // Drive enable (1 = drive, 0 = release)

    wire SDIO = drive_en ? SDIO_drv : 1'bz;  // Tri-state SDIO

    wire [7:0] data_out;   // Data Out for checking Data write
    wire data_ready;       // Indicate Write Operation Completed
    reg clk_start = 0;

    // DUT instance with only 6 ports
    adc3664_spi_slave dut (
        .SCLK(SCLK),
        .SEN(SEN),
        .Reset(Reset),
        .SDIO(SDIO),
        .data_out(data_out),
        .data_ready(data_ready)
    );

    // Clock generation
    always #10 if(clk_start == 1) SCLK = ~SCLK; // CLK  start if SEN = 0

    integer i;                  
    reg [23:0] write_frame;     

    initial begin
      
        // WRITE FRAME: write 0xA0 to address 0x00000001
        write_frame = {1'b0, 3'b010, 12'h001, 8'hA0};
        
       
        #5 Reset = 1;        // Reset pulse
        #5 Reset = 0;
        #5 SEN = 0;          
 	#5;
  	     clk_start = 1;
        for (i = 0; i < 24; i = i+1) begin        // Each 24 bit will be provided Serially On SDIO
            SDIO_drv = write_frame[23 - i];
            drive_en = 1;                         // SDIO = SDIO_drv
            @(negedge SCLK);                      // New bit on Every SCLK Negedge
        end
       
        drive_en = 0;
        SDIO_drv = 1'bz;
        
        clk_start = 0;
        SCLK = 0;
        #5 SEN = 1;
         
        #30 $stop;
    end

endmodule
