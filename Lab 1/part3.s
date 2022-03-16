.global _start

size: .word 5
array: .word -1, 23, 0, 12, -7

_start:
	ldr r0, size
	sub r0, r0, #1	//store size-1 in R0
	ldr r1, =array
	mov r2, #0		//step = 0
	
	
outerLoop:
	mov r3, #0		//i = 0
	innerLoop:
		ldr r5, [r1, r3, lsl#2]		//R5 = value at (ptr + 4i)
		add r7, r3, #1				//R7 = i + 1
		ldr r6, [r1, r7, lsl#2]		//R5 = value at (ptr + 4(i+1))
		cmp r5, r6
		bgt if
continue:		
		add r3, r3, #1
		sub r4, r0, r2
		cmp r3, r4
		blt innerLoop
	add r2, r2, #1
	cmp r2, r0
	blt outerLoop
	b end
	



if:
	str r6, [r1, r3, lsl#2]
	str r5, [r1, r7, lsl#2]
	b continue
	
	
end:
	