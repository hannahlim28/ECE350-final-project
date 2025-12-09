module uart_receive  #(
    parameter CLK_HZ = 25_000_000,
    parameter BAUD_RT = 115200,
    parameter DATA_BITS = 8
)(
    input wire clk, 
    input wire reset,
    input wire rx,
    output reg rx_done,
    output reg [7:0] rx_data
);

localparam CYCLES_PER_BIT = CLK_HZ/BAUD_RT;
localparam HALF_BAUD = CYCLES_PER_BIT/2;
localparam COUNT_CYC_BITS = $clog2(CYCLES_PER_BIT);
reg BAUD_CLK = 0;
reg [COUNT_CYC_BITS-1:0] cycle_counter = 0;


localparam IDLE = 2'b00;
localparam START = 2'b01;
localparam DATA = 2'b10;
localparam ENDBIT = 2'b11;

reg [1:0] state = IDLE;
reg [7:0] output_data;
reg [3:0] bit_count;

always @(posedge clk) begin
    if(reset)begin
        cycle_counter <=0;
        rx_done<=0;
        bit_count <=0;
        state <=IDLE;
    end else begin
        rx_done<=0;
        case(state)
            IDLE: begin
                bit_count <=0;
                cycle_counter <=0;
                if(rx == 0) begin
                    state <= START;
                    cycle_counter <=0;
                end
            end
            START: begin
                if(cycle_counter == (HALF_BAUD -1))begin
                    if(rx == 0)begin
                        cycle_counter<=0;
                        bit_count <= 0;
                        state <= DATA;
                    end else begin
                        state <= IDLE;
                    end             
                end else begin
                    cycle_counter <= cycle_counter + 1;
                end
            end
            DATA: begin
                if(cycle_counter == (CYCLES_PER_BIT - 1)) begin
                    cycle_counter <=0;
                    output_data[bit_count] <= rx;
                    if(bit_count == 7) begin
                        bit_count <=0;
                        state <= ENDBIT;
                    end else begin
                        bit_count <= bit_count + 1;
                    end
                end else begin
                    cycle_counter <= cycle_counter + 1;
                end
            end
            ENDBIT: begin
                if(cycle_counter == (CYCLES_PER_BIT - 1)) begin
                    cycle_counter <=0;
                    if(rx == 1) begin
                        rx_data <= output_data;
                        rx_done <= 1;
                    end
                    state <= IDLE;
                end else begin
                    cycle_counter <= cycle_counter + 1;
                end
            end
        endcase
    end
end


endmodule