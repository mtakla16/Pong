`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Pong Video Game
// Authors:  Mikey Takla, Ash Zaveri, Jay Gutierrez
// Adapted from VGA verilog template by Da Cheng
//////////////////////////////////////////////////////////////////////////////////
module pong (ClkPort, vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b, Sw0, Sw1, btnU, btnD, btnL, btnR,
	St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar,
	An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp,
	LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7);
	input ClkPort, Sw0, btnU, btnD, btnL, btnR, Sw0, Sw1;
	output St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar;
	output vga_h_sync, vga_v_sync, vga_r, vga_g, vga_b;
	output An0, An1, An2, An3, Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp;
	output LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	reg vga_r, vga_g, vga_b;
	//////////////////////////////////////////////////////////////////////////////////////////
	/*  LOCAL SIGNALS */
	wire	reset, start, ClkPort, board_clk, clk;
	
	BUF BUF1 (board_clk, ClkPort); 	
	BUF BUF2 (reset, Sw0);
	BUF BUF3 (start, Sw1);
	
	reg [31:0]	DIV_CLK;
	always @ (posedge board_clk, posedge reset)  
	begin : CLOCK_DIVIDER
      if (reset)
			DIV_CLK <= 0;
      else
			DIV_CLK <= DIV_CLK + 1'b1;
	end	
	
	assign	clk = DIV_CLK[1];
	assign 	{St_ce_bar, St_rp_bar, Mt_ce_bar, Mt_St_oe_bar, Mt_St_we_bar} = {5'b11111};
	
	wire inDisplayArea;
	wire [9:0] CounterX;
	wire [9:0] CounterY;
	wire b_display;
	
	reg [9:0] pad1_position;
	reg [9:0] pad2_position;
	wire [3:0] player1_score;
	wire [3:0] player2_score;
	wire [1:0] color_counter;

	ball_sm ball(.clk(clk), .reset(reset), .sys_clk(DIV_CLK[21]),
					.p1_position(pad1_position), .p2_position(pad2_position),
					.vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea),
					.CounterX(CounterX), .CounterY(CounterY), .b_display(b_display),
					.p1_score(player1_score), .p2_score(player2_score), .color_counter(color_counter));
	
	/////////////////////////////////////////////////////////////////
	///////////////		VGA control starts here		/////////////////
	/////////////////////////////////////////////////////////////////

	//PAD 1
	always @(posedge DIV_CLK[21])
		begin
			if(reset)
				begin
				pad1_position<=400;
				end
			else if(btnL && ~btnU)
				begin
				if (pad1_position >= 430)
					pad1_position <= 430;
				else
					pad1_position <= pad1_position+10;
				end
			else if(btnU && ~btnL)
				begin
				if (pad1_position <= 50)
					pad1_position <= 50;
				else
					pad1_position <= pad1_position-10;
				end
		
		end
		
		//PAD 2
		always @(posedge DIV_CLK[21])
		begin
			if(reset)
				begin
				pad2_position<=200;
				end
			else if(btnD && ~btnR)
				begin
				if (pad2_position >= 430)
					pad2_position <= 430;
				else
					pad2_position <= pad2_position+10;
				end
			else if(btnR && ~btnD)
				begin
				if (pad2_position <= 50)
					pad2_position <= 50;
				else
					pad2_position <= pad2_position-10;
				end
		end
		
	wire p1_display = (CounterY>=(pad1_position-50) && CounterY<=(pad1_position+50) && CounterX>=20 && CounterX<=30);
	wire p2_display = CounterY>=(pad2_position-50) && CounterY<=(pad2_position+50) && CounterX>=610 && CounterX<=620;
	
	wire R, G, B;
	assign R = ((p1_display || p2_display) && (color_counter == 0))
				||(b_display && (color_counter == 1))
				||((p2_display || b_display) && (color_counter == 2));
	assign G = ((p1_display || p2_display) && (color_counter == 1))
				||(b_display && (color_counter == 2))
				||((p2_display || b_display) && (color_counter == 0));
	assign B = ((p1_display || p2_display) && (color_counter == 2))
				||(b_display && (color_counter == 0))
				||((p2_display || b_display) && (color_counter == 1));
	
	always @(posedge clk)
	begin
		vga_r <= R & inDisplayArea;
		vga_g <= G & inDisplayArea;
		vga_b <= B & inDisplayArea;
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  VGA control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	`define QI 			2'b00
	`define QGAME_1 	2'b01
	`define QGAME_2 	2'b10
	`define QDONE 		2'b11
	
	reg [3:0] p2_score;
	reg [3:0] p1_score;
	reg [1:0] state;
	wire LD0, LD1, LD2, LD3, LD4, LD5, LD6, LD7;
	
	assign LD0 = (p1_score == 4'b1010);
	assign LD1 = (p2_score == 4'b1010);
	
	assign LD2 = start;
	assign LD4 = reset;
	
	assign LD3 = (state == `QI);
	assign LD5 = (state == `QGAME_1);
	assign LD6 = (state == `QGAME_2);
	assign LD7 = (state == `QDONE);
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  LD control ends here 	 	////////////////////
	/////////////////////////////////////////////////////////////////
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control starts here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
	reg 	[3:0]	SSD;
	wire 	[3:0]	SSD0, SSD1, SSD2, SSD3;
	wire 	[1:0] ssdscan_clk;
	
	assign SSD3 = player1_score[3:0];
	assign SSD2 = 4'b1111;
	assign SSD1 = 4'b1111;
	assign SSD0 = player2_score[3:0];
	
	// need a scan clk for the seven segment display 
	// 191Hz (50MHz / 2^18) works well
	assign ssdscan_clk = DIV_CLK[19:18];	
	assign An0	= !(~(ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 00
	assign An1	= !(~(ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 01
	assign An2	= !( (ssdscan_clk[1]) && ~(ssdscan_clk[0]));  // when ssdscan_clk = 10
	assign An3	= !( (ssdscan_clk[1]) &&  (ssdscan_clk[0]));  // when ssdscan_clk = 11
	
	always @ (ssdscan_clk, SSD0, SSD1, SSD2, SSD3)
	begin : SSD_SCAN_OUT
		case (ssdscan_clk) 
			2'b00:
					SSD = SSD0;
			2'b01:
					SSD = SSD1;
			2'b10:
					SSD = SSD2;
			2'b11:
					SSD = SSD3;
		endcase 
	end	

	// and finally convert SSD_num to ssd
	reg [6:0]  SSD_CATHODES;
	assign {Ca, Cb, Cc, Cd, Ce, Cf, Cg, Dp} = {SSD_CATHODES, 1'b1};
	// Following is Hex-to-SSD conversion
	always @ (SSD) 
	begin : HEX_TO_SSD
		case (SSD)		
			4'b1111: SSD_CATHODES = 7'b1111111 ; //Nothing 
			4'b0000: SSD_CATHODES = 7'b0000001 ; //0
			4'b0001: SSD_CATHODES = 7'b1001111 ; //1
			4'b0010: SSD_CATHODES = 7'b0010010 ; //2
			4'b0011: SSD_CATHODES = 7'b0000110 ; //3
			4'b0100: SSD_CATHODES = 7'b1001100 ; //4
			4'b0101: SSD_CATHODES = 7'b0100100 ; //5
			4'b0110: SSD_CATHODES = 7'b0100000 ; //6
			4'b0111: SSD_CATHODES = 7'b0001111 ; //7
			4'b1000: SSD_CATHODES = 7'b0000000 ; //8
			4'b1001: SSD_CATHODES = 7'b0000100 ; //9
			4'b1010: SSD_CATHODES = 7'b0001000 ; //10 or A
			default: SSD_CATHODES = 7'bXXXXXXX ; // default is not needed as we covered all cases
		endcase
	end
	
	/////////////////////////////////////////////////////////////////
	//////////////  	  SSD control ends here 	 ///////////////////
	/////////////////////////////////////////////////////////////////
endmodule