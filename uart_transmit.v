module uart_transmit #(
    parameter CLK_HZ = 100_000_000,
    parameter BAUD_RT = 115200,
    parameter DATA_BITS = 8
)(
    input wire clk,
    input wire reset,
    output wire tx_send,
    output wire tx_busy,
    input wire tx_start,
    input wire [7:0] tx_data
);
    localparam CYCLES_PER_BIT = CLK_HZ/BAUD_RT;
    localparam COUNT_CYC_BITS = $clog2(CYCLES_PER_BIT);
    // assign baud_clk = BAUD_CLK;
    reg BAUD_CLK = 0;
    reg [COUNT_CYC_BITS-1:0] cycle_counter = 0;
    reg [1:0] state = IDLE;
    reg [3:0] bit_counter = 0;
    reg [7:0] shifted_data;
    reg tx_sdata = 1'b1;

    assign tx_send = tx_sdata;
    assign tx_busy = (state != IDLE);

    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam DATA = 2'b10;
    localparam STOP = 2'b11;

    always @(posedge clk) begin
        if (reset) begin
            cycle_counter <= 0;
            BAUD_CLK <= 0;
        end else begin
        if(cycle_counter == (CYCLES_PER_BIT -1)) begin
            cycle_counter <= 0;
            BAUD_CLK <= 1;
        end else begin
            cycle_counter <= cycle_counter +1;
            BAUD_CLK <= 0;
        end
        end
    end

    always @(posedge clk) begin
        if (reset) begin
            bit_counter <= 0;
            tx_sdata <= 1;
            state <= IDLE;
        end else begin
        case (state) 
            IDLE: begin
                bit_counter <= 0;
                if(tx_start)begin
                    shifted_data <= tx_data;
                    state <= START;
                end
            end
            START: begin
                if(BAUD_CLK) begin
                    tx_sdata <= 1'b0;
                    state <= DATA;
                end
            end
            DATA: begin
                if(BAUD_CLK) begin
                    tx_sdata <= shifted_data[0];
                    shifted_data <= {1'b0, shifted_data[7:1]};
                    if(bit_counter == 7) begin
                        state <= STOP;
                        bit_counter <=0;
                    end else begin
                        bit_counter <= bit_counter +1;
                    end
                end
            end
            STOP: begin
                if(BAUD_CLK) begin
                    tx_sdata <= 1'b1;
                    state <= IDLE;
                end
            end
        endcase
        end
    end

endmodule