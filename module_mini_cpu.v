module module_mini_cpu(
	input [17:0] switch,
	input b_en, b_send, clk,
	output EN, RW, RS
);
	
	parameter IDLE = 0, GET = 1, SET = 2, RESET = 3;

	parameter OFF = 0, WAIT_PRESS_EN = 1,
				WAIT_UNPRESS_EN = 2,
				GET1 = 3, GET1_OK = 4, GET2 = 5, GET2_OK = 6,  RESET_RAM = 7, RESET_OK = 8, CALCULATE = 9, ULA_OK = 10,
				SET_RAM = 11, SET_OK = 12, GET_UPDATE = 13, GET_UP = 13, SHOW_DISPLAY = 15;
	
	parameter LOAD = 0, ADD = 1, 
				ADDI = 2, SUB = 3, 
				SUBI = 4, MUL = 5, 
				CLEAR = 6, DISPLAY = 7;
				
	parameter DISPLAY_OFF = 1, SHOW = 2;
	
	reg on = 0;
	reg [3:0] state = OFF;
	reg [1:0] mode_ram = 0;
	reg [2:0] operation = 0;
	reg [3:0] address;
	reg [15:0] data_in;
	reg [15:0] value1 = 0;
	reg [15:0] value2 = 0;
	reg [15:0] value3 = 0;
	reg [15:0] show_value = 0;
	wire done_ram;
	wire done_ula;
	wire done_display;
	reg [1:0] op_display = 0;
	reg [2:0] type_op;
	wire [15:0] data_out;
	wire [15:0] op_result;
	wire wire_en, wire_rw, wire_rs;
	
	
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
	
	DISPLAY display (
		.clk(clk);
		.operation(op_display);
		.opcode(type_op);
		.addr(address);
		.data_addr(show_value);
		.EN(wire_en);
		.RW(wire_rw);
		.RS(wite_rs);
		.done(done_display);
	);
	
	
	always @(posedge b_en) begin
		on <= ~on;
	end
	
	always @(posedge clk) begin
		case (state)
			OFF: begin state <= (done_display)? (on)? WAIT_PRESS_EN : state : state; end
			WAIT_PRESS_EN: begin state <= (on)? (~b_send)? WAIT_UNPRESS_EN : state : RESET_RAM; end
			WAIT_UNPRESS_EN: begin
				if (on) begin
					if (~b_send) begin
						case (switch[17:15])
							LOAD: state <= SET_RAM;
							CLEAR: state <= RESET_RAM;
							DISPLAY: state <= SHOW_DISPLAY;
							default: state <= GET1;
						endcase
					end else begin
						state <= state;
					end
				end else begin
					state <= RESET_RAM;
				end
			end
			GET1: begin state <= (on)? (done_ram)? GET1_OK : state : RESET_RAM; end
			GET1_OK: begin
				if (on) begin
					case(switch[17:15])
						ADD: state <= GET2;
						ADDI: state <= CALCULATE;
						SUB: state <= GET2;
						SUBI: state <= CALCULATE;
						DISPLAY: state <= SHOW_DISPLAY;
					endcase
				end else begin
					state <= RESET_RAM;
				end
			end
			GET2: begin state <= (on)? (done_ram)? GET2_OK: state : RESET_RAM; end
			GET2_OK: begin state <= (on)? CALCULATE : RESET_RAM; end
			RESET_RAM: begin state <= (on)? (done_ram)? RESET_OK : state : OFF; end
			RESET_OK: begin state <= (on)? GET_UPDATE : OFF; end
;			CALCULATE: begin state <= (on)? (done_ula)? ULA_OK: state : RESET_RAM; end
			ULA_OK: begin state <= (on)? SET_RAM : RESET_RAM; end
			SET_RAM: begin state <= (on)? (done_ram)? SET_OK : state : RESET_RAM; end
			SET_OK: begin state <= (on)? GET_UPDATE : RESET_RAM;
			GET_UPDATE: begin state <= (on)? (done_ram)? GET_UP_OK : state : RESET_RAM end
			GET_UP_OK: begin state <= (on)? SHOW_DISPLAY : RESET_RAM; end
			SHOW_DISPLAY: begin state <= (done_display)? (on)? INIT : RESET_RAM : state; end
		endcase
	end
	
	always @(posedge clk) begin
		case (state)
			OFF: op_display <= DISPLAY_OFF;
			WAIT_PRESS_EN: begin mode_ram <= IDLE; operation <= 0; op_display <= IDLE;
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
			end
			GET2: begin
				mode_ram <= GET;
				address <= switch[6:3];
			end
			GET2_OK: begin
				mode_ram <= IDLE;
				value2 <= data_out;
			end
			RESET_RAM: mode_ram <= RESET;
			RESET_OK: mode_ram <= IDLE;
			CALCULATE: operation <= switch[17:15];
			ULA_OK: begin value3 <= op_result; operation <= 0;
			SET_RAM: begin 
				mode_ram <= SET;
				address <= switch[14:11];
				data_in <= (switch[17:15] == LOAD)? switch[6:0] : value3;
			SET_OK: mode_ram = IDLE;
			GET_UPDATE: begin
				mode_ram <= GET;
				address <= switch[14:11];
			end
			GET_UP_OK: begin mode_ram = IDLE;
			SHOW_DISPLAY: begin 
				op_display <= SHOW;
				op_code <= switch[17:15];
				address < switch[14:11];
				show_value <= data_out;
			end
		endcase
	end
	
	assign EN = wire_en;
	assign WR = wire_rw;
	assign RS = wire_rs;
	
endmodule