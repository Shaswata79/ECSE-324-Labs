.global read_PB_data_ASM
.global read_PB_edgecp_ASM
.global PB_clear_edgecp_ASM
.global enable_PB_INT_ASM
.global disable_PB_INT_ASM


.equ push_button_data, 0xFF200050
.equ push_button_interruptmask, 0xFF200058
.equ push_button_edgecapture, 0xFF20005C



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






	