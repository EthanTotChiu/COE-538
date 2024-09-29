;********************************************************************
;* Sound tone generator                                             *
;*                                                                  *
;* Plays a single tone for the duration of the loop                 *
;* Author: Ethan Chiu                                               *
;********************************************************************
; export symbols
            XDEF Entry, _Startup              ; export ‘Entry’ symbol
            ABSENTRY Entry              ; for absolute assembly: mark
                                      ; this as applicat. entry point
; Include derivative-specific definitions
            INCLUDE 'derivative.inc'
;********************************************************************
;* Code section                                                     *
;********************************************************************
          BSET DDRP,%11111111             ; Config. Port P for output
          LDAA #%10000000                 ; Prepare to drive PP7 high
MainLoop  STAA PTP                                        ; Drive PP7
          LDX #$1FFF                    ; Initialize the loop counter
Delay     DEX                            ; Decrement the loop counter
          BNE Delay                   ; If not done, continue to loop
          EORA #%10000000                    ; Toggle the MSB of AccA
          BRA MainLoop                               ; Go to MainLoop
;********************************************************************
;* Interrupt Vectors *
;********************************************************************
            ORG $FFFE
            FDB Entry ; Reset Vector