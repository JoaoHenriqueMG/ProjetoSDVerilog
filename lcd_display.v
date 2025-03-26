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
parameter WAIT_INSTRUCTION = 0, SHOW = 1;

reg init = 1;
reg state = IDLE;
reg limit;
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
	case (operation) 
		WAIT_INSTRUCTION: begin
			if (init) limit <= 20;
			else begin
				
			end
		end
		SHOW: begin
			init <= 0;
			
		end
	endcase
end

always @ (posedge clk) begin
	case (state) 
		WRITE: EN <= 1;
		WAIT: EN <= 0;
	endcase
	
	case (operation)
		WAIT_INSTRUCTION: begin
			if (init) begin
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
				endcase
			end else begin
			
			end
		end
	endcase
	
	endcase
	
end



