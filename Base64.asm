; Demetris Doumas 12/5/14 
; Project2 Base64
; one example of a Test file 
; http://en.wikipedia.org/wiki/Base64 


.MODEL small
.STACK 100h
.386

.DATA 

no_Arg		 	db 0ah,'You did not put the correct arguments (c>base64 inputfile outputfile) ',0ah,'$'
nosec_Arg		db 0ah,'Missing output file (c>base64 inputfile outputfile) ',0ah,'$'



; Working with the psp of Dos box command prompt
CmdLnLen equ byte ptr es:[80h] ;Command line length
CmdLn equ byte ptr es:[81h] ;Command line data


InnameFile db 80h dup(?)     
OutnameFile db 80h dup(?)
cRet db "0",0 ; Carrage return counter

;file handlers
inh dw ?; input handler
outh dw ?; output handler
inh2 dw ?; input handler
outh2 dw ?; output handler

;For encoding
inp  db 3   dup(?)
outp db 4 dup(?)

;For decoding
inp2  db 4 dup(?)
outp2 db 3 dup(?)












prompt1 db 'Enter E or e  for Encoding, D or d for Decoding', 0Dh , 0Ah , '$' 
;move the cursur and end the string with $


;==========================================================================;
.CODE
.STARTUP

; need to ge file from command prompt  and argument
; c:>Base64 file.txt e


CALL getArguments

mov ax, @DATA
mov ah, 9
lea dx, prompt1
int 21h


readKeyboard:
mov ah, 10h 
int 16h
cmp al, 'E'
je Encode
cmp al, 'e'
je Encode
cmp al, 'D'
je Decode
cmp al, 'd'
je Decode
cmp al, 'c'
jmp readKeyboard


;===============================================================================;
;==============================Encode===========================================;
;===============================================================================;
Encode PROC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; open
mov ah, 3Dh
sub al, al
mov al, 0
mov dx, offset innameFile
int 21h
jc error
mov inh, ax  ; move ax to in handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; create
mov ah, 3ch
sub cx,cx
mov dx, offset outnameFile
int 21h
jc error
mov outh ,ax ; mov ax to out handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; read and write
next:
mov ah, 3fh
mov bx, inh
mov cx, 3  ; read three bytes
mov dx, offset inp
int 21h

or ax, ax 
jz done

;Byte0
mov al, inp[0]
shr al, 2
add al, 33
mov outp[0], al

;Byte1
mov ah, inp[0]
mov al, inp[1]
shr ax, 4
and al, 63
add al, 33
mov outp[1], al

;Byte2
mov ah, inp[1]
mov al, inp[2]
shr ax, 6
and al, 63
add al, 33
mov outp[2], al

;Byte3
mov al, inp[2]
and al, 63
add al, 33
mov outp[3], al



mov ah,40h
mov bx, outh
mov cx, 4  ; write four bytes
mov dx, offset outp




int 21h
jc error
jmp next
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

error:
done:
mov ah, 3Eh
mov bx, inh
int 21h
mov ah, 3Eh
mov bx, outh
int 21h

Encode ENDP
jmp finish





;==========================================================================;
;=========================Decode===========================================;
;==========================================================================;
Decode PROC  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; open
mov ah, 3Dh
sub al, al
mov al, 0
mov dx, offset innameFile
int 21h
jc E
mov inh, ax  ; move ax to in handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; create
mov ah, 3ch
sub cx,cx
mov dx, offset outnameFile
int 21h
jc E
mov outh ,ax ; mov ax to out handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; read and write
N:
mov ah, 3fh
mov bx, inh
mov cx, 4 ; read four bytes
mov dx, offset inp2
int 21h
;jc error
or ax, ax 
jz Done

mov ah , inp2[0]
mov al , inp2[1]
sub ah , 33
sub al , 33
shl ah , 2
shr al , 4
add al , ah
mov outp2[0] , al

mov ah , inp2[1]
mov al , inp2[2]
sub ah , 33
sub al , 33
shl ah , 4
shr al , 2
add al , ah
mov outp2[1] , al

mov ah , inp2[2]
mov al , inp2[3]
sub ah , 33
sub al , 33
shl ah , 6
add al , ah
mov outp2[2] , al


mov ah,40h
mov bx, outh
mov cx, 3  ; write three bytes
mov dx, offset outp2
int 21h
jc E
jmp N
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

E:
D:
mov ah, 3Eh
mov bx, inh
int 21h
mov ah, 3Eh
mov bx, outh
int 21h




Decode ENDP
jmp finish


;==========================================================================;
;========================Get file name and user's argument=================;
;==========================================================================;
getArguments Proc


push es						
pusha						
mov ah,62h					
int 21h					
mov es,bx					
mov si,offset InnameFile
mov di,81h
sub cx,cx
mov cl,es:[di-1]			
cmp cx,0					
jne argument_found
CALL _no_arguments
argument_found:

mov al,20h
cld
repz scasb
jnz first_argument_found
CALL _no_arguments
first_argument_found:

dec di
input:
mov al,es:[di]			
mov [si],al				
inc si					
inc di					
mov al,es:[di]			
cmp al,0Dh
jne comp_space
CALL _no_second_argument
comp_space:
cmp al,20h
jz done_input
jmp input

done_input:
mov byte ptr[si],0

mov al,20h				
repz scasb				
jnz writting_output
CALL _no_arguments
writting_output:
dec di

mov si,offset OutnameFile
_output:
mov al,es:[di]
mov [si],al
inc si
inc di
mov al,es:[di]
cmp al,20h
jz L3
cmp al,0Dh
jz L3
loop _output

L2: stc
L3: 
mov byte ptr [si],0
popa
pop es
ret


getArguments ENDP


_no_arguments PROC 
mov ah,9
lea dx, no_Arg
int 21h
jmp done
ret
_no_arguments ENDP

_no_second_argument PROC
mov ah,9
lea dx,nosec_Arg
int 21h
jmp done
ret
_no_second_argument ENDP




finish:

   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   int 16h
   mov  ah,4ch                 ;DOS terminate program function
   int  21h                    ;terminate the program

END