.global _start

fx: .word 183, 207, 128, 30, 109, 0, 14, 52, 15, 210, 228, 76, 48, 82, 179, 194, 22, 168, 58, 116, 228, 217, 180, 181, 243, 65, 24, 127, 216, 118, 64, 210, 138, 104, 80, 137, 212, 196, 150, 139, 155, 154, 36, 254, 218, 65, 3, 11, 91, 95, 219, 10, 45, 193, 204, 196, 25, 177, 188, 170, 189, 241, 102, 237, 251, 223, 10, 24, 171, 71, 0, 4, 81, 158, 59, 232, 155, 217, 181, 19, 25, 12, 80, 244, 227, 101, 250, 103, 68, 46, 136, 152, 144, 2, 97, 250, 47, 58, 214, 51	
kx: .word 1, 1, 0, -1, -1, 0, 1, 0, -1, 0, 0, 0, 1, 0, 0, 0, -1, 0, 1, 0, -1, -1, 0, 1, 1
	
gx: .space 400

_start:

mov r0, #0		//y = 0

ldr r6, =fx
ldr r7, =kx
ldr r8, =gx
mov r4, #10

loop1:
	mov r1, #0		//x = 0
	loop2:
		mov r5, #0		//sum = 0
		mov r2, #0		//i = 0
		loop3:
			mov r3, #0		//j = 0
			loop4:
				add r9, r1, r3		//temp1 = x + j
				sub r9, r9, #2		//temp1 = temp1 - ksw = x + j - ksw
				add r10, r0, r2		//temp2 = y + i
				sub r10, r10, #2	//temp2 = R10 - khw = y + i - khw
				//******* inside if statement***********//
				cmp r9, #0
				bge if1
				//***************************//
			continue:
				add r3, r3, #1	//j = j + 1
				cmp r3, #5
				blt loop4
			add r2, r2, #1	//i = i + 1
			cmp r2, #5
			blt loop3
		//****storeSum*****//
		mla r11, r4, r0, r1				//position = 10(y) + x
		str r5, [r8, r11, lsl#2]		//gx[position] = sum
		//*****************//
		add r1, r1, #1	//x = x + 1
		cmp r1, #10
		blt loop2
	add r0, r0, #1		//y = y + 1
	cmp r0, #10
	blt loop1
	b end
	
if1:
	cmp r9, #9
	ble if2
	b continue
	
if2:
	cmp r10, #0
	bge if3
	b continue

if3:
	cmp r10, #9
	ble if
	b continue
				

if:
	mov r4, #5
	mla r11, r4, r2, r3 	//kx position = 5(i) + j
	ldr r11, [r7, r11, lsl#2]
	mov r4, #10
	mla r12, r4, r10, r9	//fx position = 10(temp2) + temp1
	ldr r12, [r6, r12, lsl#2]
	mla r5, r11, r12, r5	//R11 = (R11 * R12) + R5 = (kx[pos1] * fx[pos2]) + sum
	b continue

end:
	b end
	
	
	