module sending_tx(
    input wire clk,
    input wire reset,
    input wire BTNU,
    input wire BTNL,
    input wire BTNR,
    input wire BTND,
    output wire ledone,
    output wire tx
);
    wire uart_tx_busy;
    wire tx_valid;
    wire baud_clk;
    reg [31:0] xou,xol,xori,xod,xtu,xtl,xtr,xtd,you,yol,yor,yod,ytu,ytl,ytr,ytd;
    reg [1:0] intensity;
    reg g_sendu = 0;
    reg g_sendl = 0;
    reg g_sendr = 0;
    reg g_sendd = 0;

    reg see_bup, prev_bup, see_ble, see_bri, see_bdo, prev_ble, prev_bri, prev_bdo;
    wire g_busy;

    wire[7:0] test_letter;
    reg bup, ble, bri, bdo;
    always @(posedge clk) begin
        bup = BTNU;
    end
    always @(posedge clk) begin
        ble = BTNL;
    end
    always @(posedge clk) begin
        bri = BTNR;
    end
    always @(posedge clk) begin
        bdo = BTND;
    end
    always @(posedge clk) begin
        if(!g_busy && see_bup)begin
            xou = 0;
            xtu = 0;
            you = 0;
            ytu = 10;
            intensity = 2'b11;
            g_sendu <=1;
        end else begin
            g_sendu <=0;
        end
    end
    always @(posedge clk) begin
        if(!g_busy && see_ble)begin
            xol = 10;
            xtl = 0;
            yol = 0;
            ytl = 0;
            intensity = 2'b11;
            g_sendl <=1;
        end else begin
            g_sendl <=0;
        end
    end
    always @(posedge clk) begin
        if(!g_busy && see_bri)begin
            xori = 0;
            xtr = 10;
            yor = 0;
            ytr = 0;
            intensity = 2'b11;
            g_sendr <=1;
        end else begin
            g_sendr <=0;
        end
    end
    always @(posedge clk) begin
        if(!g_busy && see_bdo)begin
            xod = 0;
            xtd = 0;
            yod = 10;
            ytd = 0;
            intensity = 2'b11;
            g_sendd <=1;
        end else begin
            g_sendd <=0;
        end
    end
    
    always @(posedge clk) begin
        prev_bup <= bup;
        see_bup <= ~prev_bup & bup;
    end
    always @(posedge clk) begin
        prev_ble <= ble;
        see_ble <= ~prev_ble & ble;
    end
    always @(posedge clk) begin
        prev_bri <= bri;
        see_bri <= ~prev_bri & bri;
    end
    always @(posedge clk) begin
        prev_bdo <= bdo;
        see_bdo <= ~prev_bdo & bdo;
    end
    
    uart_transmit uut(.clk(clk), 
            .reset(reset), 
            .tx_send(tx), 
            .tx_busy(uart_tx_busy), 
            .tx_start(tx_valid), 
            .tx_data(test_letter));

    gcode_sender getting_gcode(
        .xo(xou+xol+xori+xod),
        .xt(xtu+xtl+xtr+xtd),
        .yo(you+yol+yor+yod),
        .yt(ytu+ytl+ytr+ytd),
        .intensity(intensity),
        .g_send(g_sendl ||g_sendr || g_sendu || g_sendd),
        .g_busy(g_busy),
        .clk(clk),
        .reset(reset),
        .tx_ready(!uart_tx_busy),
        .tx_valid(tx_valid),
        .tx_data(test_letter));
endmodule