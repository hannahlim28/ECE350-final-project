module gcode_sender(
    input wire baud_clk,
    input wire clk,
    input wire reset,
    input wire tx_ready,
    output reg tx_valid,
    output reg [7:0] tx_data
);

    reg [7:0] gcode_bytes [0:17];
    reg [5:0] index;
    reg first_cycle = 1'b1;
    reg prev_ready;
    reg see_ready;
    initial begin
        gcode_bytes[0] = "G";
        gcode_bytes[1] = "9";
        gcode_bytes[2] = "0";
        gcode_bytes[3] = "\n";
        gcode_bytes[4] = "G";
        gcode_bytes[5] = "2";
        gcode_bytes[6] = "1";
        gcode_bytes[7] = "\n";
        gcode_bytes[8] = "G";
        gcode_bytes[9] = "1";
        gcode_bytes[10] = " ";
        gcode_bytes[11] = "X";
        gcode_bytes[12] = "0";
        gcode_bytes[13] = " ";
        gcode_bytes[14] = "Y";
        gcode_bytes[15] = "1";
        gcode_bytes[16] = "0";
        gcode_bytes[17] = "\n";
    end

    always @(posedge clk) begin
        if (reset) begin
            index <= 0;
            tx_valid <= 0;   
        end 
    end
    always @(posedge baud_clk) begin
        prev_ready <= tx_ready;
        if(first_cycle) begin
            see_ready <= tx_ready;
            first_cycle <=0;
        end else begin
            see_ready <= ~prev_ready & tx_ready;
        end
    end
    always @(posedge baud_clk) begin
        tx_valid <=0;
        if (!reset && see_ready) begin
            tx_data <= gcode_bytes[index];
            tx_valid <= 1;
            index <= index + 1;
        end
    end

endmodule
