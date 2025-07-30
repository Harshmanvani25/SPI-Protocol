module adc3664_spi_slave (
    input wire SCLK,
    input wire SEN,
    input wire Reset,
    input wire SDIO,
    output reg SDIO_out,
    output reg drive_sdio,
    output reg [7:0] data_out,
    output reg data_ready
);

    reg [23:0] shift_reg = 24'b0;
    reg [4:0] bit_count = 5'd0;
    reg [7:0] memory [0:4095];  // 12-bit addressable memory
    reg [11:0] address = 12'd0;
    reg rw_flag = 1'b0;
    reg start_shift = 0;

    reg [7:0] read_data = 8'd0;
    reg [2:0] read_bit_cnt = 3'd0;

    wire active_frame = ~SEN;

    // Reset and start frame
    always @(negedge SEN or posedge Reset) begin
        if (Reset) begin
            start_shift <= 0;
            bit_count <= 0;
        end else if (!SEN) begin
            start_shift <= 1;
            bit_count <= 0;
        end
    end

    // On 16th negedge of SCLK: decode and fetch data (blocking)
    always @(negedge SCLK) begin
        if (active_frame && bit_count == 16) begin
            rw_flag = shift_reg[15];              // blocking
            address = shift_reg[11:0];            // blocking
            if (rw_flag == 1) begin
                read_data = memory[address];      // blocking: immediate availability
                read_bit_cnt = 0;
            end
        end
    end

    // Main shift and control logic on posedge
    always @(posedge SCLK or posedge Reset or negedge SEN) begin
        if (Reset) begin
            shift_reg   <= 0;
            data_out    <= 0;
            data_ready  <= 0;
            rw_flag     <= 0;
            drive_sdio  <= 0;
            SDIO_out    <= 1'bz;
        end else if (active_frame && bit_count <= 24) begin
            shift_reg <= {shift_reg[22:0], SDIO};
            bit_count <= bit_count + 1;

            if (bit_count == 16) begin
                drive_sdio <= (rw_flag == 1);
            end

            if (rw_flag == 0 && bit_count >= 17 && bit_count <= 24) begin
                memory[address][24 - bit_count] <= SDIO;
            end

            if (rw_flag == 1 && bit_count >= 17 && bit_count <= 24) begin
                SDIO_out <= read_data[7 - read_bit_cnt];
                read_bit_cnt <= read_bit_cnt + 1;
            end

            if (bit_count == 24) begin
                data_out <= memory[address];
                data_ready <= 1;
                drive_sdio <= 0;
                SDIO_out <= 1'bz;
            end else begin
                data_ready <= 0;
            end
        end else begin
            drive_sdio <= 0;
            SDIO_out <= 1'bz;
        end
    end

endmodule

