
// SPI Slave Module for ADC3664 Interface
// 
// Write operation into memory is successfully executed
// Remaining: Add logic for SPI memory read operation


module adc3664_spi_slave (
    input wire SCLK,             // SPI Clock
    input wire SEN,              // Serial Interface Enable (active low)
    input wire Reset,            // Active-high reset
    input wire SDIO,             // serial Data Input/output
    output reg [7:0] data_out,   // captured output from memory
    output reg data_ready        // Indicates write operation Completation
);

    // register to store incoming 24-bit SPI frame
    reg [23:0] shift_reg = 24'b0;

    // 5 Bit counter to count 24bits
    reg [4:0] bit_count = 5'd0;

    // Internal memory with 12-bit addressing and 8-bit data width
    reg [7:0] memory [0:4095];

    // Captured address 
    reg [11:0] address = 12'd0;

    // RW flag: MSB of address frame (bit 15) = 0 for write, 1 for read
    reg rw_flag = 1'b0;

    // Track SEN if 0 start operation 
    wire active_frame = ~SEN; 

    // Main data capture logic: Triggered on positive edge of SCLK, or reset, or Negative Edge of SEN
    always @(posedge SCLK or posedge Reset or negedge SEN) begin
        if (Reset) begin
            shift_reg  <= 0;
            data_out   <= 0;
            data_ready <= 0;
            rw_flag    <= 0;
            bit_count  <= 0;
        end else if (active_frame && bit_count <= 24) begin
            // Shift incoming bit into frame ( left shift ) (shift_reg <= (shift_reg << 1) | SDIO) 
            shift_reg <= {shift_reg[22:0], SDIO};
            bit_count <= bit_count + 1;

            // Extract address after 16 bits
            if (bit_count == 16) begin
                rw_flag  <= shift_reg[15];        // Determine R/W mode
                address  <= shift_reg[11:0];      // Get memory address
            end

            // Write bits into memory (bit 17–24 only if RW = 0)
            if (rw_flag == 0 && bit_count >= 17 && bit_count <= 24) begin
                memory[address][24 - bit_count] <= SDIO;
            end

            // Indicate write completion after all bits received
            if (bit_count == 24 && rw_flag == 0) begin
                data_ready <= 1;
            end else begin
                data_ready <= 0;
            end
        end
    end

    // Output captured memory value for Observing purpose
    always @(negedge SCLK) begin
        if (data_ready == 1) begin
            data_out <= memory[address];
        end
    end
endmodule

