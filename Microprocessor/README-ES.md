# OAI MIZUSHIMA YR-02
## Modular Flight Control System

| Propiedad | Valor |
|---|---|
| Proyecto | OAI MIZUSHIMA YR-02 |
| Sistema | Modular Flight Control System |
| Versión del sistema | 14.0 |
| Migración de origen | V13.1.0 |
| Plataforma | Stormworks: Build and Rescue |
| Arquitectura | Modular Microcontroller Flight Control System |
| Lenguaje | Lua |
| Microcontroladores | MC01–MC07 |

---

# 1. Descripción general

El **OAI MIZUSHIMA YR-02** es un sistema modular de control de vuelo desarrollado para Stormworks.

La arquitectura divide las funciones de control en siete microcontroladores independientes. Cada módulo tiene una responsabilidad específica y se comunica con los demás mediante conexiones Composite.

El objetivo de esta arquitectura es mantener las funciones de vuelo separadas, facilitar el mantenimiento y permitir que cada módulo pueda modificarse y comprobarse individualmente.

## 1.1. Arquitectura de módulos

| MC | Módulo | Responsabilidad |
|---|---|---|
| MC01 | FLIGHT SEQUENCE | Gestión de misión y secuencia de vuelo |
| MC02 | MASTER CONTROL | Distribución de órdenes generales |
| MC03 | FLIGHT CONTROL | Estabilización de roll |
| MC04 | ALTITUDE CONTROL | Control de altitud mediante PID |
| MC05 | NAVIGATION | Navegación y cálculo de rumbo |
| MC06 | PROPULSION | Gestión de propulsores y spoiler |
| MC07 | TELEMETRY | Supervisión y transmisión HTTP |

MC07 es opcional. Su ausencia no debe impedir el funcionamiento de los controles principales de vuelo.

## 1.2. Principios de arquitectura

- Los sensores se conectan directamente a los módulos que necesitan sus mediciones.
- Las órdenes generales de vuelo se distribuyen mediante MC02.
- Las señales específicas pueden conectarse directamente entre los módulos que las generan y los que las necesitan.
- Las salidas destinadas a actuadores se documentan por separado de las señales de comunicación.
- MC07 recibe información de otros módulos y sensores para generar telemetría.
- Las conexiones Composite deben respetar el tipo y número de canal de cada señal.

---

# 2. Convenciones de señales y conexiones

Esta sección establece cómo interpretar las tablas de conexionado.

## 2.1. Tipos de canal

Stormworks dispone de dos familias independientes de canales Composite:

| Tipo | Identificación | Información transportada |
|---|---|---|
| Boolean | Bool | Estados binarios: activado/desactivado, verdadero/falso |
| Number | Num | Valores numéricos: medidas, parámetros, cálculos y órdenes analógicas |

Los canales Boolean y Number son independientes. Por ejemplo, `Bool 3` y `Num 3` no son el mismo canal.

Cada microcontrolador dispone de hasta 32 entradas y 32 salidas de cada tipo.

## 2.2. Naturaleza de las señales

El tipo de canal no indica por sí mismo qué representa la señal. Para identificar su función se utilizan estas categorías:

| Naturaleza | Descripción | Ejemplos |
|---|---|---|
| Sensor físico | Valor procedente de un sensor instalado en el vehículo | ALTITUDE, REAL_RPS, AP_COMPASS |
| Parámetro de configuración | Valor ajustable que modifica el comportamiento de un controlador | ALT_PID_P, ALT_PID_I, ALT_PID_D, ROLL_CONTROL_MULTIPLIER |
| Orden de control | Instrucción enviada para habilitar o activar una función | ALTITUDE_HOLD, AUTOPILOT |
| Estado | Información sobre el estado de una secuencia o sistema | RUNNING, COMPLETED |
| Cálculo de control | Resultado producido por un algoritmo de control | DESIRED_VERTICAL_SPEED |
| Dato de navegación | Información de posición, distancia o rumbo | AP_DISTANCE, AP_TARGET_HEADING |
| Salida de actuador | Orden destinada a controlar un actuador | ELEVATOR_LEFT, MAIN_BOOSTER |
| Telemetría | Información recopilada para supervisión | SEQUENCE_TIMER, AP_YAW |

## 2.3. Interpretación de las tablas

Todas las conexiones se documentan con esta estructura:

| Columna | Significado |
|---|---|
| Origen | Sensor, configuración o microcontrolador que genera la señal |
| Salida | Canal por el que se transmite la señal |
| Destino | Microcontrolador o dispositivo que recibe la señal |
| Entrada | Canal en el que debe recibirse la señal |
| Señal | Nombre identificativo de la información |
| Dato | Boolean o Number |
| Naturaleza | Función que desempeña la señal |
| Descripción | Explicación de qué representa y para qué se utiliza |

**Regla fundamental:** el tipo y número de la salida del origen deben coincidir con el tipo y número de la entrada del destino.

Ejemplo:

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza |
|---|---|---|---|---|---|---|
| MC04 | Num 5 | MC07 | Num 6 | DESIRED_VERTICAL_SPEED | Number | Cálculo de control |

Esto significa que la salida Number 5 de MC04 debe llegar a la entrada Number 6 de MC07.

---

# 3. Procedimiento general de conexionado

El montaje debe realizarse siguiendo las tablas de conexiones, no únicamente los nombres de las señales.

## 3.1. Conexión entre microcontroladores

Para conectar dos microcontroladores:

1. Identificar el microcontrolador que genera la señal.
2. Localizar su canal de salida en la tabla correspondiente.
3. Identificar el microcontrolador que necesita esa señal.
4. Localizar el canal de entrada correspondiente.
5. Conectar el Composite del origen con el Composite del destino.
6. Comprobar que ambos módulos utilizan el mismo tipo y número de canal.
7. Verificar el valor recibido durante una prueba.

Una señal no debe conectarse a un canal diferente simplemente porque tenga el mismo nombre en otro módulo.

## 3.2. Distribución de señales

Una misma señal puede alimentar varios módulos cuando todos necesitan el mismo dato.

Por ejemplo, una medición física de altitud puede alimentar MC01, MC04 y MC07.

La distribución debe mantener el tipo y el número de canal que espera cada receptor. Si los módulos utilizan canales diferentes, se deberá realizar la asignación correspondiente en el sistema de distribución Composite.

## 3.3. Sensores físicos

Los sensores físicos se conectan a las entradas del microcontrolador que los utiliza.

No es necesario que todos los sensores pasen por MC02.

Ejemplos:

- El sensor de altitud alimenta los módulos que necesitan conocer la altitud.
- El sensor de velocidad vertical alimenta los módulos que necesitan conocer la velocidad vertical.
- El sensor de brújula alimenta MC05.
- Los sensores de inclinación alimentan los módulos que necesitan realizar cálculos de estabilización o detección de orientación.

## 3.4. Parámetros de configuración

Los parámetros de configuración son valores que deben proporcionarse al microcontrolador mediante las entradas Number correspondientes.

Ejemplos:

- ALT_PID_P
- ALT_PID_I
- ALT_PID_D
- ROLL_CONTROL_MULTIPLIER
- ALTITUDE_TARGET
- TARGET_RPS
- AP_STEERING
- AP_CUTOFF
- AP_DEADZONE
- AP_SMOOTHING
- etc...

No deben confundirse con sensores físicos: representan valores de configuración, no mediciones del vehículo.

## 3.5. Salidas de actuadores

Las salidas de los microcontroladores deben conectarse a los actuadores correspondientes respetando el tipo de señal.

- Las órdenes Boolean controlan estados de activación.
- Las órdenes Number transmiten valores de control.

La asignación de cada salida a su actuador físico debe comprobarse en el esquema de montaje del vehículo.

---

# 4. Tabla maestra de conexiones entre microcontroladores

Esta es la referencia principal para realizar las conexiones Composite entre módulos.

## 4.1. MC01 → MC02 — Distribución de secuencia

MC01 genera las órdenes generales y los valores de estado de la secuencia. MC02 los recibe y los distribuye a otros controladores.

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC01 | Bool 1 | MC02 | Bool 1 | RUNNING | Boolean | Estado | Indica que la secuencia está en ejecución |
| MC01 | Bool 2 | MC02 | Bool 2 | COMPLETED | Boolean | Estado | Indica que la secuencia ha finalizado |
| MC01 | Bool 3 | MC02 | Bool 3 | ROLL_STABILIZER | Boolean | Orden de control | Habilita la estabilización de roll |
| MC01 | Bool 4 | MC02 | Bool 4 | MAIN_BOOSTER | Boolean | Orden de control | Solicita la activación del propulsor principal |
| MC01 | Bool 5 | MC02 | Bool 5 | DIRECTIONAL_BOOSTER_TRIGGER | Boolean | Orden de control | Solicita un pulso de propulsor direccional |
| MC01 | Bool 6 | MC02 | Bool 6 | BOTTOM_BOOSTERS | Boolean | Orden de control | Habilita la lógica de propulsores inferiores |
| MC01 | Bool 7 | MC02 | Bool 7 | ACCELERATION_BOOSTERS | Boolean | Orden de control | Solicita la activación de propulsores de aceleración |
| MC01 | Bool 8 | MC02 | Bool 8 | ALTITUDE_HOLD | Boolean | Orden de control | Habilita el mantenimiento de altitud |
| MC01 | Bool 9 | MC02 | Bool 9 | AUTOPILOT | Boolean | Orden de control | Habilita el piloto automático |
| MC01 | Bool 10 | MC02 | Bool 10 | START_STATUS | Boolean | Estado | Estado relacionado con el inicio de la secuencia |
| MC01 | Num 1 | MC02 | Num 1 | SEQUENCE_STATE | Number | Estado | Identificador de la fase de vuelo |
| MC01 | Num 2 | MC02 | Num 2 | SEQUENCE_TIMER | Number | Estado | Temporizador de la secuencia |
| MC01 | Num 3 | MC02 | Num 3 | SPOILER | Number | Orden de control | Valor de control del spoiler |
| MC01 | Num 4 | MC02 | Num 4 | ALTITUDE_STABLE_TIMER | Number | Estado | Temporizador de estabilidad de altitud |
| MC01 | Num 5 | MC02 | Num 5 | ROLL_STABLE_TIMER | Number | Estado | Temporizador de estabilidad de roll |

## 4.2. MC02 → MC03 — Flight Control

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 3 | MC03 | Bool 3 | ROLL_STABILIZER | Boolean | Orden de control | Habilita la estabilización de roll |

MC03 también necesita recibir su multiplicador y el sensor de inclinación horizontal directamente.

## 4.3. MC02 → MC04 — Altitude Control

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 8 | MC04 | Bool 8 | ALTITUDE_HOLD | Boolean | Orden de control | Habilita el control automático de altitud |

## 4.4. MC02 → MC05 — Navigation

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 9 | MC05 | Bool 9 | AUTOPILOT | Boolean | Orden de control | Habilita el piloto automático |

## 4.5. MC02 → MC06 — Propulsion

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 4 | MC06 | Bool 1 | MAIN_BOOSTER | Boolean | Orden de control | Control del propulsor principal |
| MC02 | Bool 5 | MC06 | Bool 2 | DIRECTIONAL_BOOSTER_TRIGGER | Boolean | Orden de control | Dispara la selección de propulsor direccional |
| MC02 | Bool 6 | MC06 | Bool 3 | BOTTOM_BOOSTERS | Boolean | Orden de control | Habilita los propulsores inferiores |
| MC02 | Bool 7 | MC06 | Bool 4 | ACCELERATION_BOOSTERS | Boolean | Orden de control | Control de propulsores de aceleración |
| MC02 | Num 3 | MC06 | Num 1 | SPOILER | Number | Orden de control | Transmite el valor del spoiler |

## 4.6. MC05 → MC06 — Navigation to Propulsion

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC05 | Num 12 | MC06 | Num 2 | AP_TARGET_HEADING | Number | Dato de navegación | Transmite el rumbo normalizado hacia el objetivo |

**Importante:** AP_TARGET_HEADING utiliza MC05 Number 12. No debe conectarse desde Number 7.

## 4.7. MC04 → MC07 — Telemetry

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC04 | Num 5 | MC07 | Num 6 | DESIRED_VERTICAL_SPEED | Number | Cálculo de control | Velocidad vertical deseada calculada por MC04 |

## 4.8. MC05 → MC07 — Telemetry

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC05 | Num 7 | MC07 | Num 11 | AP_DISTANCE | Number | Dato de navegación | Distancia actual hasta el objetivo |
| MC05 | Num 6 | MC07 | Num 12 | AP_YAW | Number | Dato de navegación | Corrección de yaw calculada por el autopiloto |
| MC05 | Num 8 | MC07 | Num 13 | AP_MY_X | Number | Dato de navegación | Coordenada X actual |
| MC05 | Num 9 | MC07 | Num 14 | AP_MY_Y | Number | Dato de navegación | Coordenada Y actual |
| MC05 | Num 10 | MC07 | Num 15 | AP_TARGET_X | Number | Dato de navegación | Coordenada X del objetivo |
| MC05 | Num 11 | MC07 | Num 16 | AP_TARGET_Y | Number | Dato de navegación | Coordenada Y del objetivo |

## 4.9. MC02 → MC07 — Telemetry

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC02 | Num 1 | MC07 | Num 1 | SEQUENCE_STATE | Number | Estado | Fase actual de la secuencia |
| MC02 | Num 2 | MC07 | Num 2 | SEQUENCE_TIMER | Number | Estado | Tiempo transcurrido de la secuencia |
| MC02 | Num 3 | MC07 | Num 17 | SPOILER | Number | Orden de control | Valor del spoiler |
| MC02 | Bool 1 | MC07 | Bool 1 | RUNNING | Boolean | Estado | Secuencia en ejecución |
| MC02 | Bool 2 | MC07 | Bool 2 | COMPLETED | Boolean | Estado | Secuencia completada |
| MC02 | Bool 3 | MC07 | Bool 6 | ROLL_STABILIZER | Boolean | Estado | Estabilización de roll habilitada |
| MC02 | Bool 4 | MC07 | Bool 4 | MAIN_BOOSTER | Boolean | Estado | Propulsor principal solicitado |
| MC02 | Bool 7 | MC07 | Bool 7 | ACCELERATION_BOOSTERS | Boolean | Estado | Propulsores de aceleración solicitados |
| MC02 | Bool 8 | MC07 | Bool 5 | ALTITUDE_HOLD | Boolean | Estado | Mantenimiento de altitud habilitado |
| MC02 | Bool 9 | MC07 | Bool 3 | AUTOPILOT | Boolean | Estado | Piloto automático habilitado |

## 4.10. MC06 → MC07 — Telemetry

| Origen | Salida | Destino | Entrada | Señal | Dato | Naturaleza | Descripción |
|---|---|---|---|---|---|---|---|
| MC06 | Bool 5 | MC07 | Bool 8 | NORTH_BOOSTER | Boolean | Estado de actuador | Estado del propulsor norte |
| MC06 | Bool 6 | MC07 | Bool 9 | EAST_BOOSTER | Boolean | Estado de actuador | Estado del propulsor este |
| MC06 | Bool 7 | MC07 | Bool 10 | SOUTH_BOOSTER | Boolean | Estado de actuador | Estado del propulsor sur |
| MC06 | Bool 8 | MC07 | Bool 11 | WEST_BOOSTER | Boolean | Estado de actuador | Estado del propulsor oeste |

---

# 5. Tabla maestra de sensores y parámetros de entrada

Esta tabla identifica las señales que deben suministrarse desde sensores físicos o desde valores de configuración.

Los canales indicados corresponden a las entradas documentadas de cada controlador. Cuando un mismo sensor se utiliza en varios módulos, debe distribuirse su señal a todos los destinos que la necesitan.

| Señal | Naturaleza | Dato | MC01 | MC03 | MC04 | MC05 | MC06 | MC07 |
|---|---|---|---|---|---|---|---|---|
| TILT_ROLL_HORIZ | Sensor físico | Number | Num 2 | Num 2 | — | — | Num 3 | Num 9 |
| TILT_PITCH | Sensor físico | Number | Num 3 | — | — | — | — | Num 10 |
| TARGET_RPS | Parámetro de configuración | Number | Num 4 | — | — | — | — | Num 8 |
| REAL_RPS | Sensor físico | Number | Num 5 | — | — | — | — | Num 7 |
| ALTITUDE | Sensor físico | Number | Num 6 | — | Num 1 | — | — | Num 3 |
| ALTITUDE_TARGET | Parámetro de configuración | Number | Num 7 | — | Num 2 | — | — | Num 4 |
| VERTICAL_SPEED | Sensor físico | Number | Num 12 | — | Num 6 | — | — | Num 5 |
| AP_TARGET_X | Entrada de navegación | Number | Num 13 | — | — | Num 1 | — | — |
| AP_TARGET_Y | Entrada de navegación | Number | Num 14 | — | — | Num 2 | — | — |
| AP_SENSOR_X | Sensor de posición | Number | Num 15 | — | — | Num 3 | — | — |
| AP_SENSOR_Y | Sensor de posición | Number | Num 16 | — | — | Num 4 | — | — |
| AP_COMPASS | Sensor físico | Number | — | — | — | Num 5 | — | — |
| AP_STEERING | Parámetro de configuración | Number | — | — | — | Num 6 | — | — |
| AP_CUTOFF | Parámetro de configuración | Number | Num 19 | — | — | Num 7 | — | — |
| AP_DEADZONE | Parámetro de configuración | Number | — | — | — | Num 8 | — | — |
| AP_SMOOTHING | Parámetro de configuración | Number | — | — | — | Num 9 | — | — |
| VERTICAL_SPEED_TARGET | Parámetro de configuración | Number | Num 22 | — | — | — | — | — |
| ROLL_CONTROL_MULTIPLIER | Parámetro de configuración | Number | — | Num 1 | — | — | — | — |
| TILT_ROLL_VERT | Sensor físico | Number | — | — | — | — | Num 4 | — |
| ALT_PID_P | Parámetro de configuración | Number | — | — | Num 3 | — | — | — |
| ALT_PID_I | Parámetro de configuración | Number | — | — | Num 4 | — | — | — |
| ALT_PID_D | Parámetro de configuración | Number | — | — | Num 5 | — | — | — |
| ALT_HOLD_DELAY | Parámetro de configuración | Number | Num 11 | — | — | — | — | — |

**Nota sobre esta tabla:** los guiones indican que la señal no aparece como entrada de ese módulo en la distribución documentada. No significan que el sensor no pueda utilizarse en otras funciones futuras.

## 5.1. Señales de entrada Boolean

| Señal | Naturaleza | Origen | Destino | Entrada |
|---|---|---|---|---|
| START | Orden de control | Interruptor de inicio | MC01 | Bool 1 |
| ROLL_STABILIZER | Orden de control | MC02 | MC03 | Bool 3 |
| ALTITUDE_HOLD | Orden de control | MC02 | MC04 | Bool 8 |
| AUTOPILOT | Orden de control | MC02 | MC05 | Bool 9 |
| MAIN_BOOSTER | Orden de control | MC02 | MC06 | Bool 1 |
| DIRECTIONAL_BOOSTER_TRIGGER | Orden de control | MC02 | MC06 | Bool 2 |
| BOTTOM_BOOSTERS | Orden de control | MC02 | MC06 | Bool 3 |
| ACCELERATION_BOOSTERS | Orden de control | MC02 | MC06 | Bool 4 |

---

# 6. MC01 — FLIGHT SEQUENCE

**Responsabilidad:** gestión de misión y secuencia de vuelo.

MC01 administra las fases de vuelo y determina cuándo deben activarse las distintas funciones de control.

## 6.1. Entradas

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Bool 1 | START | Boolean | Orden de control | Interruptor de inicio |
| Num 2 | TILT_ROLL_HORIZ | Number | Sensor físico | Sensor de inclinación |
| Num 3 | TILT_PITCH | Number | Sensor físico | Sensor de inclinación |
| Num 4 | TARGET_RPS | Number | Parámetro | Configuración |
| Num 5 | REAL_RPS | Number | Sensor físico | Sensor RPS |
| Num 6 | ALTITUDE | Number | Sensor físico | Sensor de altitud |
| Num 7 | ALTITUDE_TARGET | Number | Parámetro | Configuración |
| Num 12 | VERTICAL_SPEED | Number | Sensor físico | Sensor de velocidad vertical |
| Num 13 | AP_TARGET_X | Number | Entrada de navegación | Configuración de objetivo |
| Num 14 | AP_TARGET_Y | Number | Entrada de navegación | Configuración de objetivo |
| Num 15 | AP_SENSOR_X | Number | Sensor físico | Sensor de posición |
| Num 16 | AP_SENSOR_Y | Number | Sensor físico | Sensor de posición |
| Num 19 | AP_CUTOFF | Number | Parámetro | Configuración |
| Num 22 | VERTICAL_SPEED_TARGET | Number | Parámetro | Configuración |
| Num 11 | ALT_HOLD_DELAY | Number | Parámetro | Configuración |

## 6.2. Salidas Boolean

| Canal | Señal | Destino | Naturaleza | Función |
|---|---|---|---|---|
| Bool 1 | RUNNING | MC02 Bool 1 | Estado | Secuencia en ejecución |
| Bool 2 | COMPLETED | MC02 Bool 2 | Estado | Secuencia completada |
| Bool 3 | ROLL_STABILIZER | MC02 Bool 3 | Orden de control | Activación de estabilización |
| Bool 4 | MAIN_BOOSTER | MC02 Bool 4 | Orden de control | Activación del propulsor principal |
| Bool 5 | DIRECTIONAL_BOOSTER_TRIGGER | MC02 Bool 5 | Orden de control | Solicitud de propulsor direccional |
| Bool 6 | BOTTOM_BOOSTERS | MC02 Bool 6 | Orden de control | Habilitación de propulsores inferiores |
| Bool 7 | ACCELERATION_BOOSTERS | MC02 Bool 7 | Orden de control | Activación de propulsores de aceleración |
| Bool 8 | ALTITUDE_HOLD | MC02 Bool 8 | Orden de control | Activación de mantenimiento de altitud |
| Bool 9 | AUTOPILOT | MC02 Bool 9 | Orden de control | Activación del piloto automático |
| Bool 10 | START_STATUS | MC02 Bool 10 | Estado | Estado de inicio |

## 6.3. Salidas Number

| Canal | Señal | Destino | Naturaleza | Función |
|---|---|---|---|---|
| Num 1 | SEQUENCE_STATE | MC02 Num 1 | Estado | Fase actual de vuelo |
| Num 2 | SEQUENCE_TIMER | MC02 Num 2 | Estado | Temporizador de secuencia |
| Num 3 | SPOILER | MC02 Num 3 | Orden de control | Valor del spoiler |
| Num 4 | ALTITUDE_STABLE_TIMER | MC02 Num 4 | Estado | Temporizador de estabilidad de altitud |
| Num 5 | ROLL_STABLE_TIMER | MC02 Num 5 | Estado | Temporizador de estabilidad de roll |

---

# 7. MC02 — MASTER CONTROL

**Responsabilidad:** distribución de órdenes generales.

MC02 recibe las señales de MC01 y las retransmite a sus salidas correspondientes.

No realiza los cálculos de estabilización, navegación o control de altitud.

## 7.1. Entradas

| Canal | Señal | Dato | Origen |
|---|---|---|---|
| Bool 1 | RUNNING | Boolean | MC01 Bool 1 |
| Bool 2 | COMPLETED | Boolean | MC01 Bool 2 |
| Bool 3 | ROLL_STABILIZER | Boolean | MC01 Bool 3 |
| Bool 4 | MAIN_BOOSTER | Boolean | MC01 Bool 4 |
| Bool 5 | DIRECTIONAL_BOOSTER_TRIGGER | Boolean | MC01 Bool 5 |
| Bool 6 | BOTTOM_BOOSTERS | Boolean | MC01 Bool 6 |
| Bool 7 | ACCELERATION_BOOSTERS | Boolean | MC01 Bool 7 |
| Bool 8 | ALTITUDE_HOLD | Boolean | MC01 Bool 8 |
| Bool 9 | AUTOPILOT | Boolean | MC01 Bool 9 |
| Bool 10 | START_STATUS | Boolean | MC01 Bool 10 |
| Num 1 | SEQUENCE_STATE | Number | MC01 Num 1 |
| Num 2 | SEQUENCE_TIMER | Number | MC01 Num 2 |
| Num 3 | SPOILER | Number | MC01 Num 3 |
| Num 4 | ALTITUDE_STABLE_TIMER | Number | MC01 Num 4 |
| Num 5 | ROLL_STABLE_TIMER | Number | MC01 Num 5 |

## 7.2. Salidas

MC02 utiliza una distribución directa: conserva el tipo, número y valor de cada canal de entrada.

| Canal de salida | Señal | Destino principal |
|---|---|---|
| Bool 1 | RUNNING | MC07 Bool 1 |
| Bool 2 | COMPLETED | MC07 Bool 2 |
| Bool 3 | ROLL_STABILIZER | MC03 Bool 3 / MC07 Bool 6 |
| Bool 4 | MAIN_BOOSTER | MC06 Bool 1 / MC07 Bool 4 |
| Bool 5 | DIRECTIONAL_BOOSTER_TRIGGER | MC06 Bool 2 |
| Bool 6 | BOTTOM_BOOSTERS | MC06 Bool 3 |
| Bool 7 | ACCELERATION_BOOSTERS | MC06 Bool 4 / MC07 Bool 7 |
| Bool 8 | ALTITUDE_HOLD | MC04 Bool 8 / MC07 Bool 5 |
| Bool 9 | AUTOPILOT | MC05 Bool 9 / MC07 Bool 3 |
| Bool 10 | START_STATUS | Disponible para supervisión |
| Num 1 | SEQUENCE_STATE | MC07 Num 1 |
| Num 2 | SEQUENCE_TIMER | MC07 Num 2 |
| Num 3 | SPOILER | MC06 Num 1 / MC07 Num 17 |
| Num 4 | ALTITUDE_STABLE_TIMER | Disponible para supervisión |
| Num 5 | ROLL_STABLE_TIMER | Disponible para supervisión |

---

# 8. MC03 — FLIGHT CONTROL

**Responsabilidad:** estabilización de roll.

MC03 calcula las órdenes de corrección de roll a partir de la inclinación horizontal y del multiplicador configurado.

## 8.1. Entradas

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Num 1 | ROLL_CONTROL_MULTIPLIER | Number | Parámetro | Configuración |
| Num 2 | TILT_ROLL_HORIZ | Number | Sensor físico | Sensor de inclinación |
| Bool 3 | ROLL_STABILIZER | Boolean | Orden de control | MC02 Bool 3 |

## 8.2. Salidas

| Canal | Señal | Dato | Naturaleza | Destino |
|---|---|---|---|---|
| Num 1 | ROLL_RIGHT | Number | Salida de actuador | Control de roll correspondiente |
| Num 2 | ROLL_LEFT | Number | Salida de actuador | Control de roll correspondiente |

Las salidas deben conectarse a los actuadores de roll correspondientes según el montaje del vehículo.

## 8.3. Funcionamiento

Cuando `ROLL_STABILIZER` está desactivado, ambas salidas se establecen en cero.

Cuando está habilitado, el controlador calcula la corrección utilizando el valor de inclinación y el multiplicador.

El controlador genera órdenes opuestas para ambos lados.

---

# 9. MC04 — ALTITUDE CONTROL

**Responsabilidad:** regulación de altitud mediante PID.

MC04 calcula la velocidad vertical deseada y utiliza el control PID para generar las órdenes de los elevadores.

## 9.1. Entradas

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Num 1 | ALTITUDE | Number | Sensor físico | Sensor de altitud |
| Num 2 | ALTITUDE_TARGET | Number | Parámetro | Configuración de altitud objetivo |
| Num 3 | ALT_PID_P | Number | Parámetro | Configuración PID |
| Num 4 | ALT_PID_I | Number | Parámetro | Configuración PID |
| Num 5 | ALT_PID_D | Number | Parámetro | Configuración PID |
| Num 6 | VERTICAL_SPEED | Number | Sensor físico | Sensor de velocidad vertical |
| Bool 8 | ALTITUDE_HOLD | Boolean | Orden de control | MC02 Bool 8 |

## 9.2. Salidas

| Canal | Señal | Dato | Naturaleza | Destino |
|---|---|---|---|---|
| Num 3 | ELEVATOR_RIGHT | Number | Salida de actuador | Elevador derecho |
| Num 4 | ELEVATOR_LEFT | Number | Salida de actuador | Elevador izquierdo |
| Num 5 | DESIRED_VERTICAL_SPEED | Number | Cálculo de control | MC07 Num 6 |

**Importante:** `DESIRED_VERTICAL_SPEED` se transmite por Number 5. MC07 debe recibirla por Number 6.

Los dos elevadores reciben el mismo valor calculado por MC04. No deben interpretarse como dos órdenes independientes.

## 9.3. Funcionamiento

MC04 realiza las siguientes operaciones:

1. Lee la altitud actual.
2. Compara la altitud actual con la altitud objetivo.
3. Calcula la velocidad vertical deseada.
4. Limita la velocidad vertical deseada a los límites definidos por el controlador.
5. Ejecuta el cálculo PID.
6. Aplica las protecciones del integrador.
7. Limita y suaviza la salida de control.
8. Publica la velocidad vertical deseada en Number 5.

Cuando el mantenimiento de altitud está deshabilitado, el controlador realiza los reinicios de estado previstos por su implementación.

---

# 10. MC05 — NAVIGATION

**Responsabilidad:** navegación, distancia al objetivo y cálculo de rumbo.

MC05 calcula la posición relativa respecto al objetivo y genera los datos de navegación utilizados por otros módulos.

## 10.1. Entradas

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Num 1 | AP_TARGET_X | Number | Entrada de navegación | Configuración de coordenada X objetivo |
| Num 2 | AP_TARGET_Y | Number | Entrada de navegación | Configuración de coordenada Y objetivo |
| Num 3 | AP_SENSOR_X | Number | Sensor físico | Sensor de posición X |
| Num 4 | AP_SENSOR_Y | Number | Sensor físico | Sensor de posición Y |
| Num 5 | AP_COMPASS | Number | Sensor físico | Brújula |
| Num 6 | AP_STEERING | Number | Parámetro | Configuración de dirección |
| Num 7 | AP_CUTOFF | Number | Parámetro | Configuración de distancia de corte |
| Num 8 | AP_DEADZONE | Number | Parámetro | Configuración de zona muerta |
| Num 9 | AP_SMOOTHING | Number | Parámetro | Configuración de suavizado |
| Bool 9 | AUTOPILOT | Boolean | Orden de control | MC02 Bool 9 |

## 10.2. Salidas

| Canal | Señal | Dato | Naturaleza | Destino |
|---|---|---|---|---|
| Num 6 | AP_YAW | Number | Dato de navegación | Timón de dirección / MC07 Num 12 |
| Num 7 | AP_DISTANCE | Number | Dato de navegación | MC07 Num 11 |
| Num 8 | AP_MY_X | Number | Dato de navegación | MC07 Num 13 |
| Num 9 | AP_MY_Y | Number | Dato de navegación | MC07 Num 14 |
| Num 10 | AP_TARGET_X | Number | Dato de navegación | MC07 Num 15 |
| Num 11 | AP_TARGET_Y | Number | Dato de navegación | MC07 Num 16 |
| Num 12 | AP_TARGET_HEADING | Number | Dato de navegación | MC06 Num 2 |

**Importante:**

- `AP_DISTANCE` está en Number 7.
- `AP_TARGET_HEADING` está en Number 12.
- No se debe utilizar Number 7 para transmitir `AP_TARGET_HEADING`.

## 10.3. Funcionamiento

MC05 realiza los cálculos necesarios para:

- Obtener la diferencia entre la posición actual y la posición objetivo.
- Calcular la distancia al objetivo.
- Calcular el ángulo y el rumbo objetivo.
- Normalizar el rumbo.
- Calcular el error de yaw.
- Aplicar los parámetros de dirección.
- Aplicar la zona muerta.
- Aplicar el límite de distancia.
- Aplicar el suavizado de la orden.

El cálculo de `AP_TARGET_HEADING` está disponible independientemente de que el piloto automático esté habilitado. La salida `AP_YAW` se establece en cero cuando el piloto automático está deshabilitado.

---

# 11. MC06 — PROPULSION

**Responsabilidad:** gestión de propulsores y spoiler.

MC06 recibe órdenes de la secuencia de vuelo y datos de navegación para gestionar los propulsores.

También utiliza sus propios sensores de inclinación para seleccionar los propulsores inferiores.

## 11.1. Entradas Number

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Num 1 | SPOILER | Number | Orden de control | MC02 Num 3 |
| Num 2 | TARGET_HEADING | Number | Dato de navegación | MC05 Num 12 |
| Num 3 | TILT_ROLL_HORIZ | Number | Sensor físico | Sensor de inclinación horizontal |
| Num 4 | TILT_ROLL_VERT | Number | Sensor físico | Sensor de inclinación vertical |

## 11.2. Entradas Boolean

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Bool 1 | MAIN_BOOSTER | Boolean | Orden de control | MC02 Bool 4 |
| Bool 2 | DIRECTIONAL_BOOSTER_TRIGGER | Boolean | Orden de control | MC02 Bool 5 |
| Bool 3 | BOTTOM_BOOSTERS | Boolean | Orden de control | MC02 Bool 6 |
| Bool 4 | ACCELERATION_BOOSTERS | Boolean | Orden de control | MC02 Bool 7 |

## 11.3. Salidas Number

| Canal | Señal | Dato | Naturaleza | Destino |
|---|---|---|---|---|
| Num 5 | SPOILER | Number | Salida de actuador | Sistema de spoiler |

## 11.4. Salidas Boolean

| Canal | Señal | Dato | Naturaleza | Función |
|---|---|---|---|---|
| Bool 1 | MAIN_BOOSTER | Boolean | Salida de actuador | Activación del propulsor principal |
| Bool 5 | NORTH_BOOSTER | Boolean | Salida de actuador | Activación del propulsor norte |
| Bool 6 | EAST_BOOSTER | Boolean | Salida de actuador | Activación del propulsor este |
| Bool 7 | SOUTH_BOOSTER | Boolean | Salida de actuador | Activación del propulsor sur |
| Bool 8 | WEST_BOOSTER | Boolean | Salida de actuador | Activación del propulsor oeste |
| Bool 9 | ACCELERATION_BOOSTER | Boolean | Salida de actuador | Activación del propulsor de aceleración |

## 11.5. Selección de propulsores direccionales

MC06 utiliza `TARGET_HEADING`, recibido desde MC05, para seleccionar el propulsor direccional correspondiente.

Los sectores de selección son:

| Dirección | Sector de rumbo normalizado |
|---|---|
| Norte | -0.125 ≤ rumbo < +0.125 |
| Este | +0.125 ≤ rumbo < +0.375 |
| Sur | +0.375 ≤ rumbo ≤ +0.5 y -0.5 ≤ rumbo < -0.375 |
| Oeste | -0.375 ≤ rumbo < -0.125 |

La solicitud de activación se recibe mediante `DIRECTIONAL_BOOSTER_TRIGGER`.

El controlador genera un pulso de activación de 0,2 segundos, según la lógica implementada.

## 11.6. Detección de propulsores inferiores

MC06 utiliza sus propios sensores de inclinación para determinar la orientación del vehículo.

La lógica contempla:

- Cálculo de magnitud de inclinación.
- Cálculo del ángulo de roll.
- Normalización del ángulo opuesto.
- Identificación de las cuatro zonas direccionales.
- Aplicación de los límites angulares definidos.

Las órdenes de los propulsores inferiores se combinan con las órdenes de los propulsores direccionales en las mismas cuatro salidas Boolean:

- NORTH_BOOSTER
- EAST_BOOSTER
- SOUTH_BOOSTER
- WEST_BOOSTER

Por tanto, las cuatro salidas representan el resultado combinado de ambas lógicas, no dos grupos de salidas independientes.

## 11.7. Reinicio de secuencia

La lógica original de vuelo contempla el reinicio de estados relacionados con la activación de propulsores direccionales al iniciar una nueva secuencia.

El mecanismo de reinicio entre MC01 y MC06 debe verificarse en la integración final. No debe considerarse validado hasta comprobar que los estados internos y los pulsos se reinician correctamente en vuelos repetidos.

---

# 12. MC07 — TELEMETRY

**Responsabilidad:** supervisión de vuelo y transmisión HTTP.

MC07 recibe datos de los demás módulos y de sensores físicos. Organiza esta información para generar telemetría.

No gobierna directamente los actuadores de vuelo.

## 12.1. Configuración

| Parámetro | Valor |
|---|---|
| ENABLED | true |
| PORT | 8080 |
| INTERVAL | 6 ticks |
| Frecuencia nominal | 10 transmisiones por segundo a 60 Hz |

## 12.2. Entradas Number

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Num 1 | SEQUENCE_STATE | Number | Estado | MC02 Num 1 |
| Num 2 | SEQUENCE_TIMER | Number | Estado | MC02 Num 2 |
| Num 3 | ALTITUDE | Number | Sensor físico | Sensor de altitud |
| Num 4 | ALTITUDE_TARGET | Number | Parámetro | Configuración |
| Num 5 | VERTICAL_SPEED | Number | Sensor físico | Sensor de velocidad vertical |
| Num 6 | DESIRED_VERTICAL_SPEED | Number | Cálculo de control | MC04 Num 5 |
| Num 7 | REAL_RPS | Number | Sensor físico | Sensor RPS |
| Num 8 | TARGET_RPS | Number | Parámetro | Configuración |
| Num 9 | TILT_ROLL_HORIZ | Number | Sensor físico | Sensor de inclinación |
| Num 10 | TILT_PITCH | Number | Sensor físico | Sensor de inclinación |
| Num 11 | AP_DISTANCE | Number | Dato de navegación | MC05 Num 7 |
| Num 12 | AP_YAW | Number | Cálculo de control | MC05 Num 6 |
| Num 13 | AP_MY_X | Number | Dato de navegación | MC05 Num 8 |
| Num 14 | AP_MY_Y | Number | Dato de navegación | MC05 Num 9 |
| Num 15 | AP_TARGET_X | Number | Dato de navegación | MC05 Num 10 |
| Num 16 | AP_TARGET_Y | Number | Dato de navegación | MC05 Num 11 |
| Num 17 | SPOILER | Number | Orden de control | MC06 Num 5 |

## 12.3. Entradas Boolean

| Canal | Señal | Dato | Naturaleza | Origen |
|---|---|---|---|---|
| Bool 1 | RUNNING | Boolean | Estado | MC02 Bool 1 |
| Bool 2 | COMPLETED | Boolean | Estado | MC02 Bool 2 |
| Bool 3 | AUTOPILOT | Boolean | Estado | MC02 Bool 9 |
| Bool 4 | MAIN_BOOSTER | Boolean | Estado de actuador | MC06 Bool 1 |
| Bool 5 | ALTITUDE_HOLD | Boolean | Estado | MC02 Bool 8 |
| Bool 6 | ROLL_STABILIZER | Boolean | Estado | MC02 Bool 3 |
| Bool 7 | ACCELERATION_BOOSTERS | Boolean | Estado de actuador | MC06 Bool 9 |
| Bool 8 | NORTH_BOOSTER | Boolean | Estado de actuador | MC06 Bool 5 |
| Bool 9 | EAST_BOOSTER | Boolean | Estado de actuador | MC06 Bool 6 |
| Bool 10 | SOUTH_BOOSTER | Boolean | Estado de actuador | MC06 Bool 7 |
| Bool 11 | WEST_BOOSTER | Boolean | Estado de actuador | MC06 Bool 8 |

## 12.4. Información transmitida

MC07 recopila información sobre:

- Estado y fase de vuelo.
- Tiempo de secuencia.
- Altitud actual y objetivo.
- Error de altitud.
- Velocidad vertical actual y deseada.
- Error de velocidad vertical.
- RPS actual y objetivo.
- Inclinación de roll y pitch.
- Estado del piloto automático.
- Distancia al objetivo.
- Corrección de yaw.
- Coordenadas actuales y objetivo.
- Estado de los propulsores.
- Estado de mantenimiento de altitud.
- Estado de estabilización.
- Valor del spoiler.

## 12.5. Comunicación HTTP

La transmisión se realiza mediante la funcionalidad HTTP de Stormworks Lua:

`async.httpGet(8080, url)`

El endpoint utiliza el formato:

`/telemetry?...`

MC07 proporciona una salida de comunicación HTTP, pero no dispone de salidas de control de actuadores dentro de la arquitectura descrita.

---

# 13. Tabla maestra de salidas de actuadores

Esta tabla identifica las salidas de control que deben llegar a los actuadores del vehículo.

Los canales lógicos están identificados por los scripts. La correspondencia con los componentes físicos debe verificarse con el montaje del vehículo.

| Controlador | Salida | Señal | Dato | Actuador o sistema |
|---|---|---|---|---|
| MC03 | Num 1 | ROLL_RIGHT | Number | Control de roll derecho |
| MC03 | Num 2 | ROLL_LEFT | Number | Control de roll izquierdo |
| MC04 | Num 3 | ELEVATOR_RIGHT | Number | Elevador derecho |
| MC04 | Num 4 | ELEVATOR_LEFT | Number | Elevador izquierdo |
| MC05 | Num 6 | AP_YAW | Number | Timón de dirección |
| MC06 | Num 5 | SPOILER | Number | Sistema de spoiler |
| MC06 | Bool 1 | MAIN_BOOSTER | Boolean | Propulsor principal |
| MC06 | Bool 9 | ACCELERATION_BOOSTER | Boolean | Propulsor de aceleración |
| MC06 | Bool 5 | NORTH_BOOSTER | Boolean | Propulsor norte |
| MC06 | Bool 6 | EAST_BOOSTER | Boolean | Propulsor este |
| MC06 | Bool 7 | SOUTH_BOOSTER | Boolean | Propulsor sur |
| MC06 | Bool 8 | WEST_BOOSTER | Boolean | Propulsor oeste |

**Nota:** las salidas `DESIRED_VERTICAL_SPEED` de MC04 y las salidas de navegación de MC05 son señales internas de comunicación entre controladores, no salidas físicas de actuadores.

---

# 14. Diagramas de arquitectura

## 14.1. Distribución general

```text
                 SENSORES Y CONFIGURACIÓN
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
       +------+         +------+         +------+
       | MC01 |         | MC03 |         | MC04 |
       | SEQ. |         |ROLL  |         | ALT. |
       +------+         +------+         +------+
          |
          | Órdenes y estados
          v
       +------+
       | MC02 |
       |MASTER|
       +------+
          |
          +----------------+----------------+
          |                |                |
          v                v                v
       +------+         +------+         +------+
       | MC03 |         | MC04 |         | MC05 |
       |ROLL  |         | ALT. |         | NAV. |
       +------+         +------+         +------+
                                           |
                                           | AP_TARGET_HEADING
                                           | Num 12
                                           v
                                        +------+
                                        | MC06 |
                                        |PROP. |
                                        +------+

       MC02 -----------+
       MC04 -----------+----> MC07 ----> HTTP
       MC05 -----------+
       MC06 -----------+
       SENSORES -------+
```

El diagrama representa relaciones funcionales. No significa que todas las señales deban pasar por MC02.

## 14.2. Flujo principal de órdenes

```text
MC01 FLIGHT SEQUENCE
          |
          v
MC02 MASTER CONTROL
          |
          +----> MC03 FLIGHT CONTROL
          |
          +----> MC04 ALTITUDE CONTROL
          |
          +----> MC05 NAVIGATION
          |
          +----> MC06 PROPULSION
```

## 14.3. Flujo de navegación y propulsión

```text
SENSORES DE POSICIÓN
SENSOR DE BRÚJULA
COORDENADAS OBJETIVO
          |
          v
    MC05 NAVIGATION
          |
          +---- AP_DISTANCE
          |
          +---- AP_YAW
          |
          +---- AP_MY_X / AP_MY_Y
          |
          +---- AP_TARGET_X / AP_TARGET_Y
          |
          +---- AP_TARGET_HEADING
                         |
                         | MC05 Num 12
                         v
                    MC06 Num 2
                         |
                         v
                PROPULSORES DIRECCIONALES
```

## 14.4. Flujo de control de altitud

```text
SENSOR DE ALTITUD ------------------+
                                    |
ALTITUDE_TARGET --------------------+
                                    |
SENSOR VERTICAL_SPEED --------------+
                                    |
ALT_PID_P / ALT_PID_I / ALT_PID_D --+
                          |
                          v
                   MC04 ALTITUDE
                          |
              +-----------+-----------+
              |                       |
              v                       v
        ELEVADORES             DESIRED_VERTICAL_SPEED
                                      |
                                      | MC04 Num 5
                                      v
                                  MC07 Num 6
```

---

# 15. Procedimiento de validación del montaje

La validación debe realizarse módulo por módulo antes de probar el sistema completo.

## 15.1. Comprobación de conexiones Composite

- [ ] Todos los microcontroladores están instalados.
- [ ] Cada Composite está conectado al módulo correspondiente.
- [ ] Los canales Boolean se conectan a entradas Boolean.
- [ ] Los canales Number se conectan a entradas Number.
- [ ] Los números de canal coinciden con las tablas.
- [ ] No existen asignaciones duplicadas involuntarias.
- [ ] Todas las señales necesarias llegan a sus destinos.

## 15.2. Comprobación de sensores

- [ ] Sensor de altitud.
- [ ] Sensor de velocidad vertical.
- [ ] Sensor RPS.
- [ ] Sensor de inclinación horizontal.
- [ ] Sensor de inclinación vertical.
- [ ] Sensor de pitch.
- [ ] Sensor de posición X.
- [ ] Sensor de posición Y.
- [ ] Sensor de brújula.
- [ ] Valores de configuración.

## 15.3. Comprobación de módulos

| Módulo | Prueba |
|---|---|
| MC01 | Inicio, progresión y finalización de secuencia |
| MC02 | Recepción y retransmisión de señales |
| MC03 | Activación y respuesta de estabilización |
| MC04 | Control PID, salida de elevadores y velocidad vertical deseada |
| MC05 | Posición, distancia, rumbo y salida de navegación |
| MC06 | Propulsor principal, aceleración, direccionales y spoiler |
| MC07 | Recepción de datos y transmisión HTTP |

## 15.4. Pruebas de integración

- [ ] MC01 transmite correctamente las órdenes a MC02.
- [ ] MC02 retransmite correctamente las órdenes a los módulos correspondientes.
- [ ] MC03 recibe la orden de estabilización.
- [ ] MC04 recibe las mediciones y parámetros de altitud.
- [ ] MC04 publica `DESIRED_VERTICAL_SPEED` en Number 5.
- [ ] MC07 recibe `DESIRED_VERTICAL_SPEED` por Number 6.
- [ ] MC05 transmite `AP_TARGET_HEADING` por Number 12.
- [ ] MC06 recibe `AP_TARGET_HEADING` por Number 2.
- [ ] MC06 genera las órdenes de propulsión esperadas.
- [ ] MC07 recibe los datos de navegación y estados.
- [ ] MC07 transmite telemetría correctamente.
- [ ] La secuencia puede iniciarse nuevamente sin conservar estados no deseados.

---

# 16. Consideraciones de integración pendientes

Los siguientes puntos deben comprobarse durante el montaje y las pruebas físicas.

| Elemento | Estado | Acción necesaria |
|---|---|---|
| MC05 AP_TARGET_HEADING | Canal definido: Num 12 | Conectar a MC06 Num 2 |
| MC04 DESIRED_VERTICAL_SPEED | Canal definido: Num 5 | Conectar a MC07 Num 6 |
| MC05 AP_DISTANCE | Canal definido: Num 7 | Conectar a MC07 Num 11 |
| MC06 reinicio de propulsores | Pendiente de validación | Comprobar reinicio entre vuelos |
| Cableado físico de actuadores | Por comprobar en vehículo | Confirmar correspondencia de cada salida |
| Distribución Composite física | Por comprobar en vehículo | Verificar conexiones y ramificaciones |
| Telemetría HTTP | Pendiente de prueba integrada | Verificar recepción en el puerto 8080 |

Las conexiones lógicas indicadas en este documento deben respetarse aunque la distribución física del cableado sea diferente.

---

# 17. Mantenimiento y ampliación

La arquitectura permite ampliar las funciones del sistema sin modificar innecesariamente los demás controladores.

Cualquier cambio debe cumplir estas condiciones:

1. Mantener una responsabilidad clara por microcontrolador.
2. Documentar cada nueva entrada y salida.
3. Evitar reutilizar canales ya asignados.
4. Mantener la correspondencia entre tipo de dato y canal.
5. Actualizar la tabla maestra de conexiones.
6. Actualizar las tablas individuales del módulo afectado.
7. Verificar las conexiones de los módulos que reciben las señales.
8. Probar el funcionamiento individual y conjunto.

Las nuevas señales deben incorporarse primero a la tabla maestra de conexiones y después a las secciones de cada microcontrolador.

---

# 18. Política de versiones

El proyecto utiliza dos niveles de versionado.

| Versión | Significado |
|---|---|
| System Version | Versión global de la arquitectura |
| Module Version | Versión individual de cada microcontrolador |

Versión actual del sistema:

`SYSTEM VERSION: 14.0`

Cada módulo debe incluir su propio encabezado:

```lua
-- OAI MIZUSHIMA YR-02
-- MC 0X: MODULE NAME
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
-- RESPONSIBILITY:
-- Module responsibility
```

Cuando se modifica una conexión, debe actualizarse la documentación del origen y del destino.

Una modificación de canal no se considera completa hasta que ambos extremos estén documentados y comprobados.

---

# 19. Filosofía del proyecto

El OAI MIZUSHIMA YR-02 se basa en tres principios:

**Modularidad:** cada microcontrolador tiene una responsabilidad definida.

**Preservación:** los cálculos y comportamientos originales deben mantenerse salvo que exista una modificación intencionada.

**Ampliabilidad:** las nuevas funciones deben integrarse sin introducir dependencias innecesarias.

El objetivo es mantener un sistema de control de vuelo organizado, verificable y fácil de mantener.

---

**OAI MIZUSHIMA YR-02**  
*Modular Flight Control System — System Version 14.0*