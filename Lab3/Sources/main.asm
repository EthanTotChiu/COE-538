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
LCD_DAT     EQU     PORTB             ;LCD data port, bits - PB7,...,PB0
LCD_CNTR    EQU     PTJ               ;LCD control port, bits - PE7(RS),PE4(E)
LCD_E       EQU     $80               ;LCD E-signal pin
LCD_RS      EQU     $40               ;LCD RS-signal pin
; Variable/data section
ORG $3850
TEN_THOUS   RMB     1                 ;10,000 digit
THOUSANDS   RMB     1                 ;1,000 digit
HUNDREDS    RMB     1                 ;100 digit
TENS        RMB     1                 ;10 digit
UNITS       RMB     1                 ;1 digit
NO_BLANK    RMB     1                 ;Used in ’leading zero’ blanking by BCD2ASC

; Code section
            ORG     $4000
            
Entry:
_Startup:
            LDS     #$4000            ;initialize the stack pointer
            JSR     initAD            ;initialize ATD converter
            JSR     initLCD           ;initialize LCD
            JSR     clrLCD            ;clear LCD & home cursor
            LDX     #msg1             ;display msg1
            JSR     putsLCD           ;"
            LDAA    #$C0              ;move LCD cursor to the 2nd row
            JSR     cmd2LCD
            LDX     #msg2             ;display msg2
            JSR     putsLCD           ;"
lbl         MOVB    #$90,ATDCTL5      ;r.just., unsign., sing.conv., mult., ch0, start conv.
            BRCLR   ATDSTAT0,$80,*    ;wait until the conversion sequence is complete
            LDAA    ...               ;load the ch4 result into AccA
            LDAB    ...               ;AccB = 39
            MUL                       ;AccD = 1st result x 39
            ADDD    ...               ;AccD = 1st result x 39 + 600
            JSR     int2BCD            
            JSR     BCD2ASC
            LDAA    ...               ;move LCD cursor to the 1st row, end of msg1
            JSR     cmd2LCD           ;   "
            LDAA    TEN_THOUS         ;output the TEN_THOUS ASCII character
            JSR     putcLCD           ;"
                    ...               ;same for THOUSANDS, ’.’ and HUNDREDS
            LDAA    ...               ;move LCD cursor to the 2nd row, end of msg2
            JSR     cmd2LCD           ;"
            BRCLR   PORTAD0,...,bowON
            LDAA    #$31              ;output ’1’ if bow sw OFF
            BRA     bowOFF
bowON       LDAA    #$30              ;output ’0’ if bow sw ON
bowOFF      JSR     putcLCD
                    ...               ;output a space character in ASCII
            BRCLR   PORTAD0,...,sternON
            LDAA    #$31              ;output ’1’ if stern sw OFF
            BRA     sternOFF
sternON     LDAA    #$30              ;output ’0’ if stern sw ON
sternOFF    JSR     putcLCD
            
            JMP     lbl
                   
msg1        dc.b    "Battery volt ",0
msg2        dc.b    "Sw status ",0
            
; Subroutine section
;*******************************************************************
;* Initialization of the LCD: 4-bit data width, 2-line display,    *
;* turn on display, cursor and blinking off. Shift cursor right.   *
;*******************************************************************
initLCD       BSET    DDRS,%11110000     ; configure pins PS7,PS6,PS5,PS4 for output
              BSET    DDRE,%10010000     ; configure pins PE7,PE4 for output
              LDY     #2000              ; wait for LCD to be ready
              JSR     del_50us           ; -"-
              LDAA    #$28               ; set 4-bit data, 2-line display
              JSR     cmd2LCD            ; -"-
              LDAA    #$0C               ; display on, cursor off, blinking off
              JSR     cmd2LCD            ; -"-
              LDAA    #$06               ; move cursor right after entering a character
              JSR     cmd2LCD            ; -"-
              RTSclrLCD ...
;*******************************************************************
;* ([Y] x 50us)-delay subroutine. E-clk=41,67ns. *
;*******************************************************************
del_50us:     PSHX                ;2 E-clk
eloop:        LDX   #30           ;2 E-clk -
iloop:        PSHA                ;2 E-clk |
              PULA                ;3 E-clk |
              PSHA                ;2 E-clk | 50us
              PULA                ;3 E-clk |
              PSHA                ;2 E-clk |
              PULA                ;3 E-clk |
              PSHA                ;2 E-clk |
              PULA                ;3 E-clk |
              PSHA                ;2 E-clk |
              PULA                ;3 E-clk |
              PSHA                ;2 E-clk |
              PULA                ;3 E-clk |
              NOP                 ;1 E-clk |
              NOP                 ;1 E-clk |
              DBNE  X,iloop       ;3 E-clk -
              DBNE  Y,eloop       ;3 E-clk
              PULX                ;3 E-clk
              RTS                 ;5 E-clkcmd2LCD ...
;*******************************************************************
;* This function outputs a NULL-terminated string pointed to by X *
;*******************************************************************
putsLCD       LDAA  1,X+          ; get one character from the string
              BEQ   donePS        ; reach NULL character?
              JSR   putcLCD
              BRA   putsLCD
donePS        RTS
;*******************************************************************
;* This function outputs the character in accumulator in A to LCD *
;*******************************************************************
putcLCD       BSET  LCD_CNTR,LCD_RS  ; select the LCD Data register (DR)
              JSR   dataMov           ; send data to DR
              RTS
;*******************************************************************
;* This function sends data to the LCD IR or DR depening on RS *
;*******************************************************************
dataMov       BSET    LCD_CNTR,LCD_E   ; pull the LCD E-sigal high
              STAA    LCD_DAT          ; send the upper 4 bits of data to LCD
              BCLR    LCD_CNTR,LCD_E   ; pull the LCD E-signal low to complete the write oper.
              LSLA                     ; match the lower 4 bits with the LCD data pins
              LSLA                     ; -"-
              LSLA                     ; -"-
              LSLA                     ; -"-
              BSET    LCD_CNTR,LCD_E   ; pull the LCD E signal high
              STAA    LCD_DAT          ; send the lower 4 bits of data to LCD
              BCLR    LCD_CNTR,LCD_E   ; pull the LCD E-signal low to complete the write oper.
              LDY     #1               ; adding this delay will complete the internal
              JSR     del_50us         ; operation for most instructions
              RTS

           
int2BCD ...


;*******************************************************************
;* Binary to ASCII *
;*******************************************************************
leftHLF       LSRA                    ; shift data to right
              LSRA
              LSRA
              LSRA
rightHLF      ANDA    #$0F             ; mask top half
              ADDA    #$30             ; convert to ascii
              CMPA    #$39
              BLE     out               ; jump if 0-9
              ADDA    #$07             ; convert to hex A-F
out           RTS

initAD        MOVB    #$C0,ATDCTL2      ;power up AD, select fast flag clear
              JSR     del_50us          ;wait for 50 us
              MOVB    #$00,ATDCTL3      ;8 conversions in a sequence
              MOVB    #$85,ATDCTL4      ;res=8, conv-clks=2, prescal=12
              BSET    ATDDIEN,$0C       ;configure pins AN03,AN02 as digital inputs
              RTS
;********************************************************************
;* Interrupt Vectors                                                *
;********************************************************************
              ORG $FFFE
              FDB Entry ; Reset Vector
