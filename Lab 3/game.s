.global _start


.equ pixel_buffer, 0xc8000000 
.equ character_buffer, 0xc9000000
.equ ps2_data_register, 0xff200100
.equ make_code_address, 0xfffffe9f

//an array that contains the vaulues 0, 1, or 2 in each location
cell_values: .word 0, 0, 0, 0, 0, 0, 0, 0, 0, 0	//size = 4*9


_start:
	BL reset_board_ASM
	BL VGA_clear_pixelbuff_ASM
	BL VGA_clear_charbuff_ASM
	BL VGA_fill_ASM
	BL VGA_draw_grid_ASM
	MOV R10, #1		//Keeps track of player turn
	MOV R11, #1
	B input_loop
	
	
	
_end:
	B _end
	
		
//////////////////////////////////////// INPUT LOOP ////////////////////////////////////////////////////////////////

update_player:
	CMP R10, #1		//if current player is player 1
	BEQ p_two		//set current player to player two
	BNE p_one		//else set current player to player one
p_one:	
	MOV R10, #1
	B input_loop
p_two:	
	MOV R10, #2
	B input_loop

input_loop:
	MOV R0, R10
	PUSH {LR}
	BL Player_turn_ASM
	POP {LR}
	PUSH {LR}
	BL read_PS2_data_ASM
	POP {LR}
	CMP R0, #1
	BNE input_loop
	BEQ update_board
	
update_board:
	LDR R0, =ps2_data_register
	LDR R0, [R0]
	B get_cell_number
	
continue_update:
	//Now R0 contains the cell number
	SUB R0, R0, #1
	LDR R3, =cell_values
	LDR R3, [R3, R0, LSL#2]
	CMP R3, #0
	BNE input_loop
	MOV R1, R10
	PUSH {LR}
	BLEQ update_grid_ASM
	POP {LR}
	//after update completed
	PUSH {LR}
	BL check_win_condition
	POP {LR}
	
	B update_player
	
/////////////////////////////////////////UPDATE GRID////////////////////////////////////////////////////////////

update_grid_ASM:
	//RO = cell number, R1 = player number
	PUSH {R0-R12}
	LDR R3, =cell_values
	MOV R5, R0
	STR R1, [R3, R0, LSL#2]
	MOV R0, R1
	
	CMP R5, #0
	PUSH {LR}
	BLEQ draw_in_cell_1
	POP {LR}
	
	CMP R5, #1
	PUSH {LR}
	BLEQ draw_in_cell_2
	POP {LR}
	
	CMP R5, #2
	PUSH {LR}
	BLEQ draw_in_cell_3
	POP {LR}
	
	CMP R5, #3
	PUSH {LR}
	BLEQ draw_in_cell_4
	POP {LR}
	
	CMP R5, #4
	PUSH {LR}
	BLEQ draw_in_cell_5
	POP {LR}
	
	CMP R5, #5
	PUSH {LR}
	BLEQ draw_in_cell_6
	POP {LR}
	
	CMP R5, #6
	PUSH {LR}
	BLEQ draw_in_cell_7
	POP {LR}
	
	CMP R5, #7
	PUSH {LR}
	BLEQ draw_in_cell_8
	POP {LR}
	
	CMP R5, #8
	PUSH {LR}
	BLEQ draw_in_cell_9
	POP {LR}
	
	POP {R0-R12}
	BX LR

/////////////////////////////////////////GET CELL NUMBER/////////////////////////////////////////////////////////
get_cell_number:
	//R0 CONTAINS MAKE CODE 
	CMP R0, #0x69
	MOVEQ R0, #1
	BEQ continue_update
	CMP R0, #0x72
	MOVEQ R0, #2
	BEQ continue_update
	CMP R0, #0x7A
	MOVEQ R0, #3
	BEQ continue_update
	CMP R0, #0x6b
	MOVEQ R0, #4
	BEQ continue_update
	CMP R0, #0x73
	MOVEQ R0, #5
	BEQ continue_update
	CMP R0, #0x74
	MOVEQ R0, #6
	BEQ continue_update
	CMP R0, #0x6c
	MOVEQ R0, #7
	BEQ continue_update
	CMP R0, #0x75
	MOVEQ R0, #8
	BEQ continue_update
	AND R0, R0, #0xff
	CMP R0, #0x7d
	MOVEQ R0, #9
	BEQ continue_update
	BNE input_loop

////////////////////////////////////////WIN CONDITION/////////////////////////////////////////////////////////////

check_win_condition:
	PUSH {R0-R12}
	LDR R0, =cell_values
	B check_horizontal_1
continue:
	CMP R0, #1
	PUSH {LR}
	BLEQ result_ASM
	POP {LR}
	
	CMP R0, #2
	PUSH {LR}
	BLEQ result_ASM
	POP {LR}
	
	LDR R0, =cell_values
	B check_draw
XYZ:	
	CMP R0, #0
	PUSH {LR}
	BLEQ result_ASM
	POP {LR}
	
	POP {R0-R12}
	BX LR

check_horizontal_1:
	LDR R1, [R0]
	LDR R2, [R0, #4]
	LDR R3, [R0, #8]
	CMP R1, #0
	BEQ check_horizontal_2
	CMP R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	B check_horizontal_2
	
check_horizontal_2:
	LDR R1, [R0, #12]
	LDR R2, [R0, #16]
	LDR R3, [R0, #20]
	CMP R1, #0
	BEQ check_horizontal_3
	CMP R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	B check_horizontal_3
	
check_horizontal_3:
	LDR R1, [R0, #24]
	LDR R2, [R0, #28]
	LDR R3, [R0, #32]
	CMP R1, #0
	BEQ check_vertical_1
	CMP R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	B check_vertical_1
	
check_vertical_1:
	LDR R1, [R0]
	LDR R2, [R0, #12]
	LDR R3, [R0, #24]
	CMP R1, #0
	BEQ check_vertical_2
	CMP R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	B check_vertical_2
	
check_vertical_2:
	LDR R1, [R0, #4]
	LDR R2, [R0, #16]
	LDR R3, [R0, #28]
	CMP R1, #0
	BEQ check_vertical_3
	CMP R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	B check_vertical_3
	
check_vertical_3:
	LDR R1, [R0, #8]
	LDR R2, [R0, #20]
	LDR R3, [R0, #32]
	CMP R1, #0
	BEQ check_diagonal_1
	CMP R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	B check_diagonal_1
	
check_diagonal_1:
	LDR R1, [R0]
	LDR R2, [R0, #16]
	LDR R3, [R0, #32]
	CMP R1, #0
	BEQ check_diagonal_2
	CMP R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	B check_diagonal_2
	
check_diagonal_2:
	LDR R1, [R0, #8]
	LDR R2, [R0, #16]
	LDR R3, [R0, #24]
	CMP R1, #0
	BEQ not_complete
	CMPNE R1, R2
	CMPEQ R2, R3
	MOVEQ R0, R1
	BEQ continue
	BNE not_complete
	
not_complete:
	MOV R0, #3	//game not complete
	B continue
	
check_draw:
	LDR R1, [R0]
	CMP R1, #0
	LDRNE R1, [R0, #4]
	CMP R1, #0
	LDRNE R1, [R0, #8]
	CMP R1, #0
	LDRNE R1, [R0, #12]
	CMP R1, #0
	LDRNE R1, [R0, #16]
	CMP R1, #0
	LDRNE R1, [R0, #20]
	CMP R1, #0
	LDRNE R1, [R0, #24]
	CMP R1, #0
	LDRNE R1, [R0, #28]
	CMP R1, #0
	LDRNE R1, [R0, #32]
	CMP R1, #0
	MOVNE R0, #0
	MOVEQ R0, #3
	B XYZ
	
	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

VGA_draw_point_ASM:
	//R0 = x , R1 = y , R2 = color
	PUSH {R0-R12}
	LSL R3, R1, #10			//y << 2
	LSL R4, R0, #1			//x << 1
	ADD R5, R3, R4			//calculate the offset
	LDR R6, =pixel_buffer
	ADD R7, R6, R5			//get the desired pixel
	STRH R2, [R7] 			
	POP {R0-R12}
	BX LR
	

VGA_draw_vertical_line_ASM:
	//R0 = x, R1 = y, R3 = length
	PUSH {R0-R12}
	MOV R4, #0
	LDR R2, =#0xFFFF00
line_loop_1:
		ADD R1, R1, #1
		PUSH {LR}
		BL VGA_draw_point_ASM
		POP {LR}
		ADD R4, R4, #1
		CMP R4, R3
		BLT line_loop_1
	POP {R0-R12}
	BX LR
	

VGA_draw_horizontal_line_ASM:
	//R0 = x, R1 = y, R3 = length
	PUSH {R0-R12}
	MOV R4, #0
	LDR R2, =#0xFFFF00
line_loop_2:
		ADD R0, R0, #1
		PUSH {LR}
		BL VGA_draw_point_ASM
		POP {LR}
		ADD R4, R4, #1
		CMP R4, R3
		BLT line_loop_2
	POP {R0-R12}
	BX LR



VGA_draw_grid_ASM:
	PUSH {R0-R12}
	MOV R3, #207
	
	MOV R0, #125
	MOV R1, #16
	PUSH {LR}
	BL VGA_draw_vertical_line_ASM
	POP {LR}
	
	MOV R0, #194
	MOV R1, #16
	PUSH {LR}
	BL VGA_draw_vertical_line_ASM
	POP {LR}
	
	MOV R0, #56
	MOV R1, #85
	PUSH {LR}
	BL VGA_draw_horizontal_line_ASM
	POP {LR}
	
	MOV R0, #56
	MOV R1, #154
	PUSH {LR}
	BL VGA_draw_horizontal_line_ASM
	POP {LR}
	
	POP {R0-R12}
	BX LR
	
	

draw_plus_ASM:
	//R0 = x, R1 = y
	PUSH {R0-R12}
	//remember x and y
	MOV R9, R0
	MOV R10, R1

	ADD R0, R9, #18
	MOV R1, R10
	MOV R3, #36
	PUSH {LR}
	BL VGA_draw_vertical_line_ASM
	POP {LR}
	
	MOV R0, R9
	ADD R1, R10, #18
	MOV R3, #36
	PUSH {LR}
	BL VGA_draw_horizontal_line_ASM
	POP {LR}
	
	POP {R0-R12}
	BX LR



draw_square_ASM:
	//R0 = x, R1 = y
	PUSH {R0-R12}
	//remember x and y
	MOV R9, R0
	MOV R10, R1

	MOV R0, R9
	MOV R1, R10
	MOV R3, #36
	PUSH {LR}
	BL VGA_draw_vertical_line_ASM
	POP {LR}
	PUSH {LR}
	BL VGA_draw_horizontal_line_ASM
	POP {LR}
	
	ADD R0, R9, #36 
	MOV R1, R10
	MOV R3, #36
	PUSH {LR}
	BL VGA_draw_vertical_line_ASM
	POP {LR}
	
	MOV R0, R9 
	ADD R1, R10, #36
	MOV R3, #36
	PUSH {LR}
	BL VGA_draw_horizontal_line_ASM
	POP {LR}
	
	POP {R0-R12}
	BX LR

	
	
VGA_clear_pixelbuff_ASM:
	PUSH {R0-R12}
	LDR R8, =#319
	LDR R9, =#239
	MOV R2, #0
	MOV R1, #0
	outer_loop_1:
		MOV R0, #0
		inner_loop_1:
			PUSH {LR}
			BL VGA_draw_point_ASM
			POP {LR}
			ADD R0, R0, #1
			CMP R0, R8
			BLE inner_loop_1
		ADD R1, R1, #1
		CMP R1, R9
		BLE outer_loop_1
	POP {R0-R12}
	BX LR
	
	
VGA_fill_ASM:
	PUSH {R0-R12}
	LDR R8, =#319
	LDR R9, =#239
	MOV R2, #0x0000FF	//BLUE
	MOV R1, #0
	outer_loop_3:
		MOV R0, #0
		inner_loop_3:
			PUSH {LR}
			BL VGA_draw_point_ASM
			POP {LR}
			ADD R0, R0, #1
			CMP R0, R8
			BLE inner_loop_3
		ADD R1, R1, #1
		CMP R1, R9
		BLE outer_loop_3
	POP {R0-R12}
	BX LR


VGA_write_char_ASM:
	//R0 = x , R1 = y , R2 = character
	PUSH {R3-R12}
	LSL R3, R1, #7				//y << 7
	ADD R4, R3, R0				//calculate the offset
	LDR R6, =character_buffer
	ADD R7, R6, R4				//get the desired memory
	STRB R2, [R7] 
	POP {R3-R12}
	BX LR


VGA_clear_charbuff_ASM:
	PUSH {R0-R12}
	MOV R2, #0
	MOV R1, #0
	outer_loop_2:
		MOV R0, #0
		inner_loop_2:
			PUSH {LR}
			BL VGA_write_char_ASM
			POP {LR}
			ADD R0, R0, #1
			CMP R0, #79
			BLE inner_loop_2
		ADD R1, R1, #1
		CMP R1, #59
		BLE outer_loop_2
	POP {R0-R12}
	BX LR
	
Player_turn_ASM:
	//R0 = 1 or 2
	PUSH {R0-R12}
	SUB R0, R0, #1
	ADD R0, R0, #49
	MOV R2, R0
	MOV R0, #5
	MOV R1, #5
	PUSH {LR}
	BL VGA_write_char_ASM
	POP {LR}
	POP {R0-R12}
	BX LR


////////////////////////////////////////////RESULT_ASM/////////////////////////////////////////////////
result_ASM:
	//R0 = 0, 1 or 2
	PUSH {R0-R12}
	MOV R3, R0
	CMP R3, #0
	BEQ draw
	CMP R3, #1
	BEQ player_1_wins
	CMP R3, #2
	BEQ player_2_wins
cont:
	B _end
	POP {R0-R12}
	BX LR
	

draw:
	MOV R0, #5
	MOV R1, #5
	MOV R2, #68		//D
	BL VGA_write_char_ASM
	MOV R0, #6
	MOV R1, #5
	MOV R2, #114	//r
	BL VGA_write_char_ASM
	MOV R0, #7
	MOV R1, #5
	MOV R2, #97		//a
	BL VGA_write_char_ASM
	MOV R0, #8
	MOV R1, #5
	MOV R2, #119	//w
	BL VGA_write_char_ASM
	B cont
	
player_1_wins:
	MOV R0, #5
	MOV R1, #5
	MOV R2, #80		//P
	BL VGA_write_char_ASM
	MOV R0, #6
	MOV R1, #5
	MOV R2, #108	//l
	BL VGA_write_char_ASM
	MOV R0, #7
	MOV R1, #5
	MOV R2, #97		//a
	BL VGA_write_char_ASM
	MOV R0, #8
	MOV R1, #5
	MOV R2, #121	//y
	BL VGA_write_char_ASM
	MOV R0, #9
	MOV R1, #5
	MOV R2, #101	//e
	BL VGA_write_char_ASM
	MOV R0, #10
	MOV R1, #5
	MOV R2, #114	//r
	BL VGA_write_char_ASM
	MOV R0, #13
	MOV R1, #5
	MOV R2, #49		//1
	BL VGA_write_char_ASM
	MOV R0, #16
	MOV R1, #5
	MOV R2, #87		//W
	BL VGA_write_char_ASM
	MOV R0, #17
	MOV R1, #5
	MOV R2, #105	//i
	BL VGA_write_char_ASM
	MOV R0, #18
	MOV R1, #5
	MOV R2, #110	//n
	BL VGA_write_char_ASM
	MOV R0, #19
	MOV R1, #5
	MOV R2, #115	//s
	BL VGA_write_char_ASM
	B cont

player_2_wins:
	MOV R0, #5
	MOV R1, #5
	MOV R2, #80		//P
	BL VGA_write_char_ASM
	MOV R0, #6
	MOV R1, #5
	MOV R2, #108	//l
	BL VGA_write_char_ASM
	MOV R0, #7
	MOV R1, #5
	MOV R2, #97		//a
	BL VGA_write_char_ASM
	MOV R0, #8
	MOV R1, #5
	MOV R2, #121	//y
	BL VGA_write_char_ASM
	MOV R0, #9
	MOV R1, #5
	MOV R2, #101	//e
	BL VGA_write_char_ASM
	MOV R0, #10
	MOV R1, #5
	MOV R2, #114	//r
	BL VGA_write_char_ASM
	MOV R0, #13
	MOV R1, #5
	MOV R2, #50		//2
	BL VGA_write_char_ASM
	MOV R0, #16
	MOV R1, #5
	MOV R2, #87		//W
	BL VGA_write_char_ASM
	MOV R0, #17
	MOV R1, #5
	MOV R2, #105	//i
	BL VGA_write_char_ASM
	MOV R0, #18
	MOV R1, #5
	MOV R2, #110	//n
	BL VGA_write_char_ASM
	MOV R0, #19
	MOV R1, #5
	MOV R2, #115	//s
	BL VGA_write_char_ASM
	B cont



///////////////////////////////////////////////////////////////////////////////////////////////////////

draw_in_cell_1:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #73
	MOV R1, #32
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_2:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #141
	MOV R1, #32
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_3:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #209
	MOV R1, #32
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_4:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #73
	MOV R1, #100
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_5:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #141
	MOV R1, #100
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_6:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #209
	MOV R1, #100
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_7:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #73
	MOV R1, #168
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_8:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #141
	MOV R1, #168
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	
draw_in_cell_9:
	//R0 = 1(square) or 2(plus)
	PUSH {R0-R12}
	MOV R3, R0
	MOV R0, #209
	MOV R1, #168
	CMP R3, #1
	PUSH {LR}
	BLEQ draw_square_ASM
	POP {LR}
	CMP R3, #2
	PUSH {LR}
	BLEQ draw_plus_ASM
	POP {LR}
	POP {R0-R12}
	BX LR
	

reset_board_ASM:
	PUSH {R0-R12}
	LDR R0, =cell_values
	MOV R1, #0
	STR R1, [R0]
	STR R1, [R0, #4]
	STR R1, [R0, #8]
	STR R1, [R0, #12]
	STR R1, [R0, #16]
	STR R1, [R0, #20]
	STR R1, [R0, #24]
	STR R1, [R0, #28]
	STR R1, [R0, #32]
	STR R1, [R0, #36]
	POP {R0-R12}
	BX LR
	

@ TODO: insert PS/2 driver here.
read_PS2_data_ASM:
	//R0 contains address of data read
	PUSH {R1-R12}
	LDR R1, =ps2_data_register
	LDR R2, [R1]				//get the data register
	MOV R3, R2					//make a copy of the data register
	LSR R2, R2, #15
	AND R2, R2, #0x1
	MOV R0, R2
	POP {R1-R12}
	BX LR
	
	