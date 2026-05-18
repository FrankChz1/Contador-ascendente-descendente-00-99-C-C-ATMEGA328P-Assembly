; ==============================================================================
; EXPERIENCIA 3 - ATmega328P
; Contador ascendente / descendente 00-99
; Display 7 segmentos de 4 dígitos, cátodo común
;
; Interrupciones:
; INT0 / PD2 = Incremento por flanco de subida
; INT1 / PD3 = Decremento por flanco de subida
;
; Segmentos:
; A = PD0
; B = PD1
; C = PD4
; D = PD5
; E = PD6
; F = PD7
; G = PB4
;
; Dígitos usados:
; D3 = PC0 -> transistor NPN -> decenas
; D4 = PC1 -> transistor NPN -> unidades
; ==============================================================================

.include "m328pdef.inc"

.CSEG

; ------------------------------------------------------------------------------
; Vectores de interrupción
; ------------------------------------------------------------------------------

.ORG 0x0000
    JMP Inicio

.ORG 0x0002
    JMP ISR_INT0

.ORG 0x0004
    JMP ISR_INT1

.ORG 0x0034

; ------------------------------------------------------------------------------
; Definición de registros
; ------------------------------------------------------------------------------

.DEF TEMP      = R16
.DEF CONTADOR  = R17
.DEF UNIDADES  = R18
.DEF DECENAS   = R19
.DEF PATRON    = R20
.DEF AUX       = R21
.DEF DIGITO    = R22
.DEF AUX2      = R23

; ==============================================================================
; PROGRAMA PRINCIPAL
; ==============================================================================

Inicio:

    ; Inicializar pila
    LDI TEMP, LOW(RAMEND)
    OUT SPL, TEMP

    LDI TEMP, HIGH(RAMEND)
    OUT SPH, TEMP

    ; Contador inicia en 00
    CLR CONTADOR

    ; --------------------------------------------------------------------------
    ; Configuración de puertos
    ;
    ; PORTD:
    ; PD0 = A
    ; PD1 = B
    ; PD2 = INT0 entrada
    ; PD3 = INT1 entrada
    ; PD4 = C
    ; PD5 = D
    ; PD6 = E
    ; PD7 = F
    ; --------------------------------------------------------------------------
    LDI TEMP, 0b11110011
    OUT DDRD, TEMP

    ; PORTB:
    ; PB4 = G
    LDI TEMP, 0b00010000
    OUT DDRB, TEMP

    ; PORTC:
    ; PC0 = transistor para D3
    ; PC1 = transistor para D4
    LDI TEMP, 0b00000011
    OUT DDRC, TEMP

    ; Apagar segmentos y dígitos al inicio
    CLR TEMP
    OUT PORTD, TEMP
    OUT PORTB, TEMP
    OUT PORTC, TEMP

    ; --------------------------------------------------------------------------
    ; Configurar INT0 e INT1 por flanco de subida
    ;
    ; INT0:
    ; ISC01 = 1
    ; ISC00 = 1
    ;
    ; INT1:
    ; ISC11 = 1
    ; ISC10 = 1
    ; --------------------------------------------------------------------------
    LDI TEMP, (1<<ISC01)|(1<<ISC00)|(1<<ISC11)|(1<<ISC10)
    STS EICRA, TEMP

    ; Limpiar banderas pendientes de interrupción
    LDI TEMP, (1<<INTF0)|(1<<INTF1)
    OUT EIFR, TEMP

    ; Habilitar INT0 e INT1
    LDI TEMP, (1<<INT0)|(1<<INT1)
    OUT EIMSK, TEMP

    ; Habilitar interrupciones globales
    SEI

; ==============================================================================
; BUCLE PRINCIPAL
; Multiplexación del display
; ==============================================================================

Lazo_Principal:

    ; Convertir contador a decenas y unidades
    RCALL Calcular_BCD

    ; --------------------------------------------------------------------------
    ; Mostrar decenas en D3
    ; --------------------------------------------------------------------------
    RCALL Apagar_Digitos

    MOV DIGITO, DECENAS
    RCALL Cargar_Patron
    RCALL Enviar_Segmentos

    SBI PORTC, PC0          ; Activar D3
    RCALL Delay_Mux

    ; --------------------------------------------------------------------------
    ; Mostrar unidades en D4
    ; --------------------------------------------------------------------------
    RCALL Apagar_Digitos

    MOV DIGITO, UNIDADES
    RCALL Cargar_Patron
    RCALL Enviar_Segmentos

    SBI PORTC, PC1          ; Activar D4
    RCALL Delay_Mux

    ; Apagar ambos dígitos para evitar ghosting
    RCALL Apagar_Digitos

    RJMP Lazo_Principal

; ==============================================================================
; ISR INT0
; Incremento: 00 -> 01 -> ... -> 99 -> 00
; ==============================================================================

ISR_INT0:

    PUSH TEMP
    IN TEMP, SREG
    PUSH TEMP

    INC CONTADOR

    CPI CONTADOR, 100
    BRLO Fin_INT0

    CLR CONTADOR

Fin_INT0:

    POP TEMP
    OUT SREG, TEMP
    POP TEMP

    RETI

; ==============================================================================
; ISR INT1
; Decremento: 00 -> 99 -> 98 -> ... -> 00
; ==============================================================================

ISR_INT1:

    PUSH TEMP
    IN TEMP, SREG
    PUSH TEMP

    CPI CONTADOR, 0
    BREQ Contador_A_99

    DEC CONTADOR
    RJMP Fin_INT1

Contador_A_99:

    LDI CONTADOR, 99

Fin_INT1:

    POP TEMP
    OUT SREG, TEMP
    POP TEMP

    RETI

; ==============================================================================
; SUBRUTINA: Calcular_BCD
; Convierte CONTADOR de 0-99 en DECENAS y UNIDADES
; ==============================================================================

Calcular_BCD:

    MOV AUX2, CONTADOR
    CLR DECENAS

BCD_Loop:

    CPI AUX2, 10
    BRLO BCD_Fin

    SUBI AUX2, 10
    INC DECENAS

    RJMP BCD_Loop

BCD_Fin:

    MOV UNIDADES, AUX2

    RET

; ==============================================================================
; SUBRUTINA: Cargar_Patron
;
; Entrada:
; DIGITO = número de 0 a 9
;
; Salida:
; PATRON = patrón de segmentos
;
; Bits:
; bit0 = A
; bit1 = B
; bit2 = C
; bit3 = D
; bit4 = E
; bit5 = F
; bit6 = G
; ==============================================================================

Cargar_Patron:

    LDI ZL, LOW(Tabla_7Seg << 1)
    LDI ZH, HIGH(Tabla_7Seg << 1)

    ADD ZL, DIGITO
    CLR TEMP
    ADC ZH, TEMP

    LPM PATRON, Z

    RET

; ==============================================================================
; SUBRUTINA: Enviar_Segmentos
;
; Mapeo físico:
; A -> PD0
; B -> PD1
; C -> PD4
; D -> PD5
; E -> PD6
; F -> PD7
; G -> PB4
; ==============================================================================

Enviar_Segmentos:

    ; Construir salida para PORTD
    CLR AUX

    ; A -> PD0
    SBRC PATRON, 0
    ORI AUX, (1<<PD0)

    ; B -> PD1
    SBRC PATRON, 1
    ORI AUX, (1<<PD1)

    ; C -> PD4
    SBRC PATRON, 2
    ORI AUX, (1<<PD4)

    ; D -> PD5
    SBRC PATRON, 3
    ORI AUX, (1<<PD5)

    ; E -> PD6
    SBRC PATRON, 4
    ORI AUX, (1<<PD6)

    ; F -> PD7
    SBRC PATRON, 5
    ORI AUX, (1<<PD7)

    OUT PORTD, AUX

    ; Construir salida para PORTB
    CLR AUX

    ; G -> PB4
    SBRC PATRON, 6
    ORI AUX, (1<<PB4)

    OUT PORTB, AUX

    RET

; ==============================================================================
; SUBRUTINA: Apagar_Digitos
;
; Transistores NPN:
; PC0 = 0 apaga D3
; PC1 = 0 apaga D4
; ==============================================================================

Apagar_Digitos:

    CBI PORTC, PC0
    CBI PORTC, PC1

    RET

; ==============================================================================
; SUBRUTINA: Delay_Mux
; Retardo corto para multiplexación
; ==============================================================================

Delay_Mux:

    LDI AUX, 3

Delay_L1:

    LDI AUX2, 220

Delay_L2:

    DEC AUX2
    BRNE Delay_L2

    DEC AUX
    BRNE Delay_L1

    RET

; ==============================================================================
; TABLA 7 SEGMENTOS - CÁTODO COMÚN
;
; 1 = segmento encendido
;
; Orden:
; bit0=A, bit1=B, bit2=C, bit3=D, bit4=E, bit5=F, bit6=G
; ==============================================================================

Tabla_7Seg:

    .DB 0b00111111, 0b00000110 ; 0, 1
    .DB 0b01011011, 0b01001111 ; 2, 3
    .DB 0b01100110, 0b01101101 ; 4, 5
    .DB 0b01111101, 0b00000111 ; 6, 7
    .DB 0b01111111, 0b01101111 ; 8, 9
