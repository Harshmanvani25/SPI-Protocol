module adc3664_spi_slave (
    input wire SCLK,
    input wire SEN,
    input wire Reset,
    input wire SDIO,
    output reg [7:0] data_out,
    output reg data_ready
);

    reg [23:0] shift_reg = 24'b0;
    reg [4:0] bit_count = 5'd0;
    reg [7:0] memory [0:4095];  // 12-bit addressable memory
    reg [11:0] address = 12'd0;
    reg rw_flag = 1'b0;
    reg start_shift = 0;
    
    wire active_frame = ~SEN;

    // Reset counter at start of new frame
    always @(negedge SEN or posedge Reset) begin
        if (Reset) begin
            start_shift <= 0;
            bit_count <= 0;
        end else if (!SEN) begin
            start_shift <= 1; // Enable shifting when SEN goes low
        end
    end

    // Shift register logic
    always @(posedge SCLK or posedge Reset or negedge SEN) begin
        if (Reset) begin
            shift_reg  <= 0;
            data_out   <= 0;
            data_ready <= 0;
            rw_flag    <= 0;
        end else if (active_frame && bit_count <= 24) begin
            shift_reg = {shift_reg[22:0], SDIO};
            bit_count <= bit_count + 1;
      
            if (bit_count == 16) begin
                rw_flag  <= shift_reg[15];       // MSB is R/W
                address  <= shift_reg[11:0];     // 12-bit address
           end
      
            if (rw_flag == 0 && bit_count >= 17 && bit_count <= 24) begin
                memory[address][24 - bit_count] <= SDIO;
            end

            if (bit_count == 24 && rw_flag == 0) begin
                data_ready <= 1;
            end else begin
                data_ready <= 0;
            end
        end
    end

    // Read operation on falling edge
    always @(posedge SCLK) begin
        if (bit_count == 16 && rw_flag == 1) begin
            data_out   <= memory[address];
            data_ready <= 1;
        end
        

    end

endmodule

