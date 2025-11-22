module gcode_sender(
    input wire clk,
    input wire reset,
    input wire tx_ready,
    output reg tx_valid,
    output reg [7:0] tx_data
);

    reg [7:0] gcode_bytes [0:17];
    reg [5:0] index;

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
        end else begin
            if (tx_ready && !tx_valid) begin
                tx_data <= gcode_bytes[index];
                tx_valid <= 1;
                index <= index + 1;
            end else begin
                tx_valid <= 0;
            end
        end
    end

endmodule
