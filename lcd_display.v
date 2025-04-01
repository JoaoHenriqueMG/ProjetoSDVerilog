module lcd_display (
	input clk,
	input on,
	input upd;
	input [3:0] opcode, 
	input [3:0] addr,
	output reg EN, RW, RS, done_show,
	output reg [7:0] data
);

parameter WRITE = 0, WAIT = 1; // Estados do lcd
parameter OFF = 0, INIT = 1, UPDATE = 2, SHOW = 3; // Tipos de operações
parameter LOAD = 0, ADD = 1, ADDI = 2, SUB = 3, SUBI = 4, MUL = 5, CLEAR = 6, DISPLAY = 7; // Comandos do opcode

reg state = WRITE;
reg [5:0] instructions = 0;

reg [7:0] show_opcode [3:0];
reg [7:0] show_addr [3:0];
reg [7:0] show_data_addr [5:0];
reg [14:0] num_data;
reg [15:0] data_addr = 69;
reg [1:0] operation;

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
				if (operation == OFF) begin
					if (instructions < 2) instructions <= instructions + 1;
					else instructions <= instructions;
				end else if (operation == SHOW) begin
					if (instructions < 41) instructions <= instructions + 1;
					else instructions <= instructions;
				end else 
					instructions <= 0;
			end else
				counter <= counter + 1;
		end
	endcase
end

always @(posedge clk) begin 
	case(operation)
		OFF: begin operation <= (on)? INIT : operation; end
		INIT: begin operation <= (on)? SHOW : OFF; end
		UPDATE: begin operation <= (on)? SHOW : OFF; end
		SHOW: begin operation <= (on)? (upd)? UPDATE: SHOW : OFF; end
	endcase
end

always @ (posedge clk) begin
	case (state) 
		WRITE: EN <= 1;
		WAIT: EN <= 0;
	endcase
	
	case (operation)
		OFF: begin 
			case(instructions)
				0: begin data <= 8'h38; RS <= 0; end // Set 2 lines
				1: begin data <= 8'h08; RS <= 0; end // Display off, cursor off
			endcase
		INIT: begin
			show_opcode[3] <= 8'h2D; // Write '-'
			show_opcode[2] <= 8'h2D; // Write '-'
			show_opcode[1] <= 8'h2D; // Write '-'
			show_opcode[0] <= 8'h2D; // Write '-'
			show_addr[3] <= 8'h2D; // Write '-'
			show_addr[2] <= 8'h2D; // Write '-'
			show_addr[1] <= 8'h2D; // Write '-'
			show_addr[0] <= 8'h2D; // Write '-'
			show_data_addr[5] <= 8'h2B; // Write +
			show_data_addr[4] <= 8'h30; // Write 0
			show_data_addr[3] <= 8'h30; // Write 0
			show_data_addr[2] <= 8'h30; // Write 0
			show_data_addr[1] <= 8'h30; // Write 0
			show_data_addr[0] <= 8'h30; // Write 0
		end
		UPDATE: begin
			done_show <= 0;
			case (opcode)
				LOAD: begin 
					show_opcode[3] <= 8'h4C; // L
					show_opcode[2] <= 8'h4F; // O
					show_opcode[1] <= 8'h41; // A
					show_opcode[0] <= 8'h44; // D
				end
				ADD: begin 
					show_opcode[3] <= 8'h41; // A
					show_opcode[2] <= 8'h44; // D
					show_opcode[1] <= 8'h44; // D
					show_opcode[0] <= 8'h20; // ' '
				end
				ADDI: begin 
					show_opcode[3] <= 8'h41; // A
					show_opcode[2] <= 8'h44; // D
					show_opcode[1] <= 8'h44; // D
					show_opcode[0] <= 8'h49; // I
				end
				SUB: begin 
					show_opcode[3] <= 8'h53; // S
					show_opcode[2] <= 8'h55; // U
					show_opcode[1] <= 8'h42; // B
					show_opcode[0] <= 8'h20; // ' '
				end
				SUBI: begin 
					show_opcode[3] <= 8'h53; // S
					show_opcode[2] <= 8'h55; // U
					show_opcode[1] <= 8'h42; // B
					show_opcode[0] <= 8'h49; // I
				end
				MUL: begin 
					show_opcode[3] <= 8'h4D; // M
					show_opcode[2] <= 8'h55; // U
					show_opcode[1] <= 8'h4C; // L
					show_opcode[0] <= 8'h20; // ' '
				end
				CLEAR: begin 
					show_opcode[3] <= 8'h43; // C
					show_opcode[2] <= 8'h4C; // L
					show_opcode[1] <= 8'h52; // R
					show_opcode[0] <= 8'h20; // ' '
				end
				DISPLAY: begin 
					show_opcode[3] <= 8'h44; // D
					show_opcode[2] <= 8'h50; // P
					show_opcode[1] <= 8'h4C; // L
					show_opcode[0] <= 8'h20; // ' '
				end
			endcase

			show_addr[0] <= (addr[0] == 1) ? 8'h31 : 8'h30;
			show_addr[1] <= (addr[1] == 1) ? 8'h31 : 8'h30;  
			show_addr[2] <= (addr[2] == 1) ? 8'h31 : 8'h30;  
			show_addr[3] <= (addr[3] == 1) ? 8'h31 : 8'h30;

			num_data <= data_addr[14:0];
			
			show_data_addr[5] <= (data_addr[15] == 0) ? 8'h2B : 8'h2D;
			show_data_addr[4] <= (num_data / 10000) + 48;
			show_data_addr[3] <= ((num_data / 1000) % 10) + 48;
			show_data_addr[2] <= ((num_data / 100) % 10) + 48;
			show_data_addr[1] <= ((num_data / 10) % 10) + 48;
			show_data_addr[0] <= (num_data % 10) + 48;
				
		end
		
		SHOW: begin
			case (instructions)
				0: begin data <= 8'h38; RS <= 0; end // Set 2 lines
				1: begin data <= 8'h0E; RS <= 0; end // Display on, cursor blinking
				2: begin data <= 8'h01; RS <= 0; end // Clear display screen
				3: begin data <= 8'h02; RS <= 0; end // Return home
				4: begin data <= 8'h06; RS <= 0; end // Shift cursor to right
				5: begin data <= show_opcode[3]; RS <= 1; end 
				6: begin data <= show_opcode[2]; RS <= 1; end
				7: begin data <= show_opcode[1]; RS <= 1; end 
				8: begin data <= show_opcode[0]; RS <= 1; end 
				9: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				10: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				11: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				12: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				13: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				14: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				15: begin data <= 8'h5B; RS <= 1; end // Write '['
				16: begin data <= show_addr[3]; RS <= 1; end 
				17: begin data <= show_addr[2]; RS <= 1; end
				18: begin data <= show_addr[1]; RS <= 1; end 
				19: begin data <= show_addr[0]; RS <= 1; end 
				20: begin data <= 8'h5D; RS <= 1; end // Write ']'
				21: begin data <= 8'hC0; RS <= 0; end // Force cursor to the beginning (2nd line)
				22: begin data <= 8'h06; RS <= 0; end // Shift cursor to right
				23: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				24: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				25: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				26: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				27: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				28: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				29: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				30: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				31: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				32: begin data <= 8'h14; RS <= 0; end // Move cursor right by one character
				33: begin data <= show_data_addr[5]; RS <= 1; end
				34: begin data <= show_data_addr[4]; RS <= 1; end
				35: begin data <= show_data_addr[3]; RS <= 1; end
				36: begin data <= show_data_addr[2]; RS <= 1; end
				37: begin data <= show_data_addr[1]; RS <= 1; end
				38: begin data <= show_data_addr[0]; RS <= 1; end
				39: begin data <= 8'h02; RS <= 0; end // Return home
				40: begin data <= 8'h06; RS <= 0; end // Shift cursor to right
				default: done_show <= 1;
			endcase
		end
	endcase
end
endmodule