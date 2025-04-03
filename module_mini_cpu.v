module module_mini_cpu(
	input [17:0] switch,
	input b_en, b_send, clk,
	output EN, RW, RS,
	output [7:0] inst_lcd,
	output verif,
	output [15:0] att
);
	
	parameter IDLE = 0, OFF = 0, GET = 1, SET = 2, RESET = 3;

	parameter OFF_CPU = 0, WAIT_PRESS = 1, WAIT_UNPRESS = 2, SEARCH_V1 = 3, GET_V1 = 4,
				 SEARCH_V2 = 5, GET_V2 = 6, CALCULATE = 7, RESULT_CALC = 8, SET_RAM = 9, SET_OK = 10, LCD_UPD = 11,
				 LCD_OK = 12, CLEAR_RAM = 13, CLEAR_OK = 14, RESET_RAM = 15, RESET_OK = 16, GET_UP = 17, GET_UP_OK = 18;
					 
	
	parameter LOAD = 0, ADD = 1, 
				ADDI = 2, SUB = 3, 
				SUBI = 4, MUL = 5, 
				CLEAR = 6, DISPLAY = 7;
				
	parameter UPD = 1, IDLE_LCD = 2;
	
	reg on = 0;
	
	reg reset_ula = 0;
	
	reg [4:0] state = OFF_CPU;
	
	reg [3:0] address;
	
	reg [15:0] data_in;
	
	reg [1:0] mode_ram = 0;
	wire [15:0] data_out;
	wire done_ram;
	
	reg [15:0] value1 = 0;
	reg [15:0] value2 = 0;
	wire [15:0] result_ula;
	wire done_ula;
	
	reg [15:0] value3 = 0;
	
	wire done_display;
	
	wire wire_en, wire_rw, wire_rs;
	reg [1:0] op_display = 0;
	wire [7:0] data_inst_lcd;
	
	reg [2:0] operation;
	
	memory ram (
		.clk(clk),
		.operation(mode_ram),
		.address(address),
		.data_in(data_in),
		.data_out(data_out),
		.done(done_ram)
	);
	
	reg [15:0] data_show;
	
	cpu_ula ula (
		.clk(clk),
		.reset(reset_ula),
		.op_code(switch[17:15]),
		.src1(value1),
		.src2(value2),
		.op_result(result_ula),
		.done(done_ula)
	);
	
	lcd_display display (
		.clk(clk),
		.command(op_display),
		.opcode(switch[17:15]),
		.addr(switch[14:11]),
		.data_addr(data_show),
		.EN(EN),
		.RW(WR),
		.RS(RS),
		.done_display(done_display),
		.data(inst_lcd)
	);
	
	always @(posedge b_en) begin
		on <= ~on;
	end
	
	always @(posedge clk) begin
		case(state)
			OFF_CPU: begin state <= (on)? WAIT_PRESS : RESET_RAM; end
			WAIT_PRESS: state <= (on)? (b_send)? WAIT_PRESS : WAIT_UNPRESS : RESET_RAM;
			WAIT_UNPRESS: begin
				if (on) begin
					if (b_send) begin
						if (switch[17:15] == LOAD)
							state <= SET_RAM;
						else if (switch[17:15] == CLEAR)
							state <= CLEAR_RAM;
						else if (switch[17:15] == DISPLAY)
							state <= GET_UP;
						else
							state <= SEARCH_V1;
					end else
						state <= WAIT_UNPRESS;
				end else
					state <=RESET_RAM;
			end
			SEARCH_V1: state <= (on)? (done_ram) ? GET_V1 : SEARCH_V1 : RESET_RAM;
			GET_V1: begin
				if (on) begin
					if (switch[17:15] == ADD | switch[17:15] == SUB)
						state <= SEARCH_V2;
					else 
						state <= CALCULATE;
				end else
					state <= RESET_RAM;
			end
			SEARCH_V2: state <= (on)? (done_ram) ? GET_V2 : SEARCH_V2 : RESET_RAM;
			GET_V2: state <= (on)? CALCULATE : RESET_RAM;
			CALCULATE: state <= (on)? (done_ula)? RESULT_CALC : CALCULATE : RESET_RAM;
			RESULT_CALC: state <= (on)? SET_RAM : RESET_RAM;
			SET_RAM: state <= (on)? (done_ram)? SET_OK : SET_RAM : RESET_RAM;
			SET_OK: state <= (on)? GET_UP : RESET_RAM;
			GET_UP: state <= (on)? (done_ram)? LCD_UPD : GET_UP : RESET_RAM;
			LCD_UPD: state <= (on)? (done_display)? LCD_OK : LCD_UPD : RESET_RAM;
			LCD_OK: state <= (on)? WAIT_PRESS : RESET_RAM;
			CLEAR_RAM: state <= (on)? (done_ram)? CLEAR_OK : CLEAR_RAM: RESET_RAM;
			CLEAR_OK: state <= (on)? GET_UP : RESET_RAM;
			RESET_RAM: state <= (done_ram)? RESET_OK : RESET_RAM;
			RESET_OK: state <= OFF_CPU;
			
		endcase
	end
	
	always @(posedge clk) begin
		case(state)
			OFF_CPU: begin op_display = OFF; op_display <= OFF; mode_ram <= IDLE; end
			WAIT_PRESS: begin reset_ula <= 0; op_display = IDLE_LCD; mode_ram <= IDLE; end
			SEARCH_V1: begin
				mode_ram <= GET;
				address <= switch[10:7];
			end
			GET_V1: begin
				mode_ram <= IDLE;
				value1 <= data_out;
			end
			SEARCH_V2: begin
				mode_ram <= GET;
				address <= switch[6:3];
			end
			GET_V2: begin
				mode_ram <= IDLE;
				value2 <= data_out;
			end
			CALCULATE: begin
				reset_ula <= 1;
				if (switch[17:15] == ADDI | switch[17:15] == SUBI | switch[17:15] == MUL)
					value2 <= switch[6:0];
			end
			RESULT_CALC: begin
				reset_ula <= 0;
				value3 <= result_ula;
			end
			SET_RAM: begin
				mode_ram <= SET;
				address <= switch[14:11];
				if (switch[17:15] == LOAD)
					data_in <= switch[6:0];
				else 
					data_in <= value3;
			end
			SET_OK: mode_ram = IDLE;
			GET_UP: begin
				mode_ram <= GET;
				address <= switch[14:11];
			end
			LCD_UPD: begin
				data_show <= data_out;
				mode_ram = IDLE;
				op_display <= UPD;
			end
			LCD_OK: op_display <= IDLE_LCD;
			CLEAR_RAM: mode_ram <= RESET;
			CLEAR_OK: mode_ram <= IDLE;
			RESET_RAM: mode_ram <= RESET;
			RESET_OK: mode_ram <= IDLE;
		endcase
	end
	
	assign verif = done_display;
	assign att = value3;
	
endmodule
