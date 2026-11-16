# OAI MIZUSHIMA YR-02
### Autonomous Programmable Cruise Missile System

**OAI MIZUSHIMA YR-02** es un vehículo aéreo no tripulado de tipo *cruise missile* (misil de crucero), desarrollado íntegramente dentro de **Stormworks: Build and Rescue**.

Se trata de un sistema de vuelo autónomo y completamente programable, diseñado para realizar misiones de navegación mediante coordenadas, controlar su trayectoria y gestionar de forma automatizada sus diferentes sistemas de vuelo y propulsión.

Su funcionamiento se basa en una secuencia de vuelo programada que coordina los distintos subsistemas del vehículo, desde las comprobaciones iniciales y la estabilización hasta la navegación autónoma y el perfil de descenso.

Mizushima no es simplemente un vehículo con piloto automático: es una plataforma integrada de control, navegación, propulsión, comunicaciones y supervisión, desarrollada mediante una arquitectura modular de microcontroladores y software externo.

---

# 1. STACK TECNOLÓGICO

El proyecto combina tecnologías internas de Stormworks con aplicaciones externas para ampliar sus capacidades de supervisión y comunicación.

| Tecnología | Aplicación |
|---|---|
| Stormworks: Build and Rescue | Simulación y entorno de ejecución del vehículo |
| Lua | Programación de los sistemas de control y automatización |
| Microcontrollers (MC) | Arquitectura modular de control |
| Composite Signals | Comunicación interna entre subsistemas |
| Sensors & Logic Components | Captura de información y control del vehículo |
| Radio Communication | Comunicación inalámbrica entre unidades |
| Python 3.12 | Backend del sistema de telemetría |
| Flask | Servidor HTTP y API |
| HTML5 / CSS3 | Interfaz del monitor de vuelo |
| JavaScript ES Modules | Arquitectura modular del dashboard |
| JSON | Configuración, intercambio de datos y registros |
| Docker / Docker Compose | Despliegue del servidor de telemetría |

El sistema utiliza Lua como tecnología principal de programación dentro de Stormworks, mientras que Python y JavaScript amplían sus capacidades fuera del vehículo.

---

# 2. CONCEPTO GENERAL

Mizushima es un vehículo aéreo autónomo de tipo misil de crucero, con navegación guiada por coordenadas y una secuencia de vuelo automatizada.

Su objetivo es ejecutar una misión previamente configurada sin necesitar intervención continua del operador.

El vehículo dispone de sistemas independientes que trabajan conjuntamente para mantener la estabilidad, gestionar la propulsión, controlar la altitud y calcular su trayectoria hacia un destino.

Su lógica general se organiza alrededor de tres conceptos:

- **Automatización:** el vehículo ejecuta las diferentes fases de vuelo mediante una secuencia programada.
- **Navegación autónoma:** utiliza coordenadas de destino y sensores de posición para calcular el rumbo y mantener la trayectoria.
- **Control integrado:** los distintos subsistemas gestionan la estabilidad, altitud, propulsión y descenso durante el vuelo.

La configuración de la misión permite establecer parámetros de navegación y comportamiento, proporcionando un vuelo altamente programable y adaptable.

# 3. EVOLUCIÓN DEL SISTEMA

## 3.1. Version 13.1.0 — Initial Flight System

La versión 13.1.0 representa la primera arquitectura funcional documentada de Mizushima.

En esta etapa, todos los sistemas principales estaban implementados dentro de un único script Lua ejecutado por un microcontrolador.

A pesar de su estructura monolítica, ya incorporaba buena parte de las capacidades fundamentales del vehículo:

- Estabilización de balanceo (Roll Stabilizer).
- Control automático de altitud mediante PID.
- Navegación autónoma por coordenadas.
- Control de rumbo y dirección.
- Sistemas de propulsión y boosters.
- Spoilers y control de aceleración.
- Secuencia automatizada de vuelo.
- Telemetría mediante HTTP.

Esta versión permitió desarrollar y validar la lógica general del vehículo, pero la concentración de todas las funciones en un único script dificultaba su mantenimiento y ampliación.

La versión 13.1.0 constituye el punto de partida de la arquitectura posterior.

## 3.2. Version 14.0 — Modular Flight Architecture

La versión 14.0 representa una evolución importante del proyecto.

El sistema abandona la arquitectura monolítica y reorganiza las funciones del vehículo en **ocho microcontroladores independientes**, cada uno especializado en una responsabilidad concreta.

Esta separación permite desarrollar, mantener y ampliar los distintos sistemas sin concentrar toda la lógica de vuelo en un único controlador.

La arquitectura actual se compone de los siguientes subsistemas:

### MC01 — Flight Sequence

Es el controlador de la secuencia de vuelo.

Gestiona las diferentes etapas de la misión y determina cuándo deben activarse los distintos sistemas del vehículo.

La secuencia contempla comprobaciones iniciales, estabilización, activación de propulsión, navegación, habilitación del descenso y finalización de la misión.

### MC02 — Master Control

Actúa como distribuidor de órdenes generales.

Su función es centralizar la distribución de las órdenes de la secuencia de vuelo hacia los subsistemas correspondientes, sin realizar directamente los algoritmos de control especializados.

### MC03 — Flight Control

Gestiona la estabilización de balanceo del vehículo.

Utiliza información de inclinación para calcular las correcciones necesarias y mantener una actitud de vuelo estable.

### MC04 — Altitude Control

Se encarga del control automático de altitud.

Utiliza un controlador PID para regular el comportamiento vertical del vehículo y dispone de una lógica específica para gestionar el descenso.

Mantiene separados los procesos de control de altitud normal y descenso, permitiendo adaptar el comportamiento a las distintas fases de vuelo.

### MC05 — Navigation

Es el sistema responsable de la navegación autónoma.

Utiliza coordenadas de destino y datos de posición para calcular la dirección necesaria, el rumbo objetivo y la distancia restante.

Incorpora parámetros de sensibilidad, zona muerta y suavizado para ajustar el comportamiento de navegación.

El sistema permite que Mizushima siga una trayectoria definida mediante coordenadas, sin depender de una dirección fija establecida manualmente durante todo el vuelo.

### MC06 — Propulsion

Gestiona los diferentes sistemas de propulsión y asistencia al vuelo.

Incluye:

- Main Booster.
- Directional Boosters.
- Bottom Boosters.
- Acceleration Boosters.
- Afterburner.
- Spoiler Control.

Su lógica coordina la activación de estos sistemas y utiliza información de rumbo e inclinación para determinar el comportamiento de los propulsores direccionales.

### MC07 — Telemetry

Es el subsistema de recopilación y transmisión de información.

Obtiene datos de los diferentes sistemas del vehículo y los prepara para su supervisión externa.

Incluye información de navegación, altitud, velocidad vertical, estabilidad, propulsión, estado de misión y comunicaciones.

Su funcionamiento es independiente del control de los actuadores, por lo que la ausencia del sistema de telemetría no debe afectar a las funciones principales de vuelo.

### MC08 — Adaptive Descent Profile

Implementa un perfil adaptativo de descenso.

Utiliza la distancia al destino, la altitud, la velocidad horizontal y distintos parámetros de configuración para calcular un objetivo de descenso y una velocidad vertical deseada.

Su finalidad es proporcionar un comportamiento de descenso que se adapte a las condiciones de aproximación, en lugar de depender exclusivamente de un valor fijo.

---

# 4. SISTEMAS PRINCIPALES

La arquitectura 14.0 integra diferentes capacidades que permiten automatizar el comportamiento del vehículo.

## 4.1. Flight Sequence System

El sistema de secuencia organiza el vuelo en etapas definidas.

Cada etapa representa una fase operativa y permite coordinar la activación de los sistemas necesarios.

Esto proporciona un comportamiento estructurado y repetible, evitando que todos los subsistemas tengan que activarse simultáneamente o depender de una intervención manual continua.

## 4.2. Autonomous Navigation

La navegación utiliza coordenadas para determinar el destino y calcular el rumbo necesario.

A partir de la posición actual y la posición objetivo, el sistema obtiene información de distancia y dirección.

La navegación incorpora parámetros configurables para ajustar la respuesta del vehículo, como el suavizado del control, la zona muerta y la distancia de corte.

## 4.3. Flight Stabilization

La estabilización se encarga de corregir las desviaciones de balanceo.

Su objetivo es mantener una actitud de vuelo controlada y reducir las oscilaciones durante el desplazamiento.

Trabaja junto con el resto de sistemas de control para proporcionar un comportamiento estable.

## 4.4. Altitude Hold

El control de altitud mantiene el vehículo alrededor de una altitud objetivo mediante regulación PID.

También contempla límites de velocidad vertical y mecanismos de suavizado para evitar respuestas excesivamente bruscas.

## 4.5. Adaptive Descent

El perfil de descenso adaptativo permite modificar el comportamiento vertical en función de la situación del vehículo respecto al destino.

En lugar de utilizar exclusivamente una velocidad de descenso constante, calcula objetivos que tienen en cuenta parámetros como la distancia restante, la altitud y la velocidad horizontal.

## 4.6. Propulsion Management

El sistema de propulsión agrupa diferentes mecanismos de impulso y asistencia.

Su diseño permite gestionar varios tipos de propulsores, controlar su activación y adaptar su funcionamiento a las distintas fases de vuelo.

También incorpora Afterburner y control de spoilers como parte de la gestión general del vehículo.

---

# 5. UNIVERSAL LINK SYSTEM

Mizushima incorpora un sistema independiente de comunicaciones denominado **Universal Link System (ULS)**.

Su finalidad es establecer y supervisar enlaces de radio bidireccionales entre dos unidades independientes.

Aunque utiliza los roles lógicos AIR y GROUND, puede emplearse entre diferentes tipos de vehículos o estaciones.

El sistema está compuesto por dos microcontroladores:

- **MC01 — Universal Link System:** gestiona la comunicación, el heartbeat, la supervisión del enlace y el Adaptive Frequency Hopping.
- **MC02 — Diagnostic Display:** proporciona una interfaz visual para consultar el estado y los parámetros de comunicación.

### Heartbeat Monitoring

El sistema intercambia continuamente información de identificación y contadores entre ambos extremos.

Cada recepción válida actualiza el estado de comunicación.

Dispone de tres estados principales:

- SEARCHING: buscando un enlace válido.
- CONNECTED: comunicación establecida.
- LINK_LOST: conexión perdida por superar el timeout configurado.

Esto permite supervisar continuamente la disponibilidad del enlace.

### Adaptive Frequency Hopping

El Universal Link System también incorpora Adaptive Frequency Hopping (AFH).

Esta función permite generar cambios de frecuencia mediante una secuencia pseudoaleatoria determinista basada en un algoritmo Linear Congruential Generator (LCG).

Los dos extremos pueden calcular frecuencias complementarias utilizando parámetros compartidos y su rol operativo.

El sistema está diseñado para recuperar la comunicación mediante cambios de frecuencia cuando se pierde el enlace.

No obstante, AFH no identifica la causa física de la pérdida de comunicación y no implementa cifrado ni autenticación criptográfica.

El ULS proporciona a Mizushima una infraestructura de comunicación inalámbrica supervisada y reutilizable en otras unidades compatibles.

---

# 6. FLIGHT TELEMETRY MONITOR

Mizushima YR-02 dispone de una plataforma externa de supervisión denominada **Flight Telemetry Monitor**, desarrollada específicamente para monitorizar el comportamiento del vehículo durante sus misiones.

Su función es recibir y procesar la información generada por los diferentes subsistemas de Mizushima, proporcionando una visión centralizada del estado del vehículo, su navegación, sus parámetros de vuelo y la actividad de sus sistemas.

A través de esta plataforma es posible observar la evolución de una misión, consultar el estado de los principales componentes y conservar registros de telemetría para analizar posteriormente el comportamiento del vehículo.

El monitor funciona de forma independiente a los sistemas de control de vuelo. Su arquitectura es exclusivamente de lectura: recibe información de Mizushima, pero no transmite órdenes ni interviene en la ejecución de las misiones.

### HTTP Telemetry

El sistema de telemetría de Mizushima utiliza comunicación HTTP para transmitir los datos recopilados durante el vuelo.

El microcontrolador **MC07 — Telemetry** reúne información procedente de los diferentes subsistemas y la envía periódicamente al servidor externo mediante peticiones HTTP GET.

El servidor, desarrollado con Python y Flask, recibe los paquetes, procesa las variables reconocidas y mantiene actualizado el último estado conocido del vehículo.

De esta manera, el estado interno de Mizushima puede consultarse desde un equipo externo sin depender de la interfaz de Stormworks.

### Mizushima Flight Dashboard

La plataforma incorpora un dashboard web diseñado para representar la información operativa del YR-02.

Su interfaz está construida mediante módulos JavaScript independientes y permite organizar los distintos indicadores en una distribución configurable.

Entre sus principales funciones de monitorización se encuentran:

- **Flight Status:** estado general del vehículo y fase actual de la misión.
- **Mission Monitoring:** seguimiento de la secuencia de vuelo y sus diferentes etapas.
- **Navigation Monitoring:** información de rumbo, distancia al destino y datos de navegación.
- **Flight Parameters:** altitud, velocidad vertical, velocidad, RPS e inclinación.
- **Propulsion Monitoring:** estado de los boosters, Afterburner y spoilers.
- **System Diagnostics:** indicadores para supervisar los principales sistemas del vehículo.
- **Event Logging:** registro de cambios de estado y eventos relevantes durante el vuelo.
- **Telemetry Graphs:** representación histórica de diferentes parámetros de vuelo.
- **Connection Monitoring:** supervisión de la recepción de telemetría y detección de pérdidas de comunicación con el servidor.

La estructura del dashboard y sus módulos pueden adaptarse para representar nuevas variables o reorganizar la información conforme evoluciona Mizushima.

### Flight Recorder

El Flight Telemetry Monitor incorpora un **Flight Recorder** para conservar registros de las misiones realizadas por Mizushima.

Permite iniciar y detener grabaciones desde la interfaz web, almacenando muestras seleccionadas de telemetría en archivos JSON.

Estos registros permiten consultar posteriormente la evolución de una misión y analizar parámetros como la navegación, altitud, velocidad, actividad de los sistemas y comportamiento general del vehículo.

El Flight Recorder proporciona así una capacidad de registro histórico independiente de la telemetría en tiempo real.

### Tecnología e implementación

El monitor utiliza **Python 3.12 y Flask** para el backend, junto con **HTML5, CSS3 y JavaScript ES Modules** para la interfaz web.

La configuración de los módulos y las variables supervisadas se gestiona mediante archivos JSON. El sistema puede ejecutarse localmente o desplegarse mediante Docker y Docker Compose.

La aplicación constituye el entorno externo de observación y análisis de Mizushima, complementando sus sistemas internos de vuelo sin interferir en su funcionamiento.

---

# 7. ARQUITECTURA Y FILOSOFÍA DE DISEÑO

Una de las características más importantes de Mizushima es su arquitectura modular.

Aunque el sistema se concibe como un único proyecto, sus diferentes subsistemas tienen responsabilidades claramente diferenciadas.

Esta organización proporciona varias ventajas:

**Especialización:** cada microcontrolador se encarga de una función concreta, reduciendo la concentración de lógica y facilitando el mantenimiento.

**Independencia funcional:** los sistemas de navegación, estabilización, altitud, propulsión y telemetría pueden evolucionar de forma diferenciada.

**Escalabilidad:** la arquitectura permite incorporar nuevas capacidades sin tener que reconstruir todo el sistema desde cero.

**Supervisión externa:** la telemetría permite observar el comportamiento del vehículo sin interferir en sus controles.

**Reutilización:** algunos componentes, especialmente Universal Link System y Flight Telemetry Monitor, están diseñados para poder adaptarse a otras unidades y proyectos compatibles.

El proyecto sigue un estándar común de arquitectura para sus microcontroladores, con una organización uniforme del código, configuración, estado interno, funciones y ciclo de ejecución.

Esta estandarización facilita que los distintos subsistemas mantengan una estructura coherente a pesar de implementar funciones muy diferentes.

---

# 8. FLEXIBILIDAD Y POSIBILIDADES

Mizushima está concebido como una plataforma programable y ampliable, no como un vehículo limitado a una única configuración de vuelo.

Entre sus posibilidades actuales destacan:

- Definición de misiones mediante coordenadas.
- Configuración de parámetros de navegación.
- Automatización de distintas fases de vuelo.
- Control automático de estabilidad y altitud.
- Gestión independiente de diferentes sistemas de propulsión.
- Adaptación del perfil de descenso.
- Supervisión del estado de los subsistemas.
- Comunicación inalámbrica entre unidades.
- Monitorización externa en tiempo real.
- Registro de sesiones para análisis posterior.

Su arquitectura permite plantear futuras ampliaciones tanto dentro del vehículo como en sus herramientas externas.

La separación entre control, navegación, propulsión, comunicaciones y supervisión ofrece una base flexible para continuar desarrollando el sistema.

---

# 9. IDENTIDAD DEL PROYECTO

**OAI MIZUSHIMA YR-02** es un proyecto de ingeniería y automatización desarrollado dentro del entorno de simulación Stormworks: Build and Rescue.

Combina programación Lua, control automático, navegación por coordenadas, gestión de propulsión, comunicaciones por radio y herramientas externas de telemetría.

Su evolución desde una implementación monolítica hasta una arquitectura modular de múltiples microcontroladores representa uno de los aspectos centrales de su desarrollo.

El resultado es un vehículo autónomo de tipo cruise missile, con vuelo programable, navegación guiada por coordenadas y un ecosistema de sistemas auxiliares diseñado para ampliar sus capacidades.

**Mizushima no es únicamente un vehículo: es un sistema integrado de vuelo autónomo, control y supervisión.**

---

**OAI MIZUSHIMA YR-02**  
*Autonomous Programmable Cruise Missile System*  
*Stormworks: Build and Rescue*  
*System Version 14.0*