# Contador 00–99 con ATmega328P, Interrupciones Externas y Display de 7 Segmentos

Proyecto desarrollado para el laboratorio de **Interrupciones en el ATmega328P** del curso de **Introducción a Sistemas Embebidos**.

El sistema implementa un contador ascendente/descendente de dos dígitos, desde **00 hasta 99**, utilizando interrupciones externas **INT0** e **INT1** y un display de 7 segmentos de 4 dígitos en configuración de **cátodo común**.

---

## Descripción general

El proyecto consiste en controlar un display de 7 segmentos multiplexado mediante un microcontrolador **ATmega328P**.

Se utilizan dos pulsadores externos:

- **INT0 / PD2**: incrementa el contador.
- **INT1 / PD3**: decrementa el contador.

El valor del contador se muestra en dos dígitos del display:

- **D3**: decenas.
- **D4**: unidades.

La activación de los dígitos se realiza mediante transistores NPN, permitiendo que el microcontrolador controle la multiplexación sin conducir directamente la corriente total de los segmentos.

---

## Experiencias implementadas

### Experiencia 3

Implementación en **Assembler AVR** de un contador de eventos ascendente/descendente de dos dígitos.

Características principales:

- Lenguaje: Assembler.
- Rango del contador: 00–99.
- Interrupciones externas: INT0 e INT1.
- Uso de subrutinas.
- Uso de pila para guardar registros.
- Display de 7 segmentos multiplexado.
- No se utiliza PCINT.

### Experiencia 4

Implementación equivalente en **C/C++**.

Características principales:

- Lenguaje: C/C++.
- Rango del contador: 00–99.
- Interrupciones externas: INT0 e INT1.
- Uso de funciones.
- Variable global `contador` modificada por las ISR.
- Display de 7 segmentos multiplexado.
- No se utiliza PCINT.

---

## Componentes utilizados

| Componente | Cantidad | Descripción |
|---|---:|---|
| ATmega328P | 1 | Microcontrolador principal |
| Display 7 segmentos 4 dígitos | 1 | Tipo cátodo común |
| Resistencias de 330 Ω | 7 | Limitación de corriente para segmentos A-G |
| Resistencias de 1 kΩ | 2 | Resistencias de base para transistores |
| Resistencias de 10 kΩ | 2 | Pull-down para pulsadores |
| Transistores NPN | 2 | Control de dígitos D3 y D4 |
| Pulsadores | 2 | Incremento y decremento |
| Capacitores de 100 nF | 2 o más | Antirrebote y desacoplo |
| USBasp | 1 | Programador AVR |
| Protoboard y cables | — | Montaje del circuito |

---

## Herramientas utilizadas

- **Microchip Studio** para desarrollo, compilación y depuración.
- **USBasp** como programador del ATmega328P.
- **AVRDUDESS** o **Khazama** para grabar el archivo `.hex`.
- Multímetro para validación de conexiones.
- Protoboard para implementación física.

---

## Mapeo de pines

### Segmentos del display

| Segmento | Pin del display | Pin ATmega328P | Función |
|---|---:|---|---|
| A | 11 | PD0 | Segmento A |
| B | 7 | PD1 | Segmento B |
| C | 4 | PD4 | Segmento C |
| D | 2 | PD5 | Segmento D |
| E | 1 | PD6 | Segmento E |
| F | 10 | PD7 | Segmento F |
| G | 5 | PB4 | Segmento G |
| DP | 3 | No usado | Punto decimal |

Cada segmento se conecta mediante una resistencia de **330 Ω**.

---

### Dígitos utilizados

| Dígito | Pin del display | Función | Control |
|---|---:|---|---|
| D3 | 8 | Decenas | PC0 mediante transistor NPN |
| D4 | 6 | Unidades | PC1 mediante transistor NPN |
| D1 | 12 | No usado | No conectar |
| D2 | 9 | No usado | No conectar |

---

### Interrupciones externas

| Función | Pin ATmega328P | Interrupción |
|---|---|---|
| Incrementar contador | PD2 | INT0 |
| Decrementar contador | PD3 | INT1 |

Los pulsadores se conectan con resistencias **pull-down** externas de 10 kΩ.  
Al presionar el pulsador, el pin recibe **5 V**, por lo que las interrupciones se configuran por **flanco de subida**.

---

## Conexión de transistores

El display utilizado es de **cátodo común**, por lo que cada dígito se activa conectando su común a GND.

Para evitar que el ATmega328P conduzca directamente la corriente de los segmentos, se utilizan transistores NPN.

### D3: decenas

```text
D3 / pin 8 del display → Colector del transistor Q1
Emisor Q1              → GND real
Base Q1                → resistencia 1 kΩ → PC0
