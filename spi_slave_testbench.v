`timescale 1ns/1ns

module tb_adc3664_spi_slave;

    reg SCLK     = 0;
    reg SEN      = 1;
    reg Reset    = 1;
    reg SDIO_drv = 1'b0;  // Internal driver
    reg drive_en = 1'b1;  // Drive enable (1 = drive, 0 = release)

    wire SDIO = drive_en ? SDIO_drv : 1'bz;  // Tri-state SDIO

    wire [7:0] data_out;
    wire data_ready;
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
    always #10 if(clk_start == 1) SCLK = ~SCLK;

    integer i;
    reg [23:0] write_frame;
    reg [23:0] read_frame;

    initial begin
      
        // WRITE FRAME: write 0xA5 to address 0x012
        write_frame = {1'b0, 3'b010, 12'h015, 8'hA5};
        
        // Reset pulse
        #5 Reset = 1;
        #5 Reset = 0;

        #5 SEN = 0;
  	      
  	     #5;
  	     clk_start = 1;
        for (i = 0; i < 24; i = i+1) begin  
            SDIO_drv = write_frame[23 - i];
            drive_en = 1;
            
            @(negedge SCLK);
        end
        
       // #10 SEN = 1;
       
        drive_en = 0;
        SDIO_drv = 1'bz;
        @(negedge SCLK);
         clk_start = 0;
         SCLK = 0;
         #5 SEN = 1;
         //Reset = 1;
         
         
        #25;

        // READ FRAME: read from address 0x012
       read_frame = {1'b1, 3'b000, 12'h015, 8'h00};
        
       #5 Reset = 0;
        #5 SEN = 0;
        clk_start = 1;
	       
        for (i = 0; i < 24; i = i + 1) begin
            
            if (i <= 15) begin
                SDIO_drv = read_frame[23 - i];
                drive_en = 1;  // drive only address/control part
            end else begin
                drive_en = 0;  // release for data bits
            end
            @(negedge SCLK);
        end

        
        //SEN = 1;
        //drive_en = 0;
        //SDIO_drv = 1'bz;
        //@(negedge SCLK);
        

        #20 $stop;
    end

endmodule

