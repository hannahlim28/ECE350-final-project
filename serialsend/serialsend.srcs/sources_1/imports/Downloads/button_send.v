module button_send(
    input wire clk,
    input wire reset,
    input wire BTNU, 
    input wire BTNL,
    input wire BTNR,
    input wire BTND,
    input wire tx_ready,
    output reg tx_valid = 0,
    output reg [7:0] tx_data = 0
);
    // LABEL LOCAL PARAMS
    // DIR
    reg [1:0] DIR;
    localparam UP = 2'b00;
    localparam LEFT = 2'b01;
    localparam RIGHT = 2'b10;
    localparam DOWN = 2'b11;
    // STATES
    reg [1:0] state = IDLE;
    localparam IDLE = 2'b00;
    localparam START = 2'b01;
    localparam SEND = 2'b10;
    localparam ENDIT = 2'b11;

    // PULSE TO GET STARTED BUTTONS
    reg see_bup, prev_bup, see_ble, see_bri, see_bdo, prev_ble, prev_bri, prev_bdo;
    always @(posedge clk) begin
        prev_bup <= BTNU;
        see_bup <= ~prev_bup & BTNU;
        prev_ble <= BTNL;
        see_ble <= ~prev_ble & BTNL;
        prev_bri <= BTNR;
        see_bri <= ~prev_bri & BTNR;
        prev_bdo <= BTND;
        see_bdo <= ~prev_bdo & BTND;
    end

    // GRAB DIR AT FIRST PULSE
    reg button_pending = 0;
    always @(posedge clk) begin
    if(reset) begin
        button_pending <= 0;
    end
    if (!button_pending && tx_ready) begin
        if(see_bup) begin
            DIR <= UP;
            button_pending <= 1;
            end else if(see_ble) begin
            DIR <= LEFT;
            button_pending <=1;
            end else if(see_bri) begin
            DIR <= RIGHT;
            button_pending <=1;
            end else if(see_bdo) begin
            DIR <= DOWN;
            button_pending <=1;
            end 
        end
    end

    reg [18*8-1 : 0] send_data;
    reg [5*8 -1 : 0] send_states;
    reg [8:0] index = 0;
    reg prev_ready = 0;
    reg see_ready = 0;
    // ACTUAL FINITE STATE MACHINE
    always @(posedge clk) begin
        if(reset)begin
            tx_valid <= 0;
            index <=0;
            state <=IDLE;
        end else begin
            tx_valid <= 0;
            case(state)
                IDLE: begin
                    tx_valid <= 0;
                    if(button_pending) begin
                        state <= START;
                        see_ready <= tx_ready;
                    end
                end
                START: begin
                    send_states = "\n19G";
                    if(see_ready) begin
                        tx_valid <= 1;
                        index <= index + 1;
                        tx_data <= send_states[8*index +: 8];
                    end
                    if(see_ready && index == 4) begin
                        index <=0;
                        state <= SEND;
                    end
                end
                SEND: begin
                    tx_valid <=0;
                    case(DIR)
                        UP: send_data = "\n0001F 01-Y 0X 1G";
                        LEFT: send_data = "\n0001F 0Y 01-X 1G";
                        RIGHT: send_data = "\n0001F 0Y 01X 1G";
                        DOWN: send_data = "\n0001F 01Y 0X 1G";
                    endcase
                    if(see_ready)begin
                        tx_valid <= 1;
                        index <= index +1;
                        tx_data <= send_data[8*index +: 8];
                    end
                    if(see_ready && index == 17) begin
                        index <=0;
                        state<=ENDIT;
                    end
                end
                ENDIT: begin
                    send_states = "\n09G";
                    tx_valid <=0;
                    if(see_ready) begin
                        tx_valid <= 1;
                        index <= index + 1;
                        tx_data <= send_states[8*index +: 8];
                    end
                    if(see_ready && index == 4) begin
                        index <=0;
                        button_pending <=0;
                        state <= IDLE;
                    end
                end
            endcase
        end 
    end

    // MAKE THE SEE_READY PULSE
    always @(posedge clk) begin
        prev_ready <= tx_ready;
        if(state != IDLE) begin
            see_ready <= ~prev_ready & tx_ready;
        end
    end
endmodule