section .text

global _start

%macro isNum 1 

    mov eax, %1
    
    cmp eax, '0'
    jl checkLParen
    
    cmp eax, '9'
    jg checkLParen
    
    

%endmacro

%macro isLParen 1

    mov eax, %1
    
    cmp eax, '('
    jne checkRParen

%endmacro 

%macro isRParen 1  

    mov eax, %1
    cmp eax, ')'
    jne checkOp
    
%endmacro

%macro isOp 1
    
    mov eax, %1
    
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


_start:

    ler char
    
    checkNum:
    
        isNum eax
        
        ; push number in num stack 
    
        jmp _start
    
    checkLParen:
    
        isLParen eax
        
        ; push operator in op stack
    
        jmp _start
    
    checkRParen:
    
        isRParen eax
        
        ;check if is a valid expression in parenthesis
    
        jmp _start
    
    checkOp:
    
        isOp eax
        
        valid:
    
        jmp _start
        
        
    error:
        print invalid char

section .data
    numsz dd 0
    opsz dd 0

section .bss

    num resd 500
    op  resd 500
