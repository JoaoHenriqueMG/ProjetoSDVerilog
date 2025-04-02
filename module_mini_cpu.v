module module_mini_cpu(
	input [17:0] switch,
	input b_en, b_send, clk,
	output EN, RW, RS,
	output [7:0] inst_lcd
);
	
	parameter IDLE = 0, GET = 1, SET = 2, RESET = 3;

	parameter OFF = 0, WAIT_PRESS_EN = 1,
				WAIT_UNPRESS_EN = 2,
				GET1 = 3, GET1_OK = 4, GET2 = 5, GET2_OK = 6,  RESET_RAM = 7, RESET_OK = 8, CALCULATE = 9, ULA_OK = 10,
				SET_RAM = 11, SET_OK = 12, GET_UPDATE = 13, GET_UP = 14, SHOW_DISPLAY = 15;
	
	parameter LOAD = 0, ADD = 1, 
				ADDI = 2, SUB = 3, 
				SUBI = 4, MUL = 5, 
				CLEAR = 6, DISPLAY = 7;
				
	parameter OFF = 0, ON = 1, UPD = 2;
	
	reg on = 0;
	reg [3:0] state = OFF;
	reg [1:0] mode_ram = 0;
	reg [2:0] operation = 0;
	reg [3:0] address;
	reg [15:0] data_in;
	reg [15:0] value1 = 0;
	reg [15:0] value2 = 0;
	reg [15:0] value3 = 0;
	wire done_ram;
	wire done_ula;
	wire done_display;
	reg [1:0] op_display = 0;
	wire [15:0] data_out;
	wire [15:0] op_result;
	wire wire_en, wire_rw, wire_rs;
	wire [7:0] data_inst_lcd;
	
	memory ram (
		.clk(clk),
		.operation(mode_ram),
		.address(address),
		.data_in(data_in),
		.data_out(data_out),
		.done(done_ram)
	);
	
	cpu_ula ula (
		.clk(clk),
		.op_code(operation),
		.src1(value1),
		.src2(value2),
		.op_result(op_result),
		.done(done_ula)
	);
	
	lcd_display display (
		.clk(clk),
		.command(op_display),
		.opcode(switch[17:15]),
		.addr(switch[14:11]),
		.data_addr(data_out),
		.EN(wire_en),
		.RW(wire_rw),
		.RS(wite_rs),
		.done_display(done_display),
		.data(data_inst_lcd)
	);
	
	
	always @(posedge b_en) begin
		on <= ~on;
	end
	
	always @(posedge clk) begin
		case (state)
			OFF: begin state <= (on)? (done_display)? WAIT_PRESS_EN : state : state; end
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
			GET2: begin state <= (on)? (done_ram)? GET2_OK : state : RESET_RAM; end
			GET2_OK: begin state <= (on)? CALCULATE : RESET_RAM; end
			RESET_RAM: begin state <= (on)? (done_ram)? RESET_OK : state : OFF; end
			RESET_OK: begin state <= (on)? GET_UPDATE : OFF; end
			CALCULATE: begin state <= (on)? (done_ula) ? ULA_OK : RESET_RAM : state; end
			ULA_OK: begin state <= (on)? SET_RAM : RESET_RAM; end
			SET_RAM: begin state <= (on)? (done_ram)? SET_OK : state : RESET_RAM; end
			SET_OK: begin state <= (on)? GET_UPDATE : RESET_RAM; end
			GET_UPDATE: begin state <= (on)? (done_ram)? SHOW_DISPLAY : state : RESET_RAM; end
			SHOW_DISPLAY: begin state <= (done_display)? (on)? WAIT_PRESS_EN : RESET_RAM : state; end
		endcase
	end
	
	always @(posedge clk) begin
		case (state)
			OFF: begin op_display <= OFF; mode_ram <= IDLE; end
			WAIT_PRESS_EN: begin op_display <= mode_ram <= IDLE; operation <= 0; end
			GET1: begin
				op_display <= ON
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
					MUL: value2 <= switch[6:0];
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
			RESET_RAM: mode_ram <= RESET; op_display <= ON;
			RESET_OK: mode_ram <= IDLE;
			CALCULATE: operation <= switch[17:15];
			ULA_OK: begin value3 <= op_result; operation <= 0; end
			SET_RAM: begin 
				op_display <= ON;
				mode_ram <= SET;
				address <= switch[14:11];
				data_in <= (switch[17:15] == LOAD)? switch[6:0] : value3;
			end
			SET_OK: mode_ram = IDLE;
			GET_UPDATE: begin
				mode_ram <= GET;
				address <= switch[14:11];
			end
			SHOW_DISPLAY: begin 
				op_display <= UPD;
			end
		endcase
	end
	
	assign EN = wire_en;
	assign WR = wire_rw;
	assign RS = wire_rs;
	assign inst_lcd = data_inst_lcd;
	
endmodule
