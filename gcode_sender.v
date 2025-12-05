module gcode_sender(
    input wire clk,
    input wire reset,
    input wire tx_ready,
    output reg tx_valid = 0,
    output reg [7:0] tx_data = 0
);

    reg [7:0] gcode_bytes [0:17];
    reg [5:0] index = 0;
    reg first_cycle = 1'b1;
    reg prev_ready = 0;
    reg see_ready = 0;
    initial begin
        gcode_bytes[0] = "$";
        gcode_bytes[1] = "X";
        gcode_bytes[2] = "\n";
        gcode_bytes[3] = "F";
        gcode_bytes[4] = "1";
        gcode_bytes[5] = "0";
        gcode_bytes[6] = "0";
        gcode_bytes[7] = "0";
        gcode_bytes[8] = "\n";
        gcode_bytes[9] = "G";
        gcode_bytes[10] = "0";
        gcode_bytes[11] = " ";
        gcode_bytes[12] = "X";
        gcode_bytes[13] = "0";
        gcode_bytes[14] = " ";
        gcode_bytes[15] = "Y";
        gcode_bytes[16] = "1";
        gcode_bytes[17] = "0";
        gcode_bytes[18] = "\n";
    end
    always @(posedge clk) begin
        prev_ready <= tx_ready;
        if(first_cycle || reset) begin
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
            if (see_ready && index != 18) begin
                tx_data <= gcode_bytes[index];
                tx_valid <= 1;
                index <= index + 1;
            end
        end
    end

endmodule
