.model tiny 
.code 
;.386
org 100h
start:
    jmp install_handler

hw_reset9: retf 
    alt_flag db 0
    mux_id db ? 
    program_id db 0  
    exit_call_flag db 0   
    psp dw ?  
    buffer db 4000 dup (?), 10, 13, '$'   
    off dw 0
    exit_flag db 0
    file_id dw ?
    file_path db 126 dup ("$")
    greeting_message db "Screen Grabber Program", 10, 13, '$' 
    commandline_not_found_message db "Please, enter the path of file in the command line", 10, 13, '$' 
    busy_message db "The program already launched", 10, 13, '$'
    file_not_found_message db "Error! File not found.", 10, 13, '$'   
    path_not_found_message db "Error! Path not found.", 10, 13, '$'
    too_many_opened_files_message db "Error! To many files are opened.", 10, 13, '$'
    access_forbidden_message db "Error! Access is forbidden.", 10, 13, '$'
    wrong_access_mode_message db "Error! Wrong access mode.", 10, 13, '$' 
    read_access_forbidden_message db "Error! Read access is forbidden.", 10, 13, '$'
    wrong_id_message db "Error! Wrong file ID.", 10, 13, '$'
    unexpected_open_error_message db "Unexpected open error!", 10, 13, '$'  
    unexpected_read_error_message db "Unexpected read error!", 10, 13, '$' 
    unexpected_close_error_message db "Unexpected close error!", 10, 13, '$'


new_handler proc far 
    jmp actual_new_handler  
    old_address dd 0
    dw 424bh
    db 00h
    jmp hw_reset9
    db 7 dup (0)
actual_new_handler:    
    pushf
    call dword ptr cs:old_address    
    push ax 
    push bx
    push cx
    push dx
    push bp
    push di
    push si
    push sp
    push ds
    push es 
    

    mov ah, 01h
    int 16h  
    jz  not_pressed 
    cmp ah, 3ch ; F2     
 
    jne not_alt  
    
    
    
    mov al, 1        
    mov alt_flag, al 
    jmp end_int  
    
    

not_alt:     
    cmp ah, 3bh ; F1
    
    jne another_key
    
    mov al, alt_flag
    cmp al, 1
    jne another_key 
    mov al, 0
    mov alt_flag, al



      
    push cs
    pop ds
    push cs
    pop es             
    push ds 
    push 0B800h
    pop ds  
    mov di, offset buffer
    mov si, 0
    mov cx, 4000
    rep movsb 
    pop ds 
    call convert
    call open_file 
    mov al, exit_flag
    cmp al, 1
    je end_int 
    call write_file
    call close_file  
    jmp end_int 
not_pressed:
        mov al, 0
    mov alt_flag, al
    
    
another_key:  
    mov al, 0
    mov alt_flag, al
end_int: 
    mov al, 0
    mov exit_flag, al 
    pop es
    pop ds   
    pop sp
    pop si
    pop di
    pop bp
    pop dx
    pop cx
    pop bx
    pop ax
    iret
new_handler endp 

hw_reset2: retf


new_handler_10 proc far  
    jmp actual_new_handler_10 
    old_address_10 dd 0
    dw 424bh
    db 00h
    jmp hw_reset10
    db 7 dup (0)
actual_new_handler_10:
    cmp ax, 8899h
    je function8899  
    pushf
    call dword ptr cs:old_address
    iret 
function8899:    
    xchg ah, al
    iret
new_handler_10 endp  

hw_reset10: retf

 
print_string macro string
    mov ah, 09h
    mov dx, offset string
    int 21h     
endm   




open_file proc near  
    
    mov ah, 34h
    int 21h
    cmp es:[bx], 0
    jne unexpected_open_error
    cmp es:[bx-1], 0
    jne unexpected_open_error
    
      
    mov ah, 3Dh
    mov al, 1 ;mode: 11000001 - 7: not inherited, 100: no restrictions for other proc, 00: reserved, 0 - cannot write, 1 can read
    mov dx, offset file_path  
    ;mov dx, offset test_string
    mov cl, 0
    int 21h
    jc open_error 
    mov file_id, ax
    jmp end_open_file_proc
open_error: 
    mov bl, 1
    mov exit_flag, bl
file_not_found:
    cmp ax, 02h
    jne path_not_found
    print_string file_not_found_message
    jmp end_open_file_proc  
path_not_found:
    cmp ax, 03h 
    jne too_many_opened_files
    print_string path_not_found_message 
    jmp end_open_file_proc
too_many_opened_files:  
    cmp ax, 04h  
    jne access_forbidden 
    print_string access_forbidden_message 
    jmp end_open_file_proc
access_forbidden:  
    cmp ax, 05h 
    jne wrong_access_mode
    print_string wrong_access_mode_message 
    jmp end_open_file_proc  
wrong_access_mode:
    cmp ax, 0Ch
    jmp unexpected_open_error
    print_string wrong_access_mode_message  
    jmp end_open_file_proc 
unexpected_open_error:
    print_string unexpected_open_error_message    
end_open_file_proc:
    ret        
open_file endp 


close_file proc near  
    mov ah, 34h
    int 21h
    cmp es:[bx], 0
    jne unexpected_close_error
    cmp es:[bx-1], 0
    jne unexpected_close_error 
    mov ah, 3Eh 
    mov bx, file_id
    int 21h
    jc close_error
    jmp end_close_file_proc 
close_error:
    cmp ax, 06h
    jne unexpected_close_error
    print_string wrong_id_message
    jmp end_close_file_proc
unexpected_close_error:
    print_string unexpected_close_error_message    
end_close_file_proc:    
    ret
close_file endp 



write_file proc near    
    
    mov ah, 34h
    int 21h
    cmp es:[bx], 0
    jne unexpected_write_error
    cmp es:[bx-1], 0
    jne unexpected_write_error
    
    
    mov ah, 40h
    mov bx, file_id
    mov cx, 2000
    mov dx, offset buffer
    int 21h 
    jc write_error 
    jmp end_write_file_proc
write_error:
    push ax
    call close_file
    pop ax
    mov bl, 1
    mov exit_flag, bl
write_access_forbidden:
    cmp ax, 05h
    jne wrong_id
    print_string read_access_forbidden_message
    jmp end_write_file_proc
wrong_id:
    cmp ax, 06h
    jne unexpected_write_error    
    print_string wrong_id_message 
    jmp end_write_file_proc
unexpected_write_error:
    print_string unexpected_read_error_message  
    jmp end_write_file_proc 
end_write_file_proc:   
    ret
write_file endp




convert proc near
    mov di, 0
    mov si, 0
    mov cx, 2000  
symbols:
    mov al, buffer[si]
    mov buffer[di], al
    inc di
    inc si
    inc si
    loop symbols 
    mov buffer[di], '$'
    ret
convert endp
install_handler:  

    mov ax, 8899h
    int 10h
       
    cmp ax, 9988h
    je busy
    mov cl, es:80h 
    cmp cl, 0
    je file_path_not_found
    mov si, offset file_path 
    mov di, 81h
    mov al, ' '
    repe scasb
    dec di

copy_path:
    mov al, es:[di]
    cmp al, 13
    je end_copy_path
    mov ds:[si], al
    inc si
    inc di 
    jmp copy_path 
 
file_path_not_found:    
    print_string commandline_not_found_message
    jmp program_end                                        
end_copy_path:
    mov al, 0
    mov ds:[si], al
 
   push es 
    mov ah, 35h
    mov al, 9h
    int 21h
    mov word ptr old_address, bx
    mov word ptr old_address+2, es 
    mov dx, offset new_handler
    mov ah, 25h
    mov al, 9h
    int 21h 
      
      
    mov ah, 35h
    mov al, 10h
    int 21h
    mov word ptr old_address_10, bx
    mov word ptr old_address_10+2, es 
    mov dx, offset new_handler_10
    mov ah, 25h
    mov al, 10h
    int 21h   
   pop es
; resident======================

    mov ax, 3100h
    mov dx, (install_handler-start+200h)/16 
    int 21h                          
    
busy:    
    print_string busy_message 
program_end:    
     
     ret 
amis_sign db "Kreis.A." 
          db "Lab8.int"
          db "Thanks to mister Zubkov and Kalashnikov!", '$', 0  
end start    