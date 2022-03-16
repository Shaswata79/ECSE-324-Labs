.global HEX_clear_ASM
.global HEX_flood_ASM
.global HEX_write_ASM

.equ hex_display_base1, 0xFF200020
.equ hex_display_base2, 0xFF200030

	
HEX_clear_ASM:
		PUSH {R0-R12, LR} 		//callee save convention
		LDR R1, =hex_display_base1
		MOV R2, #0				//loop counter
		MOV R3, #1				//the byte against which R0 willl be checked
		//R0 containes the indices of the target displays
		B HEX_clear_loop

HEX_clear_loop:
		CMP R2, #6				//see if we checked all indices
		BGT HEX_clear_return 	//we are done
		AND R4, R0, R3			//check against R3 if bit is 1 at current position
		CMP R4, R3				//if bit is 1 at current position
		BEQ HEX_clear_DO_CLEAR	//then turn of all segments
continue_clear:					//after we are done clearing one display continue with others
		LSL R3, R3, #1			//update the byte we are comparing against
		ADD R2, R2, #1			//update loop counter
		B HEX_clear_loop			
	
HEX_clear_DO_CLEAR:
		CMP R2, #4						//Check if we are in display 4 or 5
		LDRGE R1, =hex_display_base2	//set R1 to the address of display 4 and 5
		SUBGE R5, R2, #4				//subtract 4 if in index 4 or 5
		LDRLT R1, =hex_display_base1	//set R1 to the address of hex display 0, 1, 2 and 3
		MOVLT R5, R2
		LDR R7, [R1]
		
		//??? CLEAR THIS HEX DISPLAY ???//
		CMP R5, #0
		ANDEQ R7, R7, #0xFFFFFF00 		//AND with 1111 1111 1111 1111 1111 1111 0000 0000
		CMP R5, #1
		ANDEQ R7, R7, #0xFFFF00FF			//AND with 1111 1111 1111 1111 0000 0000 1111 1111
		CMP R5, #2
		ANDEQ R7, R7, #0xFF00FFFF			//AND with 1111 1111 0000 0000 1111 1111 1111 1111
		CMP R5, #3
		ANDEQ R7, R7, #0x00FFFFFF			//AND with 0000 0000 1111 1111 1111 1111 1111 1111
		
		STR R7, [R1]
		//////////////////////////////////
		B continue_clear
	
HEX_clear_return:
		POP {R1-R12, LR}
		BX LR
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


HEX_flood_ASM:
		PUSH {R0-R12, LR} 		//callee save convention
		LDR R1, =hex_display_base1
		MOV R2, #0				//loop counter
		MOV R3, #1				//the byte against which R0 willl be checked
		//R0 containes the indices of the target displays
		B HEX_flood_loop
		
HEX_flood_loop:
		CMP R2, #6				//see if we checked all indices
		BGT HEX_flood_return 	//we are done
		AND R4, R0, R3			//check against R3 if bit is 1 at current position
		CMP R4, R3				//if bit is 1 at current position
		BEQ HEX_flood_DO_FLOOD	//then turn of all segments
continue_flood:					//after we are done flooding one display continue with others
		LSL R3, R3, #1			//update the byte we are comparing against
		ADD R2, R2, #1			//update loop counter
		B HEX_flood_loop					
		
HEX_flood_DO_FLOOD:
		CMP R2, #4						//Check if we are in display 4 or 5
		LDRGE R1, =hex_display_base2	//set R1 to the address of display 4 and 5
		SUBGE R5, R2, #4				//subtract 4 if in index 4 or 5
		LDRLT R1, =hex_display_base1	//set R1 to the address of hex display 0, 1, 2 and 3
		MOVLT R5, R2
		LDR R7, [R1]
		
		//??? FLOOD THIS HEX DISPLAY ???//
		CMP R5, #0
		ORREQ R7, R7, #0x000000FF 		//OR with 0000 0000 0000 0000 0000 0000 1111 1111
		CMP R5, #1
		ORREQ R7, R7, #0x0000FF00			//OR with 0000 0000 0000 0000 1111 1111 0000 0000
		CMP R5, #2
		ORREQ R7, R7, #0x00FF0000			//OR with 0000 0000 1111 1111 0000 0000 0000 0000
		CMP R5, #3
		ORREQ R7, R7, #0xFF000000			//0R with 1111 1111 0000 0000 0000 0000 0000 0000
		
		STR R7, [R1]
		//////////////////////////////////
		B continue_flood
	
HEX_flood_return:
		POP {R1-R12, LR}
		BX LR		
		


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


HEX_write_ASM:
		PUSH {R0-R12, LR} 		//callee save convention
		LDR R2, =hex_display_base1
		MOV R3, #0				//loop counter
		MOV R4, #1				//the byte against which R0 willl be checked
		//R0 containes the indices of the target displays
		//R1 contains the value to be written
		B HEX_write_loop
		
HEX_write_loop:
		CMP R3, #6				//see if we checked all indices
		BGT HEX_write_return 	//we are done
		AND R5, R0, R4			//check against R4 if bit is 1 at current position
		CMP R5, R4				//if bit is 1 at current position
		BEQ HEX_write_DO_WRITE	//then turn of all segments
continue_write:					//after we are done writing one display continue with others
		LSL R4, R4, #1			//update the byte we are comparing against
		ADD R3, R3, #1			//update loop counter
		B HEX_write_loop					
		
HEX_write_DO_WRITE:
		CMP R3, #4						//Check if we are in display 4 or 5
		LDRGE R2, =hex_display_base2	//set R2 to the address of display 4 and 5
		SUBGE R6, R3, #4				//subtract 4 if in index 4 or 5
		LDRLT R2, =hex_display_base1	//set R2 to the address of hex display 0, 1, 2 and 3
		MOVLT R6, R3
		LDR R7, [R2]
		
		//??? WRITE THIS HEX DISPLAY ???//
		CMP R6, #0
		MOVEQ R8, #0x000000FF 			//OR with 0000 0000 0000 0000 0000 0000 1111 1111
		MOVEQ R11, #0xFFFFFF00
		CMP R6, #1
		MOVEQ R8, #0x0000FF00			//OR with 0000 0000 0000 0000 1111 1111 0000 0000
		MOVEQ R11, #0xFFFF00FF
		CMP R6, #2
		MOVEQ R8, #0x00FF0000			//OR with 0000 0000 1111 1111 0000 0000 0000 0000
		MOVEQ R11, #0xFF00FFFF
		CMP R6, #3
		MOVEQ R8, #0xFF000000			//0R with 1111 1111 0000 0000 0000 0000 0000 0000
		MOVEQ R11, #0x00FFFFFF
		
		B write_0						//get write value in R9		
back:	
		AND R10, R9, R8
		AND R12, R7, R11
		ORR R10, R10, R12
		STR R10, [R2] 
		//////////////////////////////////
		B continue_write
	
HEX_write_return:
		POP {R1-R12, LR}
		BX LR
		
write_0:
	CMP R1, #0
	BNE write_1
	LDR R9, =#0x3F3F3F3F		//0 = 0011 1111 in hex display
	B back

write_1:
	CMP R1, #1
	BNE write_2
	LDR R9, =#0x06060606		
	B back
	
write_2:
	CMP R1, #2
	BNE write_3
	LDR R9, =#0x5B5B5B5B		
	B back
	
write_3:
	CMP R1, #3
	BNE write_4
	LDR R9, =#0x4F4F4F4F		
	B back
	
write_4:
	CMP R1, #4
	BNE write_5
	LDR R9, =#0x66666666	
	B back
	
write_5:
	CMP R1, #5
	BNE write_6
	LDR R9, =#0x6D6D6D6D
	B back
	
write_6:
	CMP R1, #6
	BNE write_7
	LDR R9, =#0x7D7D7D7D		
	B back
	
write_7:
	CMP R1, #7
	BNE write_8
	LDR R9, =#0x07070707
	B back
	
write_8:
	CMP R1, #8
	BNE write_9
	LDR R9, =#0x7F7F7F7F
	B back
	
write_9:
	CMP R1, #9
	BNE write_A
	LDR R9, =#0x6F6F6F6F
	B back
	
write_A:
	CMP R1, #10
	BNE write_B
	LDR R9, =#0x39393939
	B back
	
write_B:
	CMP R1, #11
	BNE write_C
	LDR R9, =#0x7C7C7C7C		
	B back
	
write_C:
	CMP R1, #12
	BNE write_D
	LDR R9, =#0x39393939		
	B back
	
write_D:
	CMP R1, #13
	BNE write_1
	LDR R9, =#0x5E5E5E5E		
	B back
	
write_E:
	CMP R1, #14
	BNE write_E
	LDR R9, =#0x79797979		
	B back
	
write_F:
	CMP R1, #15
	BNE write_NULL
	LDR R9, =#0x71717171	
	B back
		
write_NULL:
	MOV R9, #0x00000000		
	B back



_end:
	B _end