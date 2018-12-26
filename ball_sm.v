//////////////////////////////////////////////////////
// File Name:   Ball State Machine
// Author   :   Mikey Takla, Ash Zaveri, Jay Gutierrez
//////////////////////////////////////////////////////

module ball_sm(clk, reset, sys_clk, p1_position, p2_position, vga_h_sync, vga_v_sync, inDisplayArea, CounterX, CounterY, b_display, p1_score, p2_score, color_counter);
input clk;
input reset;
input sys_clk;
input [9:0] p1_position;
input [9:0] p2_position;
output vga_h_sync, vga_v_sync;
output inDisplayArea;
output [9:0] CounterX;
output [9:0] CounterY;
output b_display;
output [3:0] p1_score;
output [3:0] p2_score;
output [1:0] color_counter;

//CounterX and CounterY are used in this file AND top file
//other outputs from hvsync_gen ony used in top file
wire [9:0] X, Y;
hvsync_generator hvsync_gen(.clk(clk), .reset(reset), .vga_h_sync(vga_h_sync), .vga_v_sync(vga_v_sync), .inDisplayArea(inDisplayArea), .CounterX(X), .CounterY(Y));
assign CounterX = X;
assign CounterY = Y;

//local signals
reg [9:0] ball_x;
reg [9:0] ball_y;
reg [6:0] state;
reg TOP1, BOP1, TOP2, BOP2;
wire [9:0] p1_max, p1_min, p2_max, p2_min;
reg [3:0] score1, score2;
integer P1, P2, Y_MAX, Y_MIN, a, b, c;
reg f1, f2;
reg [1:0] color;

assign p1_max = p1_position + 45;
assign p1_min = p1_position - 45;
assign p2_max = p2_position + 45;
assign p2_min = p2_position - 45 ;

localparam
	Q_I  = 7'b0000001,
	Q_H  = 7'b0000010,
	Q_UR = 7'b0000100,
	Q_DL = 7'b0001000,
	Q_UL = 7'b0010000,
	Q_DR = 7'b0100000,
	Q_DONE = 7'b1000000,
	Y_HALF = 245;
	
//state machine
always @ (posedge sys_clk)
	begin
		if (reset)
			begin
			state <= Q_I;
			ball_x <= 300;
			ball_y <= 245;
			TOP1 <= 0;
			BOP1 <= 0;
			TOP2 <= 0;
			BOP2 <= 0;
			color <= 0;
			end
		else
			begin
			TOP1 <= (ball_y >= p1_min && ball_y < p1_position);
			BOP1 <= (ball_y >= p1_position && ball_y <= p1_max);
			TOP2 <= (ball_y >= p2_min && ball_y < p2_position);
			BOP2 <= (ball_y >= p2_position && ball_y <= p2_max);
			case(state)
				Q_I:
					begin
					//state transitions
					state <= Q_H;
					//RTL
					ball_x <= 300;
					ball_y <= 245;
					end
				Q_H:
					begin
					//state transistions
					if (ball_x <= P1)
						begin
						if (TOP1)
							state <= Q_UR;
						else if (BOP1) 
							state <= Q_DR;
						else
							begin
							if (score2 < 9)
								state <= Q_I;
							else
								state <= Q_DONE;
							end
						end
						
					//RTL
					ball_x <= ball_x - a;
					if (ball_x <= P1)
						if (TOP1 || BOP1)
							begin
							if(color == 2)
								color <= 0;
							else
								color <= color + 1;
							end
						else
							score2 <= score2 + 1;
					end
				Q_UR:
					begin
					//state transitions
					if (ball_x < P2)
						begin
						if (ball_y <= Y_MIN)
							state <= Q_DR;
						end
					else
						begin
						if ((ball_y > Y_HALF && TOP2) || (ball_y <= Y_HALF && BOP2))
							state <= Q_UL;
						else if ((ball_y > Y_HALF && BOP2) || (ball_y <= Y_HALF && TOP2))
							state <= Q_DL;
						else
							begin
							if (score1 < 9)
								state <= Q_I;
							else
								state <= Q_DONE;
							end
						end
					//RTL
					ball_x <= ball_x + b;
					ball_y <= ball_y - b;
					if(ball_x < P2)
						begin
						if (ball_y <= Y_MIN)
							begin
							if(color == 2)
								color <= 0;
							else
								color <= color + 1;
							end
						end
					else if (BOP2 || TOP2)
						begin
						if(color == 2)
							color <= 0;
						else
							color <= color + 1;
						end
					else
						score1 <= score1 + 1;
					end
				Q_DL:
					begin
					//state transitions
					if (ball_x > P1)
						begin
						if (ball_y >= Y_MAX)
							state <= Q_UL;
						end
					else
						begin
						if ((ball_y > Y_HALF && TOP1) || (ball_y <= Y_HALF && BOP1))
							state <= Q_DR;
						else if ((ball_y > Y_HALF && BOP1) || (ball_y <= Y_HALF && TOP1))
							state <= Q_UR;
						else
							begin
							if (score2 < 9)
								state <= Q_I;
							else
								state <= Q_DONE;
							end
						end
					//RTL
					ball_x <= ball_x - a;
					ball_y <= ball_y + a;
					if(ball_x > P1)
						begin
						if (ball_y >= Y_MAX)
							begin
							if(color == 2)
								color <= 0;
							else
								color <= color + 1;
							end
						end
					else if (BOP1 || TOP1)
						begin
						if(color == 2)
							color <= 0;
						else
							color <= color + 1;
						end
					else
						score2 <= score2 + 1;
					end
				Q_UL:
					begin
					//state transitions
					if (ball_x > P1)
						begin
						if (ball_y <= Y_MIN)
							state <= Q_DL;
						end
					else
						begin
						if ((ball_y > Y_HALF && TOP1) || (ball_y <= Y_HALF && BOP1))
							state <= Q_UR;
						else if ((ball_y > Y_HALF && BOP1) || (ball_y <= Y_HALF && TOP1))
							state <= Q_DR;
						else
							begin
							if (score2 < 9)
								state <= Q_I;
							else
								state <= Q_DONE;
							end
						end
					//RTL
					ball_x <= ball_x - c;
					ball_y <= ball_y - b;
					if(ball_x > P1)
						begin
						if (ball_y <= Y_MIN)
							begin
							if(color == 2)
								color <= 0;
							else
								color <= color + 1;
							end
						end
					else if (BOP1 || TOP1)
						begin
						if(color == 2)
							color <= 0;
						else
							color <= color + 1;
						end
					else
						score2 <= score2 + 1;
					end
				Q_DR:
					begin
					//state transitions
					if (ball_x < P2)
						begin
						if (ball_y >= Y_MAX)
							state <= Q_UR;
						end
					else
						begin
						if ((ball_y > Y_HALF && TOP2) || (ball_y <= Y_HALF && BOP2))
							state <= Q_DL;
						else if ((ball_y > Y_HALF && BOP2) || (ball_y <= Y_HALF && TOP2))
							state <= Q_UL;
						else
							begin
							if (score1 < 9)
								state <= Q_I;
							else
								state <= Q_DONE;
							end
						end
					//RTL
					ball_x <= ball_x + b;
					ball_y <= ball_y + c;
					if(ball_x < P2)
						begin
						if (ball_y >= Y_MAX)
							begin
							if(color == 2)
								color <= 0;
							else
								color <= color + 1;
							end
						end
					else if (BOP2 || TOP2)
						begin
						if(color == 2)
							color <= 0;
						else
							color <= color + 1;
						end
					else
						score1 <= score1 + 1;
					end
				Q_DONE:
					begin
					ball_x <= 300;
					ball_y <= 250;
					end
				default:
					begin
					state <= 5'bXXXXX;
					end
			endcase
		end
	end

always @ (posedge sys_clk)
begin
	if (reset)
		begin
		P2 <= 605;
		P1 <= 35;
		Y_MAX <= 476;
		Y_MIN <= 5;
		a <= 6;
		b <= 5;
		c <= 7;
		f1 <= 0;
		f2 <= 0;
		end
	else if ((!f1) && (score1 == 4 || score2 == 4))
		begin
		P2 <= 602;
		P1 <= 38;
		Y_MAX <= 473;
		Y_MIN <= 8;
		f1 <= 1;
		a <= 9;
		b <= 7;
		c <= 10;
		end
	else if((!f2) && (score1 == 8 || score2 == 8))
		begin
		P2 <= 588;
		P1 <= 42;
		Y_MAX <= 469;
		Y_MIN <= 12;
		f2 <= 1;
		a <= 12;
		b <= 10;
		c <= 14;
		end
end
	
assign b_display = ball_x <= (X+5) && ball_x >= (X-5) && ball_y <= (Y+5) && ball_y >= (Y-5);
assign p1_score = score1;
assign p2_score = score2;
assign color_counter = color;

endmodule