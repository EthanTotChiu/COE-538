;********************************************************************
;* Colored LED controlled through keypad                            *
;*                                                                  *
;* Alternates through different colors                              *
;* Depending on which key was pressed last                          *
;* Author: Ethan Chiu                                               *
;********************************************************************
; export symbols
            XDEF Entry, _Startup              ; export �Entry� symbol
            ABSENTRY Entry              ; for absolute assembly: mark
                                      ; this as applicat. entry point
; Include derivative-specific definitions
            INCLUDE 'derivative.inc'

;********************************************************************
;* The actual program starts here *
;********************************************************************
            ORG     $4000
Entry:
_Startup:
            BSET DDRP,%11111111     ; Configure Port P for output (LED2 cntrl)
            BSET DDRE,%00010000     ; Configure pin PE4 for output (enable bit)
            BCLR PORTE,%00010000    ; Enable keypad
Loop:       LDAA PTS                ; Read a key code into AccA
            LSRA                    ; Shift right AccA
            LSRA                    ; -"-
            LSRA                    ; -"-
            LSRA                    ; -"-
            STAA PTP                ; Output AccA content to LED2
            BRA Loop                ; Loop
;********************************************************************
;* Interrupt Vectors *
;********************************************************************
            ORG $FFFE
            FDB Entry ; Reset Vector