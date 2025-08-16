module memory (
	input clk,
	input [2:0] operation, // 0 - Espera; 1 - Ler dados; 2 - Escrever dados; 3 - Clear
	input [3:0] address,
	input [15:0] data_in,
	output wire [15:0] data_out,
	output wire done
);

parameter IDLE = 0, DECODER = 1, GET = 2, SET = 3, CLEAR = 4;
reg [15:0] ram [15:0];
reg [2:0] state = IDLE;
reg [15:0] reg_data_out;
reg reg_done;

integer i;
initial begin
	ram[0] = 0;
	ram[1] = 0;
	ram[2] = 0;
	ram[3] = 0;
	ram[4] = 0;
	ram[5] = 0;
	ram[6] = 0;
	ram[7] = 0;
	ram[8] = 0;
	ram[9] = 0;
	ram[10] = 0;
	ram[11] = 0;
	ram[12] = 0;
	ram[13] = 0;
	ram[14] = 0;
	ram[15] = 0;
end

always @(posedge clk) begin
	case (state)
		IDLE: begin
			if (operation != 0) state <= DECODER;
			else state <= state;
		end
		DECODER: begin
			if (operation == 1) state <= GET;
			else if (operation == 2) state <= SET;
			else if (operation == 3) state <= CLEAR;
			else state <= state;
		end
		GET: begin
			state <= IDLE;
		end
		SET: begin
			state <= IDLE;
		end
		CLEAR: begin
			state <= IDLE;
		end
	endcase
end

	always @(posedge clock) begin
	case (state) 
		IDLE: begin
			reg_data_out <= reg_data_out;
			reg_done <= 0;
		end
		DECODER: begin
			reg_data_out <= reg_data_out;
			reg_done <= 0;
		end
		GET: begin
			reg_data_out <= ram[address];
			reg_done <= 1;
		end
		SET: begin
			ram[address] <= data_in;
			reg_done <= 1;
		end
		CLEAR: begin
			ram[0] = 0;
			ram[1] = 0;
			ram[2] = 0;
			ram[3] = 0;
			ram[4] = 0;
			ram[5] = 0;
			ram[6] = 0;
			ram[7] = 0;
			ram[8] = 0;
			ram[9] = 0;
			ram[10] = 0;
			ram[11] = 0;
			ram[12] = 0;
			ram[13] = 0;
			ram[14] = 0;
			ram[15] = 0;
			reg_done <= 1;
		end
	endcase
end

assign done = reg_done;
assign data_out = reg_data_out;

endmodule
