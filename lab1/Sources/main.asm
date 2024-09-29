;********************************************************************
;* Multiplication Program                                           *
;*                                                                  *
;* It multiplies together two 8 bit numbers and leaves the result   *
;* in the ‘PRODUCT’ location.                                       *
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
                ORG     $3000
MULTIPLICAND    FCB     04                             ; First Number
MULTIPLIER      FCB     05                            ; Second Number
PRODUCT         RMB     1                    ; Result of mltiplcation
;********************************************************************
;* The actual program starts here *
;********************************************************************
            ORG     $4000
Entry:
_Startup:
            LDAA    MULTIPLICAND     ; Get the first number into ACCA
            LDAB    MULTIPLIER      ; Get the second number into ACCB
            MUL                    ; multiply to it the second number
            STD     PRODUCT                   ; and store the product
            SWI                                ; break to the monitor
;********************************************************************
;* Interrupt Vectors *
;********************************************************************
            ORG $FFFE
            FDB Entry ; Reset Vector