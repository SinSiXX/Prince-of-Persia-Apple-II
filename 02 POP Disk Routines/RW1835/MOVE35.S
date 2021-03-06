 lst off

 org $E00

errcode = 0
get8bit = $E74C

buffer = $1000 ;7 tracks long
bufferend = buffer+$7E00

rw18 = $D000 ;both versions!

slot = $FD
track = $FE
lastrack = $FF

*-------------------------------------------------
*
* CALL RT - moves rw18 routines to their homes in aux mem
*
* CALL RT+3,<5.25" slot>,<BbundID>,<start track>,<end track>
*          ,<3.5" slot>,<block offset>
*

 jmp move

* Get DEST information:

start jsr get8bit
 stx slot525
 jsr get8bit
 stx BbundID
 jsr get8bit
 stx track
 jsr get8bit
 inx
 stx ENDtrack

* SOURCE information

 jsr get8bit
 stx slot35
 jsr $DEBE ;get16bit
 jsr $DD67
 jsr $E752
 sty Boffset
 sta Boffset+1

* From now on we are using aux zpage and $D000

 lda track
 sta $C009
 sta track

 jsr recal525

loop lda track

 pha
 jsr read35
 bcs :plarts
 pla

 sta track
 jsr write525
 bcs :rts

 lda track
 eor ENDtrack
 bne loop

 pha

:plarts pla
:rts lda #0
 rol
 sta $C008 ;back to main mem
 sta errcode
 bit $C081
 rts

ENDtrack db $11

*------------------------------------------------- write525
*
* Write up to 7 tracks from 5.25" floppy.
*

write525 jsr prep525

* Drive on, delay 1 second

 jsr rw18
 db 0,1,10

* Write until buffer is empty or END track reached

 lda #>buffer

:loop sta :writebuf

 jsr rw18
 db $45 ;auto-inc, writesequ
:writebuf db $11
 bcs :error

 lda :writebuf
 jsr buffend?
 bcc :loop
 clc

:error php
 jsr rw18
 db 1 ;drive off
 plp
 rts

*------------------------------------------------- buffend?
*
* Have we reached the end of buffer, or ENDtrack?
* Enter: a - last buffer address
*
* Exit: cs - no more buffer, or ENDtrack reached
*       cc - keep going, a=new buffer address
*

buffend? clc
 adc #$12
 cmp #>bufferend
 bcs :rts

 ldy track
 cpy ENDtrack

:rts rts

*------------------------------------------------- prep525
*
* Prepare to use 5.25" RW18 routine
*

* Normal RW18 routine is in second bank of $D000

prep525 bit $C08B
 bit $C08B

* Set slot of 5.25" drive

 lda #$11
slot525 = *-1
 asl
 asl
 asl
 asl
 sta slot
 tax

* Turn off all phases

 lda $C080,x
 lda $C082,x
 lda $C084,x
 lda $C086,x

* Set Broderbund ID byte

 jsr rw18
 db 7
BbundID db $11

 rts

*------------------------------------------------- recal525
*
* Recalibrate 5.25" floppy drive
*

recal525 jsr prep525

 lda #$A0
 sta lastrack

* Drive on

 jsr rw18
 db 0,1,3 ;.3 second delay

* Seek to track zero

 lda track
 pha

 jsr rw18
 db 2,0,0

 pla
 sta track
 sta :track

* Now seek first track

 jsr rw18
 db 2,0
:track db $11

 jsr rw18
 db 1 ;drive off

 rts

*------------------------------------------------- read35
*
* Read up to 7 tracks to 3.5" disk.
*

read35 jsr prep35

* Write until no more buffer, or ENDtrack is reached

 lda #>buffer

:loop sta :readbuf

 jsr rw18
 db $43 ;auto-inc, writesequ
:readbuf db $11
 bcs :error

 lda :readbuf
 jsr buffend?
 bcc :loop
 clc

:error rts

*------------------------------------------------- prep35
*
* Prepare to use 3.5" RW18 routine
*

* 3.5" RW18 routine is in first bank of $D000

prep35 bit $C083
 bit $C083

* Set slot of 3.5" drive

 lda #$11
slot35 = *-1
 asl
 asl
 asl
 asl
 sta slot
 tax

* Set offset into 3.5" disk

 jsr rw18
 db 8
Boffset da $1111

 rts

*------------------------------------------------- move
*
* Move the RW18 routines to their respective homes.
*
* $1000 - 3.5" rw18 routine
* $2000 - 5.25" rw18 routine
*

move ldx #$83
 lda #$10
 jsr :0
 ldx #$8B
 lda #$20

:0 sta :source+2
 lda #$D0
 sta :dest+2

 lda $C000,x
 lda $C000,x

 sta $C009 ;aux $D000

 ldx #$10
 ldy #0
:source lda $1000,y
:dest sta $D000,y
 iny
 bne :source

 inc :source+2
 inc :dest+2

 dex
 bne :source

 sta $C008
 bit $C081

 rts

*------------------------------------------------- EOF
