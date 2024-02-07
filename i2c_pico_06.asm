;   Monday am, try to work out issue with lost connection
;   sorted.




    .assume adl=1       ; ez80 ADL memory mode
    .org $40000         ; load code here
    include "macros.inc"
    jp start_here       ; jump to start of code

    .align 64           ; MOS header
    .db "MOS",0,1     

    include "debug_routines.asm"
    include "delay_routines.asm"

start_here:
            
    push af             ; store all the registers
    push bc
    push de
    push ix
    push iy

; ------------------
; This is our actual code
    CLS
    call hidecursor                 ; hide the cursor

    ld hl, string       ; address of string to use
    ld bc, endString - string             ; length of string, or 0 if a delimiter is used

    rst.lil $18         ; Call the MOS API to send data to VDP 

; need to setup i2c port

    call open_i2c


LOOP_HERE:
    MOSCALL $1E                         ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0E)    
    bit 0, a    
    jp nz, EXIT_HERE                    ; ESC key to exit

    MOSCALL $1E                         ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0C)    
    bit 0, a    
    call nz, ping_i2c                    ; TAB key to send i2c data

    ld a, 00010000b
    call multiPurposeDelay      ; wait a bit


    call justrepeat

    jr LOOP_HERE


; ------------------

EXIT_HERE:

; need to close i2c port
   call close_i2c
   call showcursor
    CLS 

    pop iy              ; Pop all registers back from the stack
    pop ix
    pop de
    pop bc
    pop af
    ld hl,0             ; Load the MOS API return code (0) for no errors.   

    ret                 ; Return to MOS


; ------------------
ping_i2c:
    ld hl, i2c_write_buffer
    ld c, $52                   ; i2c address
    ld b, 1                     ; number of bytes to send
    ld (hl), $00
    ld hl, i2c_write_buffer
    MOSCALL $21



    ld a, 00001000b
    call multiPurposeDelay      ; wait a bit

waitHere:
    MOSCALL $1E                         ; get IX pointer to keyvals, currently pressed keys
    ld a, (ix + $0C)    
    bit 0, a    
    jr nz, waitHere                    ; TAB key to exit

    ld a, 00000100b
    call multiPurposeDelay      ; wait a bit

    call read_i2c

;     ld (hl), $00
;     ld hl, i2c_write_buffer
;     MOSCALL $21

    ret  

 ; ------------------

justrepeat:
    ld hl, i2c_write_buffer
    ld c, $52                   ; i2c address
    ld b, 1                     ; number of bytes to send
    ld (hl), $00
    ld hl, i2c_write_buffer
    MOSCALL $21

    ld a, 00000100b
    call multiPurposeDelay      ; wait a bit

    call read_i2c

    ret  

 ; ------------------

read_i2c:

    ; read byte 1

    ld c, $52
    ld b,1
    ld hl, i2c_read_buffer          ; where we put the byte arriving
    MOSCALL $22

    ld a, 00000010b
    call multiPurposeDelay          ; wait a bit

    ld a, (i2c_read_buffer)
    ld (joyX), a

    ; read byte 2

    ld c, $52
    ld b,1
    ld hl, i2c_read_buffer      ; where we put the byte arriving
    MOSCALL $22

    ld a, 00000010b
    call multiPurposeDelay          ; wait a bit

    ld a, (i2c_read_buffer)
    ld (joyY), a

    ; read byte 3

    ld c, $52
    ld b,1
    ld hl, i2c_read_buffer       ; where we put the byte arriving
    MOSCALL $22

    ld a, 00000010b
    call multiPurposeDelay          ; wait a bit

    ld a, (i2c_read_buffer)
    ld (btns), a


                                    ; print values
    ld b, 0
    ld c, 1
    ld a,(joyX)
    call debugA

    ld b, 0
    ld c, 2
    ld a,(joyY)
    call debugA

    ld b, 0
    ld c, 3
    ld a,(btns)
    call debugA

    ret 

 ; ------------------

open_i2c:

    ld c, 3                     ; making assumption based on Jeroen's code
    MOSCALL $1F                 ; open i2c

    ld c, $52                   ; i2c address
    ld b, 1                     ; number of bytes to send
    ld hl, i2c_write_buffer

    ld (hl), $00
    ld hl, i2c_write_buffer
    MOSCALL $21

    ld a, 00000010b
    call multiPurposeDelay          ; wait a bit

    ret 

 ; ------------------

close_i2c:

    MOSCALL $20

    ret 

 ; ------------------

hidecursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,0
    rst.lil $10                 ; VDU 23,1,0
    pop af
    ret


showcursor:
    push af
    ld a, 23
    rst.lil $10
    ld a, 1
    rst.lil $10
    ld a,1
    rst.lil $10                 ; VDU 23,1,1
    pop af
    ret

 ; ------------------


string:
    .db 31, 0,0,"ic2 paddles - ESC to exit"


endString:

i2c_read_buffer:
    .ds 32,1

i2c_write_buffer:
    .ds 32,0

btnC:       .db     0
btnZ:       .db     0

joyX:       .db     0
joyY:       .db     0
btns:       .db     0
angleX:     .db     0
angleY:     .db     0
angleZ:     .db     0



i2cID:  equ     $52




























