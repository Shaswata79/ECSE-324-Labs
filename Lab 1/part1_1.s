.global _start

n: .word 6	//6th fibonacci number (= 8)
f: .space 28	//size = n*4

_start:
	ldr r0, n
	ldr r1, =f
	mov r5, #0			//R5 = 0
	mov r6, #1			//R6 = 1
	str r5, [r1], #4	//f[0] = 0
	str r6, [r1], #4	//f[1] = 1
	mov r3, #2			//i = 2
	
loop:
	cmp r3, r0				//do i-n and set flags
	bgt _end				//if i>n we are done
	ldr r5, [r1, #-4]		//R5 = f[i-1]
	ldr r6, [r1, #-8]		//R6 = f[i-2]
	add r4, r5, r6			//R4 = R5 + R6 (R4 = f[i-1] + f[i-2])
	str r4, [r1], #4		//f[i] = R4; then increment address of f
	add r3, r3, #1
	b loop
end:
	