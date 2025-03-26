module module_mini_cpu(
	input [17:0] switch,
	input b_en, b_send, clk
);

	paramenter IDLE = 0, GET = 1, SET = 2, RESET = 3;

	parameter OFF = 0, WAIT_PRESS_EN = 1,
				WAIT_UNPRESS_EN = 2,
				GET1 = 3, GET1_OK = 4, GET2 = 5, GET2_OK = 6,  RESET = 7, RESET_OK = 8, CALCULATE = 9, ULA_OK = 10,
				SET = 11, SET_OK = 12, GET_UPDATE = 13, GET_UP = 13, SHOW = 15;
	
	parameter LOAD = 0, ADD = 1, 
				ADDI = 2, SUB = 3, 
				SUBI = 4, MUL = 5, 
				CLEAR = 6, DISPLAY = 7;
				
	reg on = 0;
	
	reg [15:0] value1 = 0;
	reg [15:0] value2 = 0;
	wire [15:0 op_result = 0;
	reg [15:0] value3 = 0;
	reg [2:0] operation = 0;

	reg [3:0] state = OFF;
	
	reg [15:0] show_value = 0;
	reg [1:0] mode_ram;
	reg [3:0] address;
	reg [15:0] data_in;
	wire [15:0] data_out;
	wire done_ram = 0;
	
	wire done_ula = 0;
	
	RAM ram (
		.clk(clk);
		.operation(mode_ram);
		.address(address);
		.data_in(data_in);
		.data_out(data_out);
		.done(done_ram);
	);
	
	ULA ula (
		.clk(clk);
		.opcode(operation);
		.src1(value1);
		.src2(value2);
		.op_result(op_result);
		.done(done_ula);
	);
	
	always @(posedge b_en) begin
		on <= ~on;
	end
	
	always @(posedge clk) begin
		case (state)
			OFF: begin state <= (on)? WAIT_PRESS_EN : state; end
			WAIT_PRESS_EN: begin state <= (on)? (~b_send)? WAIT_UNPRESS_EN : state : RESET; end
			WAIT_UNPRESS_EN: begin
				if (on) begin
					if (~b_send) begin
						case (switch[17:15])
							LOAD: state <= SET;
							CLEAR: state <= RESET;
							DISPLAY: state <= SHOW;
							default: state <= GET1;
						endcase
					end else begin
						state <= state;
					end
				end else begin
					state <= RESET;
				end
			end
			GET1: begin state <= (on)? (done_ram)? GET1_OK : state : RESET; end
			GET1_OK: begin
				if (on) begin
					case(switch[17:15])
						ADD: state <= GET2;
						ADDI: state <= CALCULATE;
						SUB: state <= GET2;
						SUBI: state <= CALCULATE;
						DISPLAY: state <= SHOW;
					endcase
				end else begin
					state <= RESET;
				end
			end
			GET2: begin state <= (on)? (done_ram)? GET2_OK: state : RESET; end
			GET2_OK: begin state <= (on)? CALCULATE : RESET; end
			RESET: begin state <= (on)? (done_ram)? RESET_OK : state : OFF; end
			RESET_OK: begin state <= (on)? SHOW : OFF; end
;			CALCULATE: begin state <= (on)? (done_ula)? ULA_OK: state : RESET; end
			ULA_OK: begin state <= (on)? SET : RESET; end
			SET: begin state <= (on)? (done_ram)? SET_OK : state : RESET; end
			SET_OK: begin state <= (on)? GET_UPDATE : RESET;
			GET_UPDATE: begin state <= (on)? (done_ram)? GET_UP_OK : state : RESET end
			GET_UP_OK: begin state <= (on)? SHOW : RESET; end
			SHOW: begin state <= (on)? INIT : RESET; end
		endcase
	end
	
	always @(posedge clk) begin
		case (state)
			OFF: display(OFF);
			WAIT_PRESS_EN: mode_ram <= IDLE; operation <= 0;
			GET1: begin 
				if (switch[17:15] == DISPLAY) begin
					mode_ram <= GET;
					address <= switch[14:11];
				end else begin
					mode_ram <= GET;
					address <= switch[10:7];
				end
			end
			GET1_OK: begin
				mode_ram <= IDLE;
				value1 <= data_out;
				case (switch[17:0])
					ADDI: value2 <= switch[6:0];
					SUBI: value2 <= switch[6:0];
					MULT: value2 <= switch[6:0];
					default: value2 <= 0;
				endcase
				value2 <= 0;
			end
			GET2: begin
				mode_ram <= GET;
				address <= switch[6:3];
			end
			GET2_OK: begin
				mode_ram <= IDLE;
				value2 <= data_out;
			end
			RESET: mode_ram <= RESET; 
			RESET_OK: mode_ram <= IDLE;
			CALCULATE: operation <= switch[17:15];
			ULA_OK: begin value3 <= op_result; operation <= 0;
			SET: begin 
				mode_ram <= SET;
				address <= switch[14:11];
				data_in <= (switch[17:15] == LOAD)? switch[6:0] : value3;
			SET_OK: mode_ram = IDLE;
			GET_UPDATE: begin
				mode_ram <= GET;
				address <= switch[17:15];
			end
			GET_UP_OK: begin show_value = data_out; mode_ram = IDLE;
			SHOW: 
			
								
	end
	
endmodule