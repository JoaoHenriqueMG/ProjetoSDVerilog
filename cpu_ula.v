module cpu_ula(
	input 					clk,
								reset,
	input [2:0] 			op_code,
	input [15:0] 			src1,
								src2,
	output reg [15:0] 	op_result,
	output reg 				done // sinalização de êxito da operação
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

reg [2:0] temp_op_code;

// valores para os estados da ULA
reg [1:0] state = START;

// lógica sequencial
always @ (posedge clk) begin
	if (~reset)
		state <= START;
	else
		case (state)
			START: // passa para o próximo estado se a operação for referente à ULA
				if(op_code == ADD | op_code == ADDI | op_code == SUB | op_code == SUBI | op_code == MUL)
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
			done = 0;
			temp_src1 = src1;
			temp_src2 = src2;
			temp_op_code = op_code;
		end
		CALCULATE: begin // gera o resultado da operação
			case (temp_op_code)
				ADD:
					op_result = temp_src1 + temp_src2;
				ADDI:
					if (temp_src2[6])
						op_result = temp_src1 - temp_src2[5:0];
					else
						op_result = temp_src1 + temp_src2[5:0];
				SUB:
					op_result = temp_src1 - temp_src2;
				SUBI:
					if (temp_src2[6])
						op_result = temp_src1 + temp_src2[5:0];
					else
						op_result = temp_src1 - temp_src2[5:0];
				MUL:
					op_result = temp_src1 * temp_src2;
				default: op_result = op_result;
				endcase
		end
		FINISH: // confirmação da conclusão da operação
			done = 1;
	endcase
end

endmodule
