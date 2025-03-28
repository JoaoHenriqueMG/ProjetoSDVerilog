module lcd_display (
	input clk,
	input [1:0] operation,
	input [3:0] opcode, 
	input [3:0] addr,
	input [3:0] data_addr,
	output reg EN, RW, RS, done,
	output reg [7:0] data
);

parameter WRITE = 0, WAIT = 1;
parameter DISPLAY_OFF = 0, UPDATE = 1, SHOW = 2;
parameter LOAD = 0, ADD = 1, ADDI = 2, SUB = 3, SUBI = 4, MUL = 5, CLEAR = 6, DISPLAY = 7

reg init = 1;
reg state = IDLE;
reg instructions = 0;

integer counter = 0;

always @ (posedge clk) begin
	case (state)
		WRITE: begin
			if (counter == 50000 - 1) begin
				counter <= 0;
				state <= WAIT;
			end else
				counter <= counter + 1;
		end
		WAIT: begin
			if (counter == 50000 - 1) begin
				counter <= 0;
				state <= WRITE;
				if (instructions <= limit) instructions <= instructions + 1;
				else instructions <= instructions;
			end else
				counter <= counter + 1;
		end
	endcase
end

always @ (posedge clk) begin
	case (state) 
		WRITE: EN <= 1;
		WAIT: EN <= 0;
	endcase
	
	case (operation)
		DISPLAY_OFF: begin
			case (instructions) 
				0: begin data <= 8'h38; RS <= 0; end // Set 2 lines
				default: begin data <= 8'h08; RS <= 0; end // Display off, cursor off
			endcase
		end
		UPDATE begin
			// ;-;
		end
		SHOW: begin
			case (instructions) 
				0: begin data <= 8'h38; RS <= 0; end // Set 2 lines
				1: begin data <= 8'h0E; RS <= 0; end // Display on, cursor blinking
				2: begin data <= 8'h01; RS <= 0; end // Clear display screen
				3: begin data <= 8'h02; RS <= 0; end // Return home
				4: begin data <= 8'h06; RS <= 0; end // Shift cursor to right
				5: begin data <= 8'h2D; RS <= 1; end // Write '-'
				6: begin data <= 8'h2D; RS <= 1; end // Write '-'
				7: begin data <= 8'h2D; RS <= 1; end // Write '-'
				8: begin data <= 8'h2D; RS <= 1; end // Write '-'
				9: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				10: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				11: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				12: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				13: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				14: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				15: begin data <= 8'h5B; RS <= 1; end // Write '['
				16: begin data <= 8'h2D; RS <= 1; end // Write '-'
				17: begin data <= 8'h2D; RS <= 1; end // Write '-'
				18: begin data <= 8'h2D; RS <= 1; end // Write '-'
				19: begin data <= 8'h2D; RS <= 1; end // Write '-'
				20: begin data <= 8'h5D; RS <= 1; end // Write ']'
				21: begin data <= 8'hC0; RS <= 0; end // Force cursor to the beginning (2nd line)
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				22: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
			endcase
		end
	endcase
end
endmodule

/*

0: begin data <= 8'h38; RS <= 0; end // Set 2 lines
1: begin data <= 8'h0E; RS <= 0; end // Display on, cursor blinking
2: begin data <= 8'h01; RS <= 0; end // Clear display screen
3: begin data <= 8'h02; RS <= 0; end // Return home
4: begin data <= 8'h06; RS <= 0; end // Shift cursor to right
5: begin data <= 8'h2D; RS <= 1; end // Write '-'
6: begin data <= 8'h2D; RS <= 1; end // Write '-'
7: begin data <= 8'h2D; RS <= 1; end // Write '-'
8: begin data <= 8'h2D; RS <= 1; end // Write '-'
9: begin data <= 8'h10; RS <= 0; end // Move cursor left by one character
10: begin data <= 8'h10; RS <= 0; end // Move cursor left by one character
11: begin data <= 8'h10; RS <= 0; end // Move cursor left by one character
12: begin data <= 8'h10; RS <= 0; end // Move cursor left by one character
13: begin data <= 8'h10; RS <= 0; end // Move cursor left by one character
14: begin data <= 8'h10; RS <= 0; end // Move cursor left by one character
15: begin data <= 8'h5B; RS <= 1; end // Write '['
16: begin data <= 8'h2D; RS <= 1; end // Write '-'
17: begin data <= 8'h2D; RS <= 1; end // Write '-'
18: begin data <= 8'h2D; RS <= 1; end // Write '-'
19: begin data <= 8'h2D; RS <= 1; end // Write '-'
20: begin data <= 8'h5D; RS <= 1; end // Write ']'
21: begin data <= 8'h5D; RS <= 1; end // Write ']'
default: begin data <= 8'h02; RS <= 0; end // Return home 
*/
