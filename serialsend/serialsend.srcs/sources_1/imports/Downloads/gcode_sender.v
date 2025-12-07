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
    reg first_cycle = 1'b1;
    reg start_up = 1'b1;
    reg prev_ready = 0;
    reg see_ready = 0;
    reg [8*64-1:0] startup = "\n1000F 2Z 0G\n0Z 0Y 0X 29G\n45G 49G 71G 12G 09G";

    wire [7:0] xa0, xa1, xa2, xa3, xa4, xa5, xa6, xb0, xb1, xb2, xb3, xb4, xb5, xb6;
    reg [7:0] x1_ascii [7:0];
    reg [7:0] y1_ascii [7:0];
    reg [7:0] x2_ascii [7:0];
    reg [7:0] y2_ascii [7:0];
    wire [7:0] ya0, ya1, ya2, ya3, ya4, ya5, ya6, yb0, yb1, yb2, yb3, yb4, yb5, yb6;
    reg [8*64-1:0] g_output;
    reg [8*4-1:0] z_value;

    float_to_ascii x2_value(.val_100((xt)*100), 
                            .ch0(xa0), 
                            .ch1(xa1),
                            .ch2(xa2),
                            .ch3(xa3),
                            .ch4(xa4), 
                            .ch5(xa5),
                            .ch6(xa6));
    float_to_ascii x1_value(.val_100((xo)*100), 
                            .ch0(xb0), 
                            .ch1(xb1),
                            .ch2(xb2),
                            .ch3(xb3),
                            .ch4(xb4), 
                            .ch5(xb5),
                            .ch6(xb6));
    float_to_ascii y2_value(.val_100((yt)*100), 
                            .ch0(ya0), 
                            .ch1(ya1),
                            .ch2(ya2),
                            .ch3(ya3),
                            .ch4(ya4), 
                            .ch5(ya5),
                            .ch6(ya6));
    float_to_ascii y1_value(.val_100((yo)*100), 
                            .ch0(yb0), 
                            .ch1(yb1),
                            .ch2(yb2),
                            .ch3(yb3),
                            .ch4(yb4), 
                            .ch5(yb5),
                            .ch6(yb6));

    always @(posedge clk) begin
        x1_ascii[0] <=xa0;
        x1_ascii[1] <=xa1;
        x1_ascii[2] <=xa2;
        x1_ascii[3] <=xa3;
        x1_ascii[4] <=xa4;
        x1_ascii[5] <=xa5;
        x1_ascii[6] <=xa6;

        x2_ascii[0] <=xb0;
        x2_ascii[1] <=xb1;
        x2_ascii[2] <=xb2;
        x2_ascii[3] <=xb3;
        x2_ascii[4] <=xb4;
        x2_ascii[5] <=xb5;
        x2_ascii[6] <=xb6;
        
        y1_ascii[0] <=ya0;
        y1_ascii[1] <=ya1;
        y1_ascii[2] <=ya2;
        y1_ascii[3] <=ya3;
        y1_ascii[4] <=ya4;
        y1_ascii[5] <=ya5;
        y1_ascii[6] <=ya6;

        y2_ascii[0] <=yb0;
        y2_ascii[1] <=yb1;
        y2_ascii[2] <=yb2;
        y2_ascii[3] <=yb3;
        y2_ascii[4] <=yb4;
        y2_ascii[5] <=yb5;
        y2_ascii[6] <=yb6;
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
                    y1_ascii[6],
                    y1_ascii[5],
                    y1_ascii[4],
                    y1_ascii[3],
                    y1_ascii[2],
                    y1_ascii[1],
                    y1_ascii[0],
                    "Y " , 
                    x1_ascii[6],
                    x1_ascii[5],
                    x1_ascii[4],
                    x1_ascii[3],
                    x1_ascii[2],
                    x1_ascii[1],
                    x1_ascii[0],
                    "X 1G",
                    "\n0001F 0Z 1G"};
        g_output2 = {"\n2Z 0G","\n0001F ", 
                    z_value, 
                    "Z ", 
                    y2_ascii[6],
                    y2_ascii[5],
                    y2_ascii[4],
                    y2_ascii[3],
                    y2_ascii[2],
                    y2_ascii[1],
                    y2_ascii[0],
                    "Y ", 
                    x2_ascii[6],
                    x2_ascii[5],
                    x2_ascii[4],
                    x2_ascii[3],
                    x2_ascii[2],
                    x2_ascii[1],
                    x2_ascii[0],
                    "X 1G",
                    "\n0001F ",
                    z_value,
                    "Z 1G"};
    end

    always @(posedge clk) begin
        if(reset)begin
            index <= 0;
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
                        state <= SENDING;
                    end
                end
                SENDG1: begin
                    tx_valid <=0;
                    if (see_ready) begin
                        tx_valid <= 1;
                        index <= index + 1;
                        tx_data <= g_output1[8*index +: 8];
                    end
                    if(see_ready && index == 32)begin
                        index <= 0;
                        state <= SENDG2;
                    end
                end
                SENDG2: begin
                    tx_valid <=0;
                    if(see_ready) begin
                        tx_valid<=1;
                        index <= index + 1;
                        tx_data <= g_output2[8*index +: 8];
                    end
                    if(see_ready && index == 39)begin
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
        end else begin
        prev_ready <= tx_ready;
        if(first_cycle && state == START) begin
            see_ready <= tx_ready;
            first_cycle <=0;
        end else if(start_up && state == SENDING) begin
            see_ready <= tx_ready;
            start_up <= 0;
        end
        else begin
            see_ready <= ~prev_ready & tx_ready;
        end
        end
    end

endmodule
