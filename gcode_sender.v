module gcode_sender(
    input wire [31:0] xo,
    input wire [31:0] xt,
    input wire [31:0] yo,
    input wire [31:0] yt,
    input wire [1:0] intensity,
    input wire g_send,
    output wire g_busy,
    input wire clk,
    input wire reset,
    input wire tx_ready,
    output reg tx_valid = 0,
    output reg [7:0] tx_data = 0
);


    reg [1:0] state = 2'b00;

    localparam START = 2'b00;
    localparam IDLE = 2'b01;
    localparam SENDING = 2'b10;

    assign g_busy = (state != IDLE);

    // reg [7:0] gcode_bytes [0:17];
    reg [8:0] index = 0;
    reg first_cycle = 1'b1;
    reg start_up = 1'b1;
    reg prev_ready = 0;
    reg see_ready = 0;
    reg [8*64-1:0] startup = "\n0Z 0Y 0X 29G\n45G 49G 71G 12G 09G";

    reg [7:0] g_value = "0";
    reg [7:0] [7:0] x_ascii;
    reg [7:0] [7:0] y_ascii;
    reg [8*64-1:0] g_output;
    reg [3:0] [7:0] z_value;

    float_to_ascii x_value(.val_100((xt - xo)*100), 
                            .ch0(x_ascii[6]), 
                            .ch1(x_ascii[5]),
                            .ch2(x_ascii[4]),
                            .ch3(x_ascii[3]),
                            .ch4(x_ascii[2]), 
                            .ch5(x_ascii[1]),
                            .ch6(x_ascii[0]));
    float_to_ascii y_value(.val_100((yt - yo)*100), 
                            .ch0(y_ascii[6]), 
                            .ch1(y_ascii[5]),
                            .ch2(y_ascii[4]),
                            .ch3(y_ascii[3]),
                            .ch4(y_ascii[2]), 
                            .ch5(y_ascii[1]),
                            .ch6(y_ascii[0]));


    always @(posedge clk) begin
        if(intensity == 0)begin
            g_value <= "1";
        end else begin
            g_value <= "0";
        end
        case(intensity)
            2'b00: begin
                z_value[0] <= "0";
                z_value[1] <= "0";
                z_value[2] <= ".";
                z_value[3] <= "2";
            end
            2'b01: begin
                z_value[0] <= "0";
                z_value[1] <= "6";
                z_value[2] <= ".";
                z_value[3] <= "0";
            end
            2'b10: begin
                z_value[0] <= "0";
                z_value[1] <= "3";
                z_value[2] <= ".";
                z_value[3] <= "0";
            end
            2'b11: begin
                z_value[0] <= "0";
                z_value[1] <= "0";
                z_value[2] <= ".";
                z_value[3] <= "0";
            end

        endcase
    end
    always @(posedge clk) begin
        g_output = {"\n0001F ", 
                    z_value[0], 
                    z_value[1], 
                    z_value[2], 
                    z_value[3], 
                    "Z " , 
                    y_ascii[0], 
                    y_ascii[1], 
                    y_ascii[2], 
                    y_ascii[3], 
                    y_ascii[4], 
                    y_ascii[5], 
                    y_ascii[6],
                    "Y " , 
                    x_ascii[0], 
                    x_ascii[1], 
                    x_ascii[2], 
                    x_ascii[3], 
                    x_ascii[4], 
                    x_ascii[5], 
                    x_ascii[6], 
                    "X " , 
                    g_value , 
                    "G"};
    end

    always @(posedge clk) begin
        if(reset)begin
            index <= 0;
            tx_valid <=0;
            state <= START;
        end else begin
            case(state)
                START: begin
                    tx_valid <=0;
                    if (see_ready) begin
                        tx_valid <= 1;
                        index <= index + 1;
                        tx_data <= startup[8*index +: 8];
                    end
                    if(see_ready && index == 63)begin
                        state <= IDLE;
                    end
                end
                IDLE: begin
                    index <=0;
                    if(g_send)begin
                        state <= SENDING;
                    end
                end
                SENDING: begin
                    tx_valid <=0;
                    if (see_ready) begin
                        tx_valid <= 1;
                        index <= index + 1;
                        tx_data <= g_output[8*index +: 8];
                    end
                    if(see_ready && index == 63)begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    always @(posedge clk) begin
        prev_ready <= tx_ready;
        if(first_cycle) begin
            see_ready <= tx_ready;
            first_cycle <=0;
        end else begin
            see_ready <= ~prev_ready & tx_ready;
        end
    end

endmodule
