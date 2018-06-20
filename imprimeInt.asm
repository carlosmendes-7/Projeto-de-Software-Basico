%macro entrada 1
    mov eax, 3  ;input
    mov ebx, 0  ;stdin
    mov ecx, %1 ;endereco destino
    mov edx, 4  ;qtd bytes
    int 80h
%endmacro

%macro saida 1
    mov eax, 4     ;output
    mov ebx, 1     ;stdout
    mov ecx, %1    ;endereco do valor a ser exibido
    mov edx, 4     ;qtd bytes do valor
    int 80h
%endmacro

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

section .bss
    stackpointer resd 1 ;usada em imprimeInt
    res          resd 1 ;usada em imprimeInt
    
section .data
    newline: dd 10
    base: dd 10
    
section .text
    global _start

_start:
    ;entrada num
    ;sub dword[num], 0xA30
    mov [res], dword 985254
    imprimeInt 
    saida newline
    
    mov [res], dword 0
    imprimeInt
    saida newline
    
    mov [res], dword 6666
    imprimeInt
    saida newline
    
    mov eax, 1
    xor ebx, ebx
    int 80h
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;    
