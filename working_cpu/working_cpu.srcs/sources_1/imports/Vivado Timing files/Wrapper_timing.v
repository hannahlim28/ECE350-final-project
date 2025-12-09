`timescale 1ns / 1ps
/**
 * 
 * READ THIS DESCRIPTION:
 *
 * This is the Wrapper module that will serve as the header file combining your processor, 
 * RegFile and Memory elements together.
 *
 * This file will be used to generate the bitstream to upload to the FPGA.
 * We have provided a sibling file, Wrapper_tb.v so that you can test your processor's functionality.
 * 
 * We will be using our own separate Wrapper_tb.v to test your code. You are allowed to make changes to the Wrapper files 
 * for your own individual testing, but we expect your final processor.v and memory modules to work with the 
 * provided Wrapper interface.
 * 
 * Refer to Lab 5 documents for detailed instructions on how to interface 
 * with the memory elements. Each imem and dmem modules will take 12-bit 
 * addresses and will allow for storing of 32-bit values at each address. 
 * Each memory module should receive a single clock. At which edges, is 
 * purely a design choice (and thereby up to you). 
 * 
 * You must change line 36 to add the memory file of the test you created using the assembler
 * For example, you would add sample inside of the quotes on line 38 after assembling sample.s
 *
 **/

module Wrapper (
    input wire clk,
    input wire reset,
    input wire BTNU,
    input wire BTNL,
    input wire BTNR,
    input wire BTND,
    input wire switch,
    output wire tx
);

    wire clock;       
    wire clk25;
    wire locked;
    clk_wiz_1 pll(.clk_out1(clk25), .locked(locked), .reset(reset), .clk_in1(clk));
    
    assign clock = clk25; 

	wire rwe, mwe;
	wire[4:0] rd, rs1, rs2;
	wire[31:0] instAddr, instData, rData, regA, regB,
		memAddr, memDataIn, memDataOut, raw_memDataOut;
		
    reg [31:0] run_y_mm;
    reg [31:0] run_x_start;
    reg [31:0] run_x_end;
    reg [31:0] run_level;
    reg        run_valid;   // 1-cycle pulse to g_send
	
	wire gcode_busy;
	wire gcode_ready = ~gcode_busy;
	
	wire is_run_y      = (memAddr == 32'h0000_9000);
    wire is_run_xstart = (memAddr == 32'h0000_9004);
    wire is_run_xend   = (memAddr == 32'h0000_9008);
    wire is_run_level  = (memAddr == 32'h0000_900C);
    wire is_run_ctrl   = (memAddr == 32'h0000_9010);
    wire is_run_status = (memAddr == 32'h0000_9014);

    wire is_run_mmio   = is_run_y | is_run_xstart | is_run_xend
                       | is_run_level | is_run_ctrl | is_run_status;
                       
    wire ram_wEn = mwe & ~is_run_mmio;

        
	// ADD YOUR MEMORY FILE HERE
	localparam INSTR_FILE = "raster3";
	localparam DATA_FILE = "grey";
	
	// Main Processing Unit
	processor CPU(.clock(clock), .reset(reset), .gcode_stall(gcode_busy || switch), 
								
		// ROM
		.address_imem(instAddr), .q_imem(instData),
									
		// Regfile
		.ctrl_writeEnable(rwe),     .ctrl_writeReg(rd),
		.ctrl_readRegA(rs1),     .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB),
									
		// RAM
		.wren(mwe), .address_dmem(memAddr), 
		.data(memDataIn), .q_dmem(memDataOut)); 
	
	// Instruction Memory (ROM)
	ROM #(.MEMFILE({INSTR_FILE, ".mem"}))
	InstMem(.clk(clock), 
		.addr(instAddr[11:0]), 
		.dataOut(instData));
	
	// Register File
	regfile RegisterFile(.clock(clock), 
		.ctrl_writeEnable(rwe), .ctrl_reset(reset), 
		.ctrl_writeReg(rd),
		.ctrl_readRegA(rs1), .ctrl_readRegB(rs2), 
		.data_writeReg(rData), .data_readRegA(regA), .data_readRegB(regB));
						
	// Processor Memory (RAM)
    RAM #(.MEMFILE({DATA_FILE, ".mem"})
    ) ProcMem (
        .clk(clock),
        .wEn(ram_wEn),              //  gated write enable
        .addr(memAddr[11:0]),
        .dataIn(memDataIn),
        .dataOut(raw_memDataOut)    // direct RAM output
    );
    
     assign memDataOut = is_run_status ? {31'b0, gcode_busy } : raw_memDataOut;
     

    always @(posedge clock) begin   
        if (reset) begin
            run_y_mm <= 32'd0;
            run_x_start <= 32'd0;   
            run_x_end <= 32'd0; 
            run_level <= 32'd0; 
            run_valid <= 1'b0; 
            end else begin 
            run_valid <= 1'b0;
        if (mwe && is_run_mmio) begin
                if (is_run_y) begin 
                    run_y_mm <= memDataIn;
                    end 
                if (is_run_xstart) begin 
                    run_x_start <= memDataIn;
                    end                                    
                if (is_run_xend) begin 
                    run_x_end <= memDataIn;
                    end 
                if (is_run_level) begin  
                    run_level <= memDataIn;
                    end                     
                if (is_run_ctrl && memDataIn[0] && ~gcode_busy) begin
                    run_valid <= 1'b1;
                end

          end 
        end    
        end 
    wire send_sig = switch ?  1'b0 :  run_valid;
    sending_tx serialsender(
        .clk(clock),
        .xo(run_x_start), //first x
        .xt(run_x_end), //second x
        .yo(run_y_mm), //first y
        .yt(run_y_mm), //second y
        .g_send(send_sig), //pulse to start sending
        .intensity(run_level), //0,1,2,3 depending on z (2 bits)
        .reset(reset),
        .BTNU(BTNU),
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTND(BTND),
        .tx(tx),
        .busy(gcode_busy)); //sending wait signal
                
`ifndef SYNTHESIS
  // Optional debug: show each run when control is written
  always @(posedge clock) begin
      if (mwe) begin
          $display("RUN @ %0t: y=%0d xs=%0d xe=%0d lvl=%0d",
                   $time, run_y_mm, run_x_start, run_x_end, run_level);
      end
  end
`endif
          
endmodule
