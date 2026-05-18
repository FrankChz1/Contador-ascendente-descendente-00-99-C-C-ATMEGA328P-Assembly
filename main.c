#define F_CPU 1000000UL

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>
#include <avr/pgmspace.h>

/*
==============================================================================
EXPERIENCIA 3 - ATmega328P
Contador ascendente / descendente 00-99
Display 7 segmentos de 4 dígitos, cátodo común

INT0 / PD2 = Incremento por flanco de subida
INT1 / PD3 = Decremento por flanco de subida

Segmentos:
A = PD0
B = PD1
C = PD4
D = PD5
E = PD6
F = PD7
G = PB4

Dígitos usados:
D3 = PC0 -> transistor NPN -> decenas
D4 = PC1 -> transistor NPN -> unidades
==============================================================================
*/

volatile uint8_t contador = 0;

/*
Tabla para display cátodo común.
1 = segmento encendido.

bit0 = A
bit1 = B
bit2 = C
bit3 = D
bit4 = E
bit5 = F
bit6 = G
*/
const uint8_t tabla_7seg[10] PROGMEM =
{
    0b00111111, // 0
    0b00000110, // 1
    0b01011011, // 2
    0b01001111, // 3
    0b01100110, // 4
    0b01101101, // 5
    0b01111101, // 6
    0b00000111, // 7
    0b01111111, // 8
    0b01101111  // 9
};

void apagar_digitos(void)
{
    PORTC &= ~((1 << PC0) | (1 << PC1));
}

void enviar_segmentos(uint8_t patron)
{
    uint8_t salida_d = 0;
    uint8_t salida_b = 0;

    if (patron & (1 << 0)) salida_d |= (1 << PD0); // A
    if (patron & (1 << 1)) salida_d |= (1 << PD1); // B
    if (patron & (1 << 2)) salida_d |= (1 << PD4); // C
    if (patron & (1 << 3)) salida_d |= (1 << PD5); // D
    if (patron & (1 << 4)) salida_d |= (1 << PD6); // E
    if (patron & (1 << 5)) salida_d |= (1 << PD7); // F

    if (patron & (1 << 6)) salida_b |= (1 << PB4); // G

    PORTD = salida_d;
    PORTB = salida_b;
}

void mostrar_numero(uint8_t numero)
{
    uint8_t decenas;
    uint8_t unidades;
    uint8_t patron;

    decenas = numero / 10;
    unidades = numero % 10;

    // Mostrar decenas en D3
    apagar_digitos();
    patron = pgm_read_byte(&tabla_7seg[decenas]);
    enviar_segmentos(patron);
    PORTC |= (1 << PC0);      // Activar D3
    _delay_ms(2);

    // Mostrar unidades en D4
    apagar_digitos();
    patron = pgm_read_byte(&tabla_7seg[unidades]);
    enviar_segmentos(patron);
    PORTC |= (1 << PC1);      // Activar D4
    _delay_ms(2);

    apagar_digitos();
}

void inicializar_puertos(void)
{
    /*
    PORTD:
    PD0 = A
    PD1 = B
    PD2 = INT0 entrada
    PD3 = INT1 entrada
    PD4 = C
    PD5 = D
    PD6 = E
    PD7 = F
    */
    DDRD = 0b11110011;

    /*
    PORTB:
    PB4 = G
    */
    DDRB = (1 << PB4);

    /*
    PORTC:
    PC0 = transistor D3
    PC1 = transistor D4
    */
    DDRC = (1 << PC0) | (1 << PC1);

    // Estado inicial apagado
    PORTD = 0x00;
    PORTB = 0x00;
    PORTC = 0x00;
}

void inicializar_interrupciones(void)
{
    /*
    INT0 por flanco de subida:
    ISC01 = 1, ISC00 = 1

    INT1 por flanco de subida:
    ISC11 = 1, ISC10 = 1
    */
    EICRA = (1 << ISC01) | (1 << ISC00) |
            (1 << ISC11) | (1 << ISC10);

    // Limpiar banderas pendientes
    EIFR = (1 << INTF0) | (1 << INTF1);

    // Habilitar INT0 e INT1
    EIMSK = (1 << INT0) | (1 << INT1);

    // Habilitar interrupciones globales
    sei();
}

ISR(INT0_vect)
{
    contador++;

    if (contador >= 100)
    {
        contador = 0;
    }
}

ISR(INT1_vect)
{
    if (contador == 0)
    {
        contador = 99;
    }
    else
    {
        contador--;
    }
}

int main(void)
{
    inicializar_puertos();
    inicializar_interrupciones();

    while (1)
    {
        mostrar_numero(contador);
    }
}
