module cpu_ula(
	input clk,
	input [2:0] 	op_code,
	input [15:0] 	src1,
						src2,
	output [15:0] 	op_result,
	output  			done // sinalização de êxito da operação
);

// parâmetros para o valor do operador
parameter 	ADD = 3'b001,
				ADDI = 3'b010,
				SUB = 3'b011,
				SUBI = 3'b100,
				MUL = 3'b101;

// parâmetros para os estados da ULA
parameter 	START = 2'b00,
				CALCULATE = 2'b01,
				FINISH = 2'b10;

// valores temporários para armazenar O1, O2 ou Imm
reg [15:0] 	temp_src1 = 0,
				temp_src2 = 0,
				reg_op_result = 0;

reg [2:0]	temp_op_code;

reg			reg_done;

// valores para os estados da ULA
reg [1:0] 	state = START;

// lógica sequencial
always @ (posedge clk) begin
	case (state)
		START: // passa para o próximo estado se a operação for referente à ULA
			if (op_code == ADD | op_code == ADDI | op_code == SUB | op_code == SUBI | op_code == MUL)
				state <= CALCULATE;
			else
				state <= START;
		CALCULATE:
				state <= FINISH;
		FINISH:
				state <= START;
	endcase
end

// lógica combinacional
always @ (*) begin
	case (state)
		START: begin // reseta o done, salva os valores para evitar inconsistência no estado seguinte
			reg_done = 0;
			temp_src1 <= src1;
			temp_src2 <= src2;
			temp_op_code <= op_code;
		end
		CALCULATE: // gera o resultado da operação
			case (temp_op_code)
				ADD:
					reg_op_result <= temp_src1 + temp_src2;
				ADDI:
					if (temp_src2[6])
						reg_op_result <= temp_src1 - temp_src2[5:0];
					else
						reg_op_result <= temp_src1 + temp_src2[5:0];
				SUB:
					reg_op_result <= temp_src1 - temp_src2;
				SUBI:
					if (temp_src2[6])
						reg_op_result <= temp_src1 + temp_src2[5:0];
					else
						reg_op_result <= temp_src1 - temp_src2[5:0];
				MUL:
					reg_op_result <= temp_src1 * temp_src2;
			endcase
		FINISH: // confirmação da conclusão da operação
			reg_done <= 1;
	endcase
end

assign	op_result = reg_op_result,
			done = reg_done;

endmodule
