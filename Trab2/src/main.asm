
%macro entrada 1
    mov eax, 3  ;input
    mov ebx, 0  ;stdin
    mov ecx, %1 ;endereco destino
    mov edx, 1  ;qtd bytes
    int 80h
%endmacro

%macro saida 1
    mov eax, 4     ;output
    mov ebx, 1     ;stdout
    mov ecx, %1    ;endereco do valor a ser exibido
    mov edx, 1     ;qtd bytes do valor
    int 80h
%endmacro

%macro insert 1 

	mov eax, [%1]
	mov ebx, [inpSz]
	mov [input+ebx*4], eax
	inc ebx
	mov [inpSz], ebx

%endmacro	


section .data

	inpSz 	dd 0						; input array size
	debug   db "debu",10
	newline db 10
	space   db 32
	cont 	dd 0
	isNegative dd 0
	minus:			dd 45
	

section .bss

    
	toPrint resd 1 
	input 	resd 500					; input array
	read  	resd 1						; to read Input
	i 		resd 1
	j		resd 1
	left 	resd 1
	right 	resd 1
	pivo	resd 1
	mid		resd 1
	pointer resd 1
 
section .text

	global main

	main:

		entrada read
		
		mov eax, dword[read]

		;if it is a space character, receive another
	    cmp eax, dword ' '
	    je main

	    ; if it its an endline or an endString char start algorithm
	    cmp eax, dword 20
	    jl startFunc
	    
	    cmp eax, dword '-'
	    jne notNeg
	    
	        mov [isNegative], dword 1 
	        jmp main
	    
	    notNeg:
	    
	    cmp [isNegative], dword 1
	    jne insertArray
	    
	        sub eax, dword 48
	        mov ebx, dword 45
	        sub ebx, eax
	        mov [read], dword ebx
	    
	    insertArray:

		insert read
		
		mov [isNegative], dword 0

		jmp main

		startFunc:
			mov [left], dword 0
			mov eax, [inpSz]
			sub eax, dword 1
			mov [right], eax
			call quickSort

		mov [cont], dword 0					;index of current number
		mov [pointer], dword input
		loop:	

			mov eax, [cont]					; eax = cont
			mov ebx, [inpSz]				; ebx = size of array
			
			cmp eax, ebx 					; cmp cont, size
			je endProgram					; if printed all elements break

			;saida input+eax*4 				; print current element
			mov edx, [pointer]
			mov eax, [edx]
			cmp eax, dword 45
			;mov [toPrint], eax
		;	saida toPrint
		;	saida newline
			
			jge true_label
			false_label:
			
			    
			    mov ebx, dword 45
			    sub ebx, eax
			    add ebx, dword 48
			    mov [toPrint], ebx
			    saida minus
			    saida toPrint
			    
			    jmp exit_if
			    
			true_label:
			
		    	saida [pointer]	
			
			exit_if:
			add [pointer], dword 4		
			saida space
			;saida newline

			mov eax, [cont]
			inc eax							; eax++
			mov [cont], eax  				; cont++
			jmp loop

		endProgram:

			saida newline

		    mov eax, 1
		    xor ebx, ebx
		    int 80h

quickSort:

	mov eax, [left]
	mov [i], eax							; i = left
		
	mov eax, [right]						
	mov [j], eax							; j = right
		
	mov eax, dword 0						; eax = 0
	add eax, [i]							; eax += i
	add eax, [j]							; eax += j
		
	mov ebx, dword 2		
	cdq		
	idiv ebx								; eax /= 2 (mid)
		
	mov ebx, [input+eax*4]					; ebx = input[mid]
	mov [pivo], ebx							; pivo = ebx
		
	while1:		
		
		mov eax, [i]						; eax = i
		mov ebx, [j]						; ebx = j
		
		cmp eax, ebx						; cmp i,j
		
		jg exitWhile						; jmp if i > j
		
		while2:		
			mov ebx, [i]					; ebx = i
			mov eax, [input+ebx*4]			; eax = input[i]
			mov ecx, [pivo]					; ecx = pivo
		
			cmp eax, ecx					; cmp input[i], pivo
			jge while3						; jmp if (input[i] >= pivo)
		
			inc ebx 						; ebx++
			mov [i], ebx					; i = ebx
		
			jmp while2						; back to loop
		
		while3:		
		
			mov ebx, [j] 					; ebx = j
			mov eax, [input+ebx*4]			; eax = input[j]
			mov ecx, [pivo]					; ecx = pivo
		
			cmp eax, ecx					; cmp input[j], pivo
			jle ifLabel						; jmp if (input[j] <= pivo)
		
			dec ebx							; ebx--	
			mov [j], ebx					; j = ebx
		
			jmp while3						; back to Loop
		
		ifLabel:			
		
			mov eax, [i] 					; eax = i 
			mov ebx, [j]					; ebx = j
			cmp eax, ebx
			jg endWhile						; jmp if(i > j)
		
			mov ecx, [input+eax*4] 			; ecx = input[i]
			mov edx, [input+ebx*4]			; edx = input[j]
			mov [input+eax*4], edx			; input[i] = edx (= input[j])
			mov [input+ebx*4], ecx			; input[i] = ecx (= input[i])
					
			inc eax 						; eax++
			mov [i], eax					; i = eax
		
			dec ebx							; ebx--
			mov [j], ebx 					; j = ebx


		endWhile:

			jmp while1 					; back to Loop
		

	exitWhile:	

	push dword[right] 		
	push dword[i]
	push dword[j]
	push dword[left]				

	firstEndIf:

		pop eax				; eax = pilha.top(), pilha.pop()
		pop ebx				; ebx = pilha.top(), pilha.pop()

		cmp eax, ebx		; cmp left, j 
		jge secondEndIf		; jmp if left >= j

		mov [left], eax     ; left = eax ( = left)
		mov [right], ebx    ; right = ebx ( = j)

		call quickSort		; quickSort(input, left, right)

	secondEndIf:

		pop eax				; eax = pilha.top(), pilha.pop()
		pop ebx				; ebx = pilha.top(), pilha.pop()

		cmp eax, ebx 		; cmp i, right

		jge exit            ; jmp if (i >= right)
		mov [left], eax		; left = eax ( = i)
		mov [right], ebx	; right = ebx ( = right)

		call quickSort      ; quickSort(input, left, right)

	exit:

		ret	
