%macro entrada 1
    mov eax, 3  ;input
    mov ebx, 0  ;stdin
    mov ecx, %1 ;endereco destino
    mov edx, 1  ;qtd bytes
    int 80h
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro saida 1
    mov eax, 4     ;output
    mov ebx, 1     ;stdout
    mov ecx, %1    ;endereco do valor a ser exibido
    mov edx, 1     ;qtd bytes do valor
    int 80h
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro imprimeInt 0 ;imprime inteiro [res] na base que estiver em [base]
    %%itoa:
        mov [stackpointer], esp
        cmp dword[res], 0
        je %%itoa.zero
        jl %%itoa.neg
    
    %%itoa.nonzero:
        xor edx, edx
        mov eax, dword[res]
        div dword[base]
        ;edx resto, eax quociente
        push edx
    	
        cmp eax, 0
        je %%itoa.write
        mov [res], eax
        jmp %%itoa.nonzero
    
    %%itoa.write:
        cmp dword[stackpointer], esp
        je %%fim.macro
        pop dword[res]
        add dword[res], 0x30
        saida res
        jmp %%itoa.write
    
    %%itoa.zero:
        push dword[res]
        jmp %%itoa.write

    %%itoa.neg:
    	saida minus
    	neg dword[res]
    	jmp %%itoa.nonzero
    
    %%fim.macro:
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro precedence 1

	; 0 precedence
	cmp %1, dword '('
	je %%p0

	; 1 precedence
	cmp %1, dword '+'
	je %%p1
	cmp %1, dword '-'
	je %%p1

	; 2 precedence
	jmp %%p2

	%%p0: 
		mov [return], dword 0
		jmp %%endPrecedence

	%%p1:
		mov [return], dword 1
		jmp %%endPrecedence

	%%p2:
		mov [return], dword 2

	%%endPrecedence:

%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro applyOp 3 

	mov eax, %1		; eax = num1
	mov ebx, %2		; ebx = num2
	mov ecx, %3		; ecx = operator

	cmp ecx, dword '+'
	je %%opAdd

	cmp ecx, dword '-'
	je %%opSub

	cmp ecx, dword '*'
	je %%opMul

	jmp %%opDiv

	%%opAdd:
		add eax, ebx  							; eax += ebx
		jmp %%ret 

	%%opSub:
		sub eax, ebx 							; eax -= ebx 
		jmp %%ret

	%%opMul:
		mul ebx      							; eax *= ebx 
		jmp %%ret

	%%opDiv:
		cmp ebx, dword 0
		jne %%nextDiv

		mov [divZero], dword 1
		mov ebx, dword 1  

		%%nextDiv:
		xor edx, edx
		div ebx	         						; eax /= ebx
		jmp %%ret 

	%%ret:
		mov [return], eax 					    ; return eax

%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro opStack.push 1
	mov ebx, [opSize]
    mov [opStack+ebx*4], %1
    inc ebx
    mov [opSize], ebx
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro numStack.push 1
	mov ebx, [numSize]
    mov [numStack+ebx*4], %1
    inc ebx
    mov [numSize], ebx
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro getOperands 0
	mov ebx, [numSize]				; ebx = numSize
	dec ebx							; numStack.pop()
	mov ecx, [numStack+ebx*4]		; ecx = numStack.prevtop()
	mov [arg2], ecx
	dec ebx							; numStack.pop()
	mov ecx, [numStack+ebx*4]		; ecx = numStack.prevtop()
	mov [arg1], ecx
	mov [numSize], ebx 				; numSize -= 2
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
%macro getOperator 0
	mov ebx, [opSize]				; ebx = opStack.size()
	dec ebx							; opStack.pop()
	mov ecx, [opStack+ebx*4]		; ecx = opStack.top() 
	mov [arg3], ecx
	mov [opSize], ebx 				; opSize -= 1
%endmacro
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
section .bss

    stackpointer 	resd 1
    res          	resd 1    
    opStack		 	resd 500 ; stack of operators
    numStack	 	resd 500 ; stack of numbers
    input        	resd 1
    return   	 	resd 1 ; stores return of macros
    arg1		 	resd 1
    arg2		 	resd 1
    arg3 			resd 1
    
section .data
	divZero			dd 0
    newline: 	 	dd 10
    minus:			dd 45
    base: 		 	dd 10
    numSize:		dd 0					; points to one position above top of stack
    opSize: 		dd 0					; points to one position above top of stack
    wfe:			db "Bem formatada", 10
    bfe:			db "Erro de formatação", 10
    zfe				db "Erro de divisão por zero", 10
    
section .text
    global main

main:

    entrada input
    mov eax, dword[input]

    ;while it is a space character, receive another
    cmp eax, dword ' '
    je main

    ;jumps if it is an end character
    cmp eax, dword 40
	jl 	endProgram
    
    ;jumps if it isn't a digit
    cmp eax, dword '0'
    jl checkLParen
    cmp eax, dword '9'
    jg checkLParen

    ;push the number onto numStack 
    sub eax, dword '0'
    numStack.push eax
    
    jmp main

checkLParen:
	;jumps if it isn't an opening parentheses
    cmp eax, '('
    jne checkRParen
    
    ;push opening parentheses onto opStack
    opStack.push eax
    jmp main

checkRParen:
	;check if it isn't a closing parentheses
    cmp eax, ')'
    jne checkOp
    
    loop1:

    	;checks for balanced parentheses in the expression
    	
    	;checks if opStack is empty 
   		mov ebx, [opSize]
    	cmp ebx, dword 0
    	je errorPar

    	;get operator from opStack to [arg3]
    	getOperator

    	;if operator is '(': break
    	cmp [arg3], dword '('
    	je endloop
    	
    	;else, get two operands from numStack to [arg1] and [arg2]
    	getOperands

    	applyOp [arg1], [arg2], [arg3] 
    	mov edx, [return]				; edx = applyOp(arg1,arg2,arg3)

    	;push result in numStack
    	numStack.push edx

    	jmp loop1

    endloop:

    jmp main

checkOp:

    precedence eax ;[return] = 1 para + e - ;[return] = 2 para * e /
    mov edx, [return]

    loop2:

    	;checks if opStack is empty 
    	mov ebx, [opSize]
    	cmp ebx, dword 0
    	je endLoop2

    	;checks if top operator on opStack has same or greater precedence as [input]
    	dec ebx				
    	mov ecx, [opStack+ebx*4]
    	precedence ecx
    	cmp [return], edx

    	;if precedence of top operator on opStack < precedence of [input]: break
    	jl endLoop2

    	;else, get operator from opStack to [arg3]
    	getOperator

    	;get two operands from numStack to [arg1] and [arg2]
    	getOperands

    	applyOp [arg1], [arg2], [arg3]
    	mov edx, [return]				; edx = applyOp(arg1,arg2,arg3)

    	;push result onto numStack
    	numStack.push edx

    	jmp loop2

	endLoop2:
		;push [input] onto opStack
		mov eax, [input]
		opStack.push eax

    	jmp main  
    
endProgram:
; while the operator stack is not empty:
	loop3: 
		;checks if opStack is empty 
		mov ebx, [opSize]
    	cmp ebx, dword 0
    	je endLoop3

    	;get operator from opStack to [arg3]
    	getOperator

    	;if operator is '(': errorPar
    	cmp [arg3], dword '('
    	je errorPar

		;get two operands from numStack to [arg1] and [arg2]
		getOperands

    	applyOp [arg1], [arg2], [arg3]
    	mov edx, [return]				; edx = applyOp(arg1,arg2,arg3)

    	;push result onto numStack
        numStack.push edx

    	jmp loop3

    endLoop3:

    	cmp [divZero], dword 1
    	je errorZero

    	mov eax, 4
    	mov ebx, 1
    	mov ecx, wfe
    	mov edx, 14
    	int 80h

    	mov eax, [numStack]
    	mov [res], eax
    	imprimeInt
        saida newline

    	jmp exit

errorPar:
    mov eax, 4
    mov ebx, 1
    mov ecx, bfe
    mov edx, 21
    int 80h

    jmp exit

errorZero:

	mov eax, 4
	mov ebx, 1
	mov ecx, zfe
	mov edx, 27
	int 80h

	jmp exit 

exit:
    mov eax, 1
    xor ebx, ebx
    int 80h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    