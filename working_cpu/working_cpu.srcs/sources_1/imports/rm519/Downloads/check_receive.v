module check_receive(
    input wire clk,
    input wire reset,
    input wire rx_done,
    input wire [7:0] rx_data,
    output reg ready_send
);

    localparam IDLE = 1'b0;
    localparam RECOK = 1'b1;

    reg state = IDLE;
    always @(posedge clk) begin
        if(reset)begin
            ready_send<= 0;
            state <= IDLE;
        end else begin
        ready_send<=0;
        case(state)
            IDLE: begin
                if(rx_done && (rx_data == "o"))begin
                    state<=RECOK;
                end else if(rx_done) begin
                    state <= IDLE;
                end
            end
            RECOK: begin
                if(rx_done && (rx_data == "k"))begin
                    ready_send <= 1;
                    state <= IDLE;
                end else if(rx_done) begin
                    state <=IDLE;
                end
            end

        endcase
        end
    end

endmodule