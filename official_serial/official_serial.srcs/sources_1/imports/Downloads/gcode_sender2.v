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
    // SET THE POSSIBLE STATES
    reg [1:0] state = START;
    localparam START = 2'b00;
    localparam IDLE = 2'b01;
    localparam SENDG1 = 2'b10;
    localparam SENDG2 = 2'b11;

    assign g_busy = (state != IDLE);

    reg [8:0] index = 0;
    reg [8:0] index2 = 0;
    reg first_cycle = 1'b1;
    reg start_up = 1'b1;
    reg prev_ready = 0;
    reg see_ready = 0;
    reg [8*64-1:0] startup = "\n0Z 0Y 0X 29G\n45G 49G 71G 12G 09G";

    wire [7:0] xa0, xa1, xa2, xa3, xb0, xb1, xb2, xb3;
    reg [3:0] x1_ascii [7:0];
    reg [3:0] y1_ascii [7:0];
    reg [3:0] x2_ascii [7:0];
    reg [3:0] y2_ascii [7:0];
    wire [7:0] ya0, ya1, ya2, ya3, yb0, yb1, yb2, yb3;
    reg [8*64-1:0] g_output1, g_output2;
    reg [8*4-1:0] z_value;

    float_to_ascii x1_value(.value(xo), 
                            .ch0(xa0), 
                            .ch1(xa1),
                            .ch2(xa2),
                            .ch3(xa3));
    float_to_ascii x2_value(.value(xt), 
                            .ch0(xb0), 
                            .ch1(xb1),
                            .ch2(xb2),
                            .ch3(xb3));
    float_to_ascii y1_value(.value(yo), 
                            .ch0(ya0), 
                            .ch1(ya1),
                            .ch2(ya2),
                            .ch3(ya3));
    float_to_ascii y2_value(.value(yt), 
                            .ch0(yb0), 
                            .ch1(yb1),
                            .ch2(yb2),
                            .ch3(yb3));

    always @(posedge clk) begin
        x1_ascii[0] <=xa0;
        x1_ascii[1] <=xa1;
        x1_ascii[2] <=xa2;
        x1_ascii[3] <=xa3;


        x2_ascii[0] <=xb0;
        x2_ascii[1] <=xb1;
        x2_ascii[2] <=xb2;
        x2_ascii[3] <=xb3;

        y1_ascii[0] <=ya0;
        y1_ascii[1] <=ya1;
        y1_ascii[2] <=ya2;
        y1_ascii[3] <=ya3;


        y2_ascii[0] <=yb0;
        y2_ascii[1] <=yb1;
        y2_ascii[2] <=yb2;
        y2_ascii[3] <=yb3;

    end
    always @(*) begin
        case(intensity[1:0])
            2'b00: z_value = "00.2";
            2'b01: z_value = "06.0";
            2'b10: z_value = "03.0";
            2'b11: z_value = "00.0";
        endcase
    end
    // G0 Z2\nG0 X 025.00 Y 004.00 Z2.00\n
    // G1 Z0 F1000\nG1 X 026.00 Y 004.00\nG0 Z2\n

    always @(posedge clk) begin
        g_output1 = {"\n0001F ", 
                    "2Z " , 
                    y1_ascii[3],
                    y1_ascii[2],
                    y1_ascii[1],
                    y1_ascii[0],
                    "Y " , 
                    x1_ascii[3],
                    x1_ascii[2],
                    x1_ascii[1],
                    x1_ascii[0],
                    "X 1G",
                    "\n0001F 2Z 0G"};
        g_output2 = {"\n2Z 0G","\n0001F ", 
                    z_value, 
                    "Z ", 
                    y2_ascii[3],
                    y2_ascii[2],
                    y2_ascii[1],
                    y2_ascii[0],
                    "Y ", 
                    x2_ascii[3],
                    x2_ascii[2],
                    x2_ascii[1],
                    x2_ascii[0],
                    "X 1G",
                    "\n0001F ",
                    z_value,
                    "Z 0G"};
    end

    always @(posedge clk) begin
        if(reset)begin
            index <= 0;
            index2 <=0;
            tx_valid <=0;
            state <= START;
            index <= 0;
            tx_data <= 0;
        end else begin
            case(state)
                START: begin
                    tx_valid <=0;
                    if (see_ready) begin
                        tx_valid <= 1;
                        index <= index + 1;
                        tx_data <= startup[8*index +: 8];
                    end
                    if(see_ready && index == 46)begin
                        state <= IDLE;
                    end
                end
                IDLE: begin
                    index <=0;
                    if(g_send)begin
                        state <= SENDG1;
                    end
                end
                SENDG1: begin
                    tx_valid <=0;
                    if (see_ready) begin
                        tx_valid <= 1;
                        tx_data <= g_output1[8*index +: 8];
                        index <= index + 1;
                    end
                    if(see_ready && index == 38)begin
                        state <= SENDG2;
                        index <= 0;
                    end
                end
                SENDG2: begin
                    tx_valid <=0;
                    if(see_ready) begin
                        tx_valid<=1;
                        index <= index + 1;
                        tx_data <= g_output2[8*index +: 8];
                    end
                    if(see_ready && index == 50)begin
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    always @(posedge clk) begin
        if(reset) begin
            prev_ready <= 0;
            see_ready <= 0;
            first_cycle<=1;
            start_up <=1; 
        end else begin
        prev_ready <= tx_ready;
        if(first_cycle && state == START) begin
            see_ready <= tx_ready;
            first_cycle <=0;
        end else if(start_up && state == SENDG1) begin
            see_ready <= tx_ready;
            start_up <= 0;
        end
        else begin
            see_ready <= ~prev_ready & tx_ready;
        end
        end
    end

endmodule
