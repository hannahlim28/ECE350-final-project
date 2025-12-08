module int_to_ascii_signed_100 (
    input  wire signed [31:0] value, // signed integer IN: -100 .. +100
    output reg  [7:0] sign,          // '-' or '+' or ' '
    output reg  [7:0] ch1,           // hundreds ASCII
    output reg  [7:0] ch2,           // tens ASCII
    output reg  [7:0] ch3            // ones ASCII
);

    integer mag;
    integer h, t, o;

    always @(*) begin
        // Set sign and magnitude
        if (value < 0) begin
            sign = "-";
            mag = -value;
        end else begin
            sign = "+";     // or " " if you prefer blank sign
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
