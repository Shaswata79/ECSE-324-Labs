.global _start

n: .word 10 		//The 6th fibonacci number (=8)
f: .space 4

_start:
	ldr r0, n				//R0 = n
	ldr r1, =f   			//R1 = f[0]
	push {lr}
	bl fib					//call subroutine 'fib'
	pop {lr}
	str r0, [r1], #4		//f[i] = R0; then increment address of f
	b end
	
fib:
	cmp r0, #1		//compare n with 1 and set flags
	bgt if			//if n>1 then go to if label
	bx lr			//if n<=1 then return
	
if:
	sub r2, r0, #1
	sub r3, r0, #2
	
	mov r0, r2
	push {r2, r3, lr}
	bl fib
	pop {r2, r3, lr}
	mov r2, r0
	
	mov r0, r3
	push {r2, r3, lr}
	bl fib
	pop {r2, r3, lr}
	mov r3, r0
	
	add r0, r2, r3			//R0 = R2 + R3 (R0 = f[i-1] + f[i-2])
	bx lr
	

end: b end
	
	