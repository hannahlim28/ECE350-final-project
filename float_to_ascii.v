module float_to_ascii(
    input  wire signed [15:0] val_100,   // scaled by 100
    output reg  [7:0] ch0,               // sign  ('-', '+', or ' ')
    output reg  [7:0] ch1,               // hundreds
    output reg  [7:0] ch2,               // tens
    output reg  [7:0] ch3,               // ones
    output reg  [7:0] ch4,               // '.'
    output reg  [7:0] ch5,               // tenths
    output reg  [7:0] ch6                // hundredths
);

    reg signed [15:0] tmp;
    reg [15:0] mag;           // absolute value
    reg [13:0] int_part;      // integer part (0..999)
    reg [6:0]  frac_part;     // 0..99

    reg [3:0] hundreds;
    reg [3:0] tens;
    reg [3:0] ones;
    reg [3:0] frac_tens;
    reg [3:0] frac_ones;

    always @* begin
        tmp = val_100;

        // sign
        if (tmp < 0) begin
            ch0 = "-";
            mag = -tmp;
        end else begin
            ch0 = " ";   // or "+" if you prefer
            mag = tmp;
        end

        // split into integer and fractional parts
        int_part  = mag / 100;   // integer portion
        frac_part = mag % 100;   // 0..99

        // clamp range to 0..999 just in case
        if (int_part > 999)
            int_part = 999;

        // integer digits
        hundreds = int_part / 100;
        tens     = (int_part / 10) % 10;
        ones     = int_part % 10;

        // fractional digits (two decimal places)
        frac_tens = frac_part / 10;
        frac_ones = frac_part % 10;

        // map digits to ASCII '0'..'9'
        ch1 = "0" + hundreds;
        ch2 = "0" + tens;
        ch3 = "0" + ones;

        ch4 = ".";

        ch5 = "0" + frac_tens;
        ch6 = "0" + frac_ones;
    end

endmodule
