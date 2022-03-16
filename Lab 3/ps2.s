.global _start

.equ pixel_buffer, 0xc8000000 
.equ character_buffer, 0xc9000000
.equ ps2_data_register, 0xff200100


_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
VGA_draw_point_ASM:
	//R0 = x , R1 = y , R2 = color
	PUSH {R3-R12}
	LSL R3, R1, #10			//y << 2
	LSL R4, R0, #1			//x << 1
	ADD R5, R3, R4			//calculate the offset
	LDR R6, =pixel_buffer
	ADD R7, R6, R5			//get the desired pixel
	STRH R2, [R7] 			
	POP {R3-R12}
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

	
	
	

@ TODO: insert PS/2 driver here.
read_PS2_data_ASM:
	//R0 contains address of data register
	PUSH {R1-R12}
	LDR R1, =ps2_data_register
	LDR R2, [R1]				//get the data registers
	MOV R3, R2					//make a copy of the data register
	LSR R2, R2, #15
	AND R2, R2, #0x1
	CMP R2, #1
	STREQB R3, [R0]
	MOV R0, R2
	POP {R1-R12}
	BX LR


write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}

	
	
	
	