module gcode_sender(
    // input wire xo,
    // input wire xt,
    // input wire yo,
    // input wire yt,
    // input wire intensity,
    // output reg g_sent,
    input wire clk,
    input wire reset,
    input wire tx_ready,
    output reg tx_valid = 0,
    output reg [7:0] tx_data = 0
);

    // reg [7:0] gcode_bytes [0:17];
    reg [5:0] index = 0;
    reg first_cycle = 1'b1;
    reg prev_ready = 0;
    reg see_ready = 0;
    reg [8*47-1:0] startup = "G90 G21 G17 G94 G54\nG92 X0 Y0\nG1 X0 Y-10 F1000\n";



    always @(posedge clk) begin
        prev_ready <= tx_ready;
        if(first_cycle) begin
            see_ready <= tx_ready;
            first_cycle <=0;
        end else begin
            see_ready <= ~prev_ready & tx_ready;
        end
    end
    always @(posedge clk) begin
        if (reset) begin
            index <= 0;
            tx_valid <= 0;   
        end else begin
            tx_valid <=0;
            if (see_ready) begin
                tx_data <= startup[8*index +: 8];
                tx_valid <= 1;
                index <= index + 1;
            end
        end
    end

endmodule
