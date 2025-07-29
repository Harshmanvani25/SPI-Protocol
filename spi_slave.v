module adc3664_spi_slave (
    input wire SCLK,
    input wire SEN,
    input wire Reset,
    input wire SDIO,
    output reg rw_flag,              // 1 for read, 0 for write
    output reg [11:0] address,
    output reg [7:0] data_out,
    output reg data_ready
);

    reg [23:0] shift_reg = 24'b0;
    reg [4:0] bit_count = 0;
    reg start_shift = 0;

    // Shift logic
    always @(posedge SCLK or posedge Reset) begin
        if (Reset) begin
            shift_reg <= 24'b0;
            start_shift <= 0;
            rw_flag <= 0;
            address <= 0;
            data_out <= 0;
            data_ready <= 0;
        end else if (!SEN && start_shift) begin
            shift_reg <= {shift_reg[22:0], SDIO};
            bit_count <= bit_count + 1;

            if (bit_count == 24) begin
                rw_flag   <= shift_reg[23];                  // Bit 23
                address   <= shift_reg[19:8];                // Bits 11:0
                data_out  <= shift_reg[7:0];                 // Data portion
                data_ready <= 1;
            end else begin
                data_ready <= 0;
            end
        end
    end

    // Counter & shift start control
    always @(negedge SEN or posedge Reset) begin
        if (Reset) begin
            start_shift <= 0;
            bit_count <= 0;
        end else if (!SEN) begin
            start_shift <= 1; // Enable shifting when SEN goes low
        end
    end

endmodule

