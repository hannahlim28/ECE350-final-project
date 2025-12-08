module float_to_ascii (
    input  wire signed [31:0] value, // signed integer IN: -100 .. +100
    output reg  [7:0] ch0,          // '-' or '+' or ' '
    output reg  [7:0] ch1,           // hundreds ASCII
    output reg  [7:0] ch2,           // tens ASCII
    output reg  [7:0] ch3            // ones ASCII
);

    integer mag;
    integer h, t, o;

    always @(*) begin
        // Set sign and magnitude
        if (value < 0) begin
            ch0 = "-";
            mag = -value;
        end else begin
            ch0 = "+";     // or " " if you prefer blank sign
            mag = value;
        end

        // Extract digits
        h = mag / 100;
        t = (mag / 10) % 10;
        o = mag % 10;

        // Convert to ASCII
        ch1 = "0" + h;
        ch2 = "0" + t;
        ch3 = "0" + o;
    end

endmodule
