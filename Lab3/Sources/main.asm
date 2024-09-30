;**********************************************************************
;* Battery and Bumper Displays                                        *
;*                                                                    *
;* Reads the battery levels on the bot and displays them on LCD       *
;* Reads bumper and displays on lc if bumper open or closed           *
;* Author: Ethan Chiu                                                 *
;**********************************************************************
; export symbols
            XDEF Entry, _Startup  ; export ‘Entry’ symbol
            ABSENTRY Entry        ; for absolute assembly: mark
                                  ; this as applicat. entry point
; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
;*****************************************************************
;* Displaying battery voltage and bumper states (s19c32) *
;*****************************************************************
; Definitions
LCD_DAT     EQU PORTB             ;LCD data port, bits - PB7,...,PB0
LCD_CNTR    EQU PTJ               ;LCD control port, bits - PE7(RS),PE4(E)
LCD_E       EQU $80               ;LCD E-signal pin
LCD_RS      EQU $40               ;LCD RS-signal pin
; Variable/data section
ORG $3850
TEN_THOUS   RMB 1                 ;10,000 digit
THOUSANDS   RMB 1                 ;1,000 digit
HUNDREDS    RMB 1                 ;100 digit
TENS        RMB 1                 ;10 digit
UNITS       RMB 1                 ;1 digit
NO_BLANK    RMB 1                 ;Used in ’leading zero’ blanking by BCD2ASC

; Code section
            ORG $4000
            
Entry:
_Startup:
            LDS #$4000            ;initialize the stack pointer
            JSR initAD            ;initialize ATD converter
            JSR initLCD           ;initialize LCD
            JSR clrLCD            ;clear LCD & home cursor
            LDX #msg1             ;display msg1
            JSR putsLCD           ;"
            LDAA #$C0             ;move LCD cursor to the 2nd row
            JSR cmd2LCD
            LDX #msg2             ;display msg2
            JSR putsLCD           ;"
lbl         MOVB #$90,ATDCTL5     ;r.just., unsign., sing.conv., mult., ch0, start conv.
            BRCLR ATDSTAT0,$80,*  ;wait until the conversion sequence is complete
            LDAA ...              ;load the ch4 result into AccA
            LDAB ...              ;AccB = 39
            MUL                   ;AccD = 1st result x 39
            ADDD ...              ;AccD = 1st result x 39 + 600
            JSR int2BCD
            JSR BCD2ASC
            LDAA ...              ;move LCD cursor to the 1st row, end of msg1
            JSR cmd2LCD           ;   "
            LDAA TEN_THOUS        ;output the TEN_THOUS ASCII character
            JSR putcLCD           ;"
            ...                   ;same for THOUSANDS, ’.’ and HUNDREDS
            LDAA ...              ;move LCD cursor to the 2nd row, end of msg2
            JSR cmd2LCD           ;"
            BRCLR PORTAD0,...,bowON
            LDAA #$31             ;output ’1’ if bow sw OFF
            BRA bowOFF
bowON       LDAA #$30             ;output ’0’ if bow sw ON
bowOFF      JSR putcLCD
            ...                   ;output a space character in ASCII
            BRCLR PORTAD0,...,sternON
            LDAA #$31             ;output ’1’ if stern sw OFF
            BRA sternOFF
sternON     LDAA #$30             ;output ’0’ if stern sw ON
sternOFF    JSR putcLCD
            
            JMP lbl
            
            msg1 dc.b "Battery volt ",0
            msg2 dc.b "Sw status ",0
            
; Subroutine section
initLCD ...
clrLCD ...
del_50us ...
cmd2LCD ...
putsLCD ...
putcLCD ...
dataMov ...
int2BCD ...
BCD2ASC ...
initAD MOVB #$C0,ATDCTL2          ;power up AD, select fast flag clear
            JSR del_50us          ;wait for 50 us
            MOVB #$00,ATDCTL3     ;8 conversions in a sequence
            MOVB #$85,ATDCTL4     ;res=8, conv-clks=2, prescal=12
            BSET ATDDIEN,$0C      ;configure pins AN03,AN02 as digital inputs
            RTS
; Interrupt vectors
...
