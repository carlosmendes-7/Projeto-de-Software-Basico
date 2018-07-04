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

%macro imprimeInt 0 ;imprime inteiro em [res] (base 10)
    %%itoa:
        mov [stackpointer], esp
        cmp dword[res], 0
        je %%itoa.zero 
    
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
    
    %%fim.macro:
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro isNum 1

	mov eax, dword[%1]

    cmp eax, dword 48
    jl checkLParen
    
    cmp eax, dword 57
    jg checkLParen
    
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro isLParen 1

	mov eax, dword[%1]
    
    cmp eax, '('
    jne checkRParen

%endmacro 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro isRParen 1

	mov eax, dword[%1] 

    cmp eax, ')'
    jne checkOp
    
%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro isOp 1

	mov eax, dword[%1]
    
    cmp eax, '*'
    je valid
    
    cmp eax, '/'
    je valid
    
    cmp eax, '-'
    je valid
    
    cmp eax, '+'
    je valid
    
    jmp error

%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro isEnd 1

	mov eax, dword[%1]

	cmp eax, dword 20
	jl 	endProgram

%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro precedence 1

	mov eax, %1

	cmp eax, dword 43
	je %%p1

	cmp eax, dword 45
	je %%p1

	jmp %%p2

	%%p1:
		mov [return], dword 1
		jmp %%endPrecedence

	%%p2: 
		mov [return], dword 2
		jmp %%endPrecedence

	%%endPrecedence:


%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

%macro applyOp 3 

	mov eax, %1									; eax = num1
	mov ebx, %2									; ebx = num2
	mov ecx, %3									; ecx = operator

	cmp eax, dword 43							; eax == '+'
	je %%opAdd

	cmp eax, dword 45							; eax == '-'
	je %%opSub

	cmp eax, dword 42							; eax == '*'
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
		div ebx	         						; eax /= ebx
		jmp %%ret 

	%%ret:
		mov [return], eax 					    ; return eax

%endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

section .bss

    stackpointer 	resd 1
    res          	resd 1    
    opStack		 	resd 500					; stack of operators
    numStack	 	resd 500					; stack of numbers
    input        	resd 1

    return   	 	resd 1						; stores the return of macros
    arg1		 	resd 1
    arg2		 	resd 1
    arg3 			resd 1
    precInput	 	resd 1
    
section .data
    newline: 	 	dd 10
    base: 		 	dd 10
    numSize:		dd 0						; points to one position above the top of stack
    opSize: 		dd 0						; points to one position above the top of stack
    debug:          db "debug", 10
    

section .text
    global main

main:

    entrada input

    isEnd input                   				;check if it is an end character

    saida input
    saida newline

    mov eax, 4
    mov ebx, 1
    mov ecx, numStack
    mov edx, 20
    int 80h
    saida newline

    mov eax, 4
    mov ebx, 1
    mov ecx, opStack
    mov edx, 20
    int 80h
    saida newline

    mov eax, 4
    mov ebx, 1
    mov ecx, debug
    mov edx, 6
    int 80h
    saida newline
    saida newline
    
    checkNum:
    
        isNum input

        ;push the number onto num stack 
        
        mov eax, [input]
        ;sub eax, dword 48
        mov ebx,  [numSize]
        mov [numStack+ebx], eax
        add ebx, dword 1
        mov [numSize], ebx
    
        jmp main
    
    checkLParen:
    
        isLParen input
        
        ; push operator onto op stack
        mov eax, [input]
        mov ebx, [opSize]
        mov [opStack+ebx], eax
        add ebx, dword 1
        mov [opSize], ebx
    
        jmp main
    
    checkRParen:
    
        isRParen input
        
        loop:

        	; only checks for balanced parentheses in the expression
        	
        	; checks if the opStack is not empty 
       		mov ebx, [opSize]				; ebx = opSize().size()
        	cmp ebx, dword 0
        	je error

        	sub ebx, dword 1				; opStack.pop()
        	mov eax, [opStack+ebx]			; eax = opStack.prevtop() 
        	mov [arg3], eax
        	mov [opSize], ebx 				; opSize -= 1

        	cmp eax, dword 40				; (eax == '(')
        	je endloop

        	mov ebx, [numSize]
        	sub ebx, dword 1				; numStack.pop()
        	mov ecx, [numStack+ebx]			; ecx = numStack.prevtop()
        	mov [arg1], ecx

        	sub ebx, dword 1				; numStack.pop()
        	mov edx, [numStack+ebx]			; edx = numStack.prevtop()
        	mov [arg2], edx
        	mov [numSize], ebx 				; numSize -= 2

        	applyOp [arg1], [arg2], [arg3] 
        	mov eax, [return]				; eax = applyOp(arg1,arg2,arg3)

        	mov ebx, [numSize]
        	mov [numStack+ebx], eax			; numStack.push(eax)
        	add ebx, dword 1				
        	mov [numSize], ebx 				; numSize += 1

        	jmp loop

        endloop:
    
        jmp main
    
    checkOp:

	    precedence [input]
	    mov ecx, [return]
	    mov [precInput], ecx

        loop2:

        	; checks if the opStack is not empty 
	    	mov ebx, [opSize]				; ebx = opSize
	    	cmp ebx, dword 0
	    	je endLoop2

	    	sub ebx, dword 1				
        	mov eax, [opStack+ebx]			; eax = opStack.top() 

        	precedence eax
        	mov eax, [return]
        	mov ebx, [precInput]
        	cmp eax, ebx

        	; if precedence(opStack.top()) < precedence(inp) break
        	jl endLoop2

        	mov ebx, [numSize]				; ebx = numSize
        	sub ebx, dword 1				; numStack.pop()
        	mov ecx, [numStack+ebx]			; ecx = numStack.prevtop()
        	mov [arg1], ecx

        	sub ebx, dword 1				; numStack.pop()
        	mov edx, [numStack+ebx]			; edx = numStack.prevtop()
        	mov [arg2], edx
        	mov [numSize], ebx 				; numSize -= 2

        	mov ebx, [opSize]				; ebx = opSize
        	sub ebx, dword 1				; opStack.pop()
        	mov eax, [opStack+ebx]			; eax = opStack.prevtop() 
        	mov [arg3], eax
        	mov [opSize], ebx 				; opSize -= 1

        	applyOp [arg1], [arg2], [arg3]
        	mov eax, [return]				; eax = applyOp(arg1,arg2,arg3)

        	mov ebx, [numSize]
        	mov [numStack+ebx], eax			; numStack.push(eax)
        	add ebx, dword 1				
        	mov [numSize], ebx 				; numSize += 1

        	jmp loop2

    	endLoop2:

    		mov eax, [input]
    		mov ebx, [opSize]
        	mov [opStack+ebx], eax			; opStack.push(eax)
        	add ebx, dword 1				
        	mov [opSize], ebx 				; opSize += 1

        	jmp main  
        
    endProgram:

    	loop3: 
    		; checks if the opStack is not empty 
    		mov ebx, [opSize]				; ebx = opSize
	    	cmp ebx, dword 0
	    	je endLoop3

    		mov ebx, [numSize]				; ebx = numSize
        	sub ebx, dword 1				; numStack.pop()
        	mov ecx, [numStack+ebx]			; ecx = numStack.prevtop()
        	mov [arg1], ecx

        	sub ebx, dword 1				; numStack.pop()
        	mov edx, [numStack+ebx]			; edx = numStack.prevtop()
        	mov [arg2], edx
        	mov [numSize], ebx 				; numSize -= 2

        	mov ebx, [opSize]				; ebx = opSize
        	sub ebx, dword 1				; opStack.pop()
        	mov eax, [opStack+ebx]			; eax = opStack.prevtop() 
        	mov [arg3], eax
        	mov [opSize], ebx 				; opSize -= 1

        	applyOp [arg1], [arg2], [arg3]
        	mov eax, [return]				; eax = applyOp(arg1,arg2,arg3)

            mov ebx, [numSize]
            mov [numStack+ebx], eax         ; numStack.push(eax)
            add ebx, dword 1                
            mov [numSize], ebx              ; numSize += 1

        	jmp loop3

        endLoop3:

        	mov eax, [numStack]
        	mov [res], eax
        	imprimeInt
            saida newline

	    	mov eax, 1
	   		xor ebx, ebx
	    	int 80h

    error:
        ;print invalid char
        mov eax, 1
        mov ebx, 0
        int 80h

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    