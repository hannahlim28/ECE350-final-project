module uart_tx #(
    parameter CLK_HZ = 100_000_000,   // Nexys A7 clock
    parameter BAUD   = 115200,        // UART rate
    parameter PAYLOAD_BITS = 8,
    parameter STOP_BITS = 1
)(
    input  wire clk,
    input  wire resetn,          // active low reset
    output wire uart_txd,
    output wire uart_tx_busy,
    input  wire uart_tx_en,      // pulse to send byte
    input  wire [PAYLOAD_BITS-1:0] uart_tx_data
);

    // ---------------------------------------------------------
    // Correct bit timing: cycles per UART bit
    // ---------------------------------------------------------
    localparam CYCLES_PER_BIT = CLK_HZ / BAUD;
    localparam COUNT_BITS = $clog2(CYCLES_PER_BIT);

    // ---------------------------------------------------------
    // Internal registers
    // ---------------------------------------------------------
    reg [COUNT_BITS-1:0] cycle_counter = 0;
    reg [3:0] bit_counter = 0;

    reg [PAYLOAD_BITS-1:0] shifter;
    reg txd_reg = 1'b1;

    reg [1:0] state;
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    assign uart_txd = txd_reg;
    assign uart_tx_busy = (state != IDLE);

    wire bit_done = (cycle_counter == CYCLES_PER_BIT-1);

    // ---------------------------------------------------------
    // Main FSM
    // ---------------------------------------------------------
    always @(posedge clk) begin
        if (!resetn) begin
            state <= IDLE;
            txd_reg <= 1'b1;
            cycle_counter <= 0;
            bit_counter <= 0;
        end else begin

            case (state)

                // ---------------------------------------------
                // IDLE: wait for uart_tx_en
                // ---------------------------------------------
                IDLE: begin
                    txd_reg <= 1'b1;   // idle high
                    cycle_counter <= 0;
                    bit_counter <= 0;

                    if (uart_tx_en) begin
                        shifter <= uart_tx_data;
                        state <= START;
                    end
                end

                // ---------------------------------------------
                // START bit (0)
                // ---------------------------------------------
                START: begin
                    txd_reg <= 1'b0;
                    if (bit_done) begin
                        cycle_counter <= 0;
                        state <= DATA;
                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end

                // ---------------------------------------------
                // DATA bits (LSB first)
                // ---------------------------------------------
                DATA: begin
                    txd_reg <= shifter[0];

                    if (bit_done) begin
                        cycle_counter <= 0;
                        shifter <= {1'b0, shifter[PAYLOAD_BITS-1:1]};

                        if (bit_counter == PAYLOAD_BITS-1) begin
                            bit_counter <= 0;   // ✅ reset before STOP
                            state <= STOP;
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end

                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end


                STOP: begin
                    txd_reg <= 1'b1;

                    if (bit_done) begin
                        cycle_counter <= 0;

                        if (bit_counter == STOP_BITS-1) begin
                            bit_counter <= 0;
                            state <= IDLE;    
                        end else begin
                            bit_counter <= bit_counter + 1;
                        end

                    end else begin
                        cycle_counter <= cycle_counter + 1;
                    end
                end


            endcase
        end
    end

endmodule
