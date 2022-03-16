.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector



.text

.equ PRIVATE_TIMER_load, 0xFFFEC600
.equ PRIVATE_TIMER_counter, 0xFFFEC604
.equ PRIVATE_TIMER_control, 0xFFFEC608
.equ PRIVATE_TIMER_interruptstatus, 0xFFFEC60C

.equ push_button_data, 0xFF200050
.equ push_button_interruptmask, 0xFF200058
.equ push_button_edgecapture, 0xFF20005C
.equ hex_display_base1, 0xFF200020
.equ hex_display_base2, 0xFF200030

PB_int_flag: .word 0x0
tim_int_flag: .word 0x0


.global _start

_start:
	/* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
	MOV R0, #0xF				//enable interrupts from all pushbuttons
	BL enable_PB_INT_ASM
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
	MOV R0, #0x0				
	MOV R1, #0x4				//Move 0100 into R0 in order to set the I bit of Control register to 1
	BL ARM_TIM_config_ASM		
	///////////////////////////////////////////////////////////////////////////////
    //LDR        R0, =0xFF200050      // pushbutton KEY base address
    //MOV        R1, #0xF             // set interrupt mask bits
    //STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
    MSR        CPSR_c, R0
	
	
start_loop:
	//dEBUGGING
	//MOV R0, #0xF				//enable interrupts from all pushbuttons
	//BL enable_PB_INT_ASM
	///////////

	LDR R0, =PB_int_flag
	LDR R0, [R0]
	AND R0, R0, #0x1
	CMP R0, #0x1
	
	BNE start_loop
	
	MOV R7, #0
minutes:
	//dISPLAY//
	MOV R0, #0x10
	MOV R1, R7
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}
	///////////
	
	MOV R6, #0
	tenSeconds:
		//dISPLAY//
		MOV R0, #0x8
		MOV R1, R6
		PUSH {LR}
		BL HEX_write_ASM
		POP {LR}
		//////////
		
		MOV R5, #0
		seconds:
			//dISPLAY//
			MOV R0, #0x4
			MOV R1, R5
			PUSH {LR}
			BL HEX_write_ASM
			POP {LR}
			//////////
			
			MOV R4, #0
			tenMilliseconds:
				//dISPLAY//
				MOV R0, #0x2
				MOV R1, R4
				PUSH {LR}
				BL HEX_write_ASM
				POP {LR}
				//////////
				
				MOV R3, #0
				milliseconds:
					//dISPLAY//
					MOV R0, #0x1
					MOV R1, R3
					PUSH {LR}
					BL HEX_write_ASM
					POP {LR}
					//////////
					
					//Button Stuff//
					LDR R0, =PB_int_flag
					LDR R0, [R0]
					AND R11, R0, #0x4
					CMP R11, #0x4
					BEQ reset
					AND R11, R0, #0x2
					CMP R11, #0x2
					BEQ stop
					
					////////////////
continue_timer:					
					///////Do timer stuff////////////////
					PUSH {LR}
					BL ARM_TIM_reset_INT_ASM
					POP {LR}
					
				timerloop:
						///////Uses interrupt//////
						LDR R0, =tim_int_flag
						LDR R0, [R0]
						CMP R0, #0x1
						BNE timerloop
						
						PUSH {LR}
						BL ARM_TIM_clear_INT_ASM
						POP {LR}
						

					//////////////////////////////////////
	
					ADD R3, R3, #1
					CMP R3, #10
					BLT milliseconds
				ADD R4, R4, #1
				CMP R4, #10
				BLT tenMilliseconds
			ADD R5, R5, #1
			CMP R5, #10
			BLT seconds
		ADD R6, R6, #1
		CMP R6, #6
		BLT tenSeconds
	ADD R7, R7, #1
	B minutes




stop:
	PUSH {LR}
	BL PB_clear_edgecp_ASM
	POP {LR}
	
stop_loop:
	LDR R0, =PB_int_flag
	LDR R0, [R0]
	AND R11, R0, #0x1
	CMP R11, #0x1
	BEQ continue_timer
	AND R11, R0, #0x4
	CMP R11, #0x4
	BEQ reset
	BNE stop_loop
	
	

reset:
	PUSH {LR}
	BL PB_clear_edgecp_ASM
	POP {LR}
	
	MOV R0, #0x1F
	MOV R1, #0
	PUSH {LR}
	BL HEX_write_ASM
	POP {LR}
	B start_loop



	
	
	
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////



/*--- Undefined instructions ---------------------------------------- */
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R0-R7, LR}
	/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR

	/* To Do: Check which interrupt has occurred (check interrupt IDs)
   	Then call the corresponding ISR
   	If the ID is not recognized, branch to UNEXPECTED
   	See the assembly example provided in the De1-SoC Computer_Manual on page 46 */
 Timer_check:
 	CMP R5, #29
	BLEQ ARM_TIM_ISR
	BEQ EXIT_IRQ
 Pushbutton_check:
    CMP R5, #73
	BLEQ KEY_ISR
	BEQ EXIT_IRQ

UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R0-R7, LR}
	SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ


	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////	
	
	
	
CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
	MOV R0, #29            // TIMER port (Interrupt ID = 29)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	
/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
	


/////////////////////////////////////////////////////////ISRs////////////////////////////////////////////////////////


KEY_ISR:
	PUSH {R0, R1, LR}
	//write the content of pushbuttons edgecapture register in to the PB_int_flag memory
	PUSH {LR}
	BL read_PB_edgecp_ASM		//returns edgecapture bits in R0
	POP {LR}
	LDR R1, =PB_int_flag
	STR R0, [R1]
	
	//clear the interrupts
	PUSH {LR}
	BL disable_PB_INT_ASM
	POP {LR}
	
	POP {R0, R1, LR}
    BX LR
	
	
	
ARM_TIM_ISR:
	PUSH {R0, R1}
	
	//writes the value '1' in to the tim_int_flag memory when an interrupt is received
	LDR R1, =tim_int_flag
	MOV R0, #0x1
	STR R0, [R1]
	
	//clears the interrupt
	PUSH {LR}
	BL ARM_TIM_clear_INT_ASM
	POP {LR}

	POP {R0, R1}
    BX LR










///////////////////////////////////////////Timer Drivers///////////////////////////////////////////////////////////

ARM_TIM_config_ASM:
	//R0 contains load value
	//R1 contains config bits
	PUSH {R2-R12}
	LDR R2, =PRIVATE_TIMER_load
	STR R0, [R2]
	LDR R3, =PRIVATE_TIMER_control
	STR R1, [R3]
	POP {R2-R12}
	BX LR

ARM_TIM_read_INT_ASM:
	PUSH {R1-R12}
	LDR R1, =PRIVATE_TIMER_interruptstatus
	LDR R2, [R1]			//load value in interrupt status register
	AND R0, R2, #0x1		//get the last bit only, return in R0
	POP {R1-R12}
	BX LR


ARM_TIM_clear_INT_ASM:
	PUSH {R0-R12}
	LDR R1, =PRIVATE_TIMER_interruptstatus
	MOV R0, #0x1		//The F bit can be cleared to 0 by writing a 0x00000001 into the Interrupt status register
	STR R0, [R1]
	POP {R0-R12}
	BX LR
	

ARM_TIM_reset_INT_ASM:
	PUSH {R0, R1}
	
	//Clear interrupt flag
	MOV R1, #0x0
	LDR R0, =tim_int_flag
	STR R1, [R0]
	
	//Enable interrupts again
	LDR R0, =#0x1E8480		//initial value
	MOV R1, #0x5			//set enable bit to 1				
	PUSH {LR}
	BL ARM_TIM_config_ASM
	POP {LR}
	
	POP {R0, R1}
	BX LR
	





	
///////////////////////////////PUSH BUTTON//////////////////////////////////////////////////////////////////////////



read_PB_data_ASM:
	PUSH {R1}					//callee-save
	LDR R1, =push_button_data	//read data register
	LDR R0, [R1]				//return value in R0
	POP {R1}
	BX LR

read_PB_edgecp_ASM:
	PUSH {R1}							//callee-save
	LDR R1, =push_button_edgecapture	//read edgecapture register
	LDR R0, [R1]						//return value in R0
	POP {R1}
	BX LR
	

PB_clear_edgecp_ASM:
	PUSH {R0, R1}
	LDR R1, =push_button_edgecapture
	LDR R0, [R1]			//read from edgecapture register
	STR R0, [R1]			//writing what was just read, back to the register
	
	LDR R0, =PB_int_flag
	MOV R1, #0x0
	STR R1, [R0]
	
	//ENABLE INTERRUPTS FROM PB AGAIN
	MOV R0, #0xF				//enable interrupts from all pushbuttons
	PUSH {LR}
	BL enable_PB_INT_ASM
	POP {LR}
	
	POP {R0, R1}
	BX LR

enable_PB_INT_ASM:
	//assuming R0 contains the indices of the target pushbuttons
	PUSH {R0, R1}			
	LDR R1, =push_button_interruptmask		//load interruptmask register
	STR R0, [R1]							//store it back
	POP {R0, R1}
	BX LR


disable_PB_INT_ASM:
	//assuming R0 contains the indices of the target pushbuttons
	PUSH {R0-R2}			
	LDR R1, =push_button_interruptmask		//load interruptmask register
	LDR R2, [R1]							//load interrupt mask bits
	EOR R0, R0, #0xF						//first XOR with F(=1111 in binary)
	AND R0, R0, R2							//then AND with value in interrupt mask register
	STR R0, [R1]							//store it back
	POP {R0-R2}
	BX LR

 
 
///////////////////////////////////SEVEN-SEGMENT DISPLAY////////////////////////////////////////////////////////////////////// 
HEX_clear_ASM:
		PUSH {R0-R12} 		//callee save convention
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
		POP {R0-R12}
		BX LR
	

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


HEX_flood_ASM:
		PUSH {R0-R12} 		//callee save convention
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
		ORREQ R7, R7, #0x000000FF 			//OR with 0000 0000 0000 0000 0000 0000 1111 1111
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
		POP {R0-R12}
		BX LR		
		


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////


HEX_write_ASM:
		PUSH {R0-R12} 		//callee save convention
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
		POP {R0-R12}
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
	LDR R9, =#0x77777777
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
	BNE write_E
	LDR R9, =#0x5E5E5E5E		
	B back
	
write_E:
	CMP R1, #14
	BNE write_F
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

	
	