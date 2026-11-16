# OAI MIZUSHIMA YR-02
# UNIVERSAL LINK SYSTEM

**VERSIÓN DEL SISTEMA:** 14.0  
**MICROCONTROLADORES:** MC01 / MC02  
**ENTORNO:** Stormworks: Build and Rescue  
**ESTÁNDAR:** MC Architecture Standard v1.0

---

# 1. DESCRIPCIÓN GENERAL

## 1.1. Propósito

Universal Link System es un controlador de comunicación por radio diseñado para establecer y supervisar enlaces bidireccionales entre dos unidades independientes en Stormworks.

Su función principal es mantener la comunicación mediante un sistema de heartbeat, detectar pérdidas de conexión y, cuando está habilitado, cambiar automáticamente las frecuencias de comunicación mediante **Adaptive Frequency Hopping (AFH)**.

Aunque utiliza los roles AIR y GROUND, el sistema es universal y puede emplearse entre diferentes tipos de unidades:

- Estación ↔ Estación
- Vehículo ↔ Vehículo
- Estación ↔ Vehículo
- Aeronave ↔ Estación

Está diseñado para enlaces punto a punto de dos extremos, no para gestionar redes de múltiples dispositivos.

## 1.2. Arquitectura

El sistema está compuesto por dos microcontroladores:

| MC | Nombre | Función |
|---|---|---|
| MC01 | Universal Link System | Gestión del enlace, heartbeat, supervisión de conexión y AFH |
| MC02 | Diagnostic Display | Visualización del estado y diagnóstico de MC01 |

MC01 contiene toda la lógica de comunicación. MC02 recibe sus señales de diagnóstico y las representa visualmente.

El sistema puede funcionar de manera independiente o integrarse en Mizushima y otros proyectos compatibles.

## 1.3. Flujo general

```text
       UNIDAD A                         UNIDAD B
      ROLE: AIR                       ROLE: GROUND
          |                                |
          v                                v
    +-----------+                    +-----------+
    |   MC01    |                    |   MC01    |
    | LINK SYS  |                    | LINK SYS  |
    +-----------+                    +-----------+
          |                                |
          v                                v
     RADIO TX/RX                       RADIO TX/RX
          |                                |
          +---------- RADIO --------------+
          |
          v
    +-----------+
    |   MC02    |
    | DIAGNOSTIC|
    +-----------+
```

Cada extremo dispone de su propio MC01. Ambos intercambian información mediante las antenas de radio de Stormworks.

---

# 2. MC01 – UNIVERSAL LINK SYSTEM

**VERSIÓN:** 5.1.1

## 2.1. Roles operativos

MC01 dispone de dos roles lógicos seleccionables mediante una entrada BOOL.

| Rol | TX | RX |
|---|---|---|
| AIR | BASE + DISTANCE | BASE |
| GROUND | BASE | BASE + DISTANCE |

Los roles son intercambiables y no están vinculados a un tipo concreto de vehículo o estación.

## 2.2. Estados de conexión

El controlador mantiene tres estados:

| Valor | Estado | Descripción |
|---:|---|---|
| 0 | SEARCHING | Esperando un heartbeat válido |
| 1 | CONNECTED | Comunicación establecida |
| 2 | LINK_LOST | Tiempo de espera superado |

La conexión se considera válida cuando se recibe un heartbeat que supera todas las comprobaciones del protocolo.

## 2.3. Entradas

| Canal | Tipo | Función |
|---:|---|---|
| 1–4 | NUMBER | Protocolo, ID remoto, contador y versión recibidos |
| 5 | NUMBER | Timeout |
| 6–7 | NUMBER | Frecuencia base y distancia |
| 8–11 | NUMBER | Protocolo, versión, ID local e ID remoto |
| 12 | BOOL | Selector AIR/GROUND |
| 12–13 | NUMBER | Frecuencias mínima y máxima de AFH |
| 13 | BOOL | Activación de AFH |

## 2.4. Salidas

| Canal | Tipo | Función |
|---:|---|---|
| 1–4 | NUMBER | Protocolo, ID local, contador TX y versión |
| 5–7 | NUMBER | Estado, antigüedad RX y contador TX de diagnóstico |
| 8–9 | NUMBER | Frecuencias TX y RX |
| 10–11 | NUMBER | Timeout y último contador RX aceptado |
| 1–3 | BOOL | CONNECTED, SEARCHING y LINK_LOST |
| 6 | BOOL | AFH activo |

## 2.5. Heartbeat y supervisión

Cada extremo transmite continuamente su información de identificación y contador mediante las salidas de MC01.

El extremo receptor comprueba:

- Coincidencia del identificador de protocolo.
- Coincidencia del ID remoto.
- Coincidencia de la versión.
- Validez del contador recibido.
- Correspondencia con el contador esperado.

El contador utiliza una representación interna en décimas, con valores comprendidos entre 10 y 999. Al transmitirse se divide entre diez.

Cada heartbeat válido reinicia el contador de antigüedad de recepción. Si se alcanza el timeout configurado, el estado cambia a LINK_LOST.

El timeout se mide en ticks de ejecución de Stormworks.

## 2.6. Adaptive Frequency Hopping (AFH)

AFH permite generar nuevas frecuencias de comunicación cuando se pierde el enlace y la función está habilitada.

La secuencia se calcula localmente mediante un generador pseudoaleatorio determinista. Ambos extremos pueden obtener los mismos resultados sin intercambiar directamente las frecuencias calculadas.

La semilla utiliza los siguientes parámetros:

- Identificador de protocolo.
- Versión del sistema.
- Distancia de frecuencia.

El rango mínimo y máximo determina los límites de generación.

El generador utiliza un algoritmo Linear Congruential Generator (LCG) y produce dos frecuencias que se asignan de forma complementaria según el rol:

| Rol | TX | RX |
|---|---|---|
| AIR | Frecuencia A | Frecuencia B |
| GROUND | Frecuencia B | Frecuencia A |

El índice de salto se calcula utilizando la antigüedad de recepción y el timeout:

```lua
currentHop = math.floor(rxAge / config.timeout)
```

Cada cambio de índice genera un nuevo par de frecuencias.

**Requisito de sincronización:** ambos extremos deben compartir los mismos parámetros de generación, incluyendo protocolo, versión, distancia, rango AFH y timeout, para mantener una secuencia y temporización equivalentes.

AFH responde a la pérdida de comunicación, pero no identifica si esta se debe a interferencias, obstrucciones, desconexión o jamming.

---

# 3. MC02 – DIAGNOSTIC DISPLAY

**VERSIÓN:** 1.0.0  
**RESOLUCIÓN DE REFERENCIA:** 288 × 160 píxeles

## 3.1. Propósito

MC02 es la interfaz visual de diagnóstico de Universal Link System.

Recibe directamente las señales de MC01 y muestra el estado del enlace y sus principales parámetros operativos.

No interviene en la gestión de comunicación ni en el cálculo de frecuencias.

## 3.2. Información mostrada

| Panel | Información |
|---|---|
| Connection Status | Rol operativo y estado del enlace |
| Communication | Antigüedad RX, timeout y contadores TX/RX |
| Frequency Monitor | Frecuencias actuales de transmisión y recepción |
| AFH Status | Estado de habilitación y activación de AFH |
| System Identification | ID local, protocolo y versión |

## 3.3. Indicadores AFH

| Indicador | Significado |
|---|---|
| ACTIVE | AFH activado |
| STANDBY | AFH habilitado, pendiente de activación |
| DISABLED | AFH deshabilitado |

La pantalla también incluye una barra de progreso para representar visualmente la antigüedad de recepción respecto al timeout configurado.

---

# 4. CONFIGURACIÓN E INTEGRACIÓN

## 4.1. Configuración de los extremos

Para establecer un enlace, ambos MC01 deben configurarse de forma compatible.

| Parámetro | Extremo A | Extremo B |
|---|---|---|
| Protocolo | Mismo valor | Mismo valor |
| Versión | Mismo valor | Mismo valor |
| ID local | ID A | ID B |
| ID remoto | ID B | ID A |
| Rol | AIR | GROUND |
| Frecuencia base | Mismo valor | Mismo valor |
| Distancia | Mismo valor | Mismo valor |
| Timeout | Mismo valor | Mismo valor |
| Rango AFH | Mismo rango | Mismo rango |

Los identificadores locales y remotos deben configurarse de forma cruzada.

## 4.2. Integración con radio

MC01 calcula y proporciona las frecuencias, pero no controla directamente las antenas.

El montaje externo debe conectar:

1. Las salidas de heartbeat de MC01 al sistema de transmisión.
2. Los datos recibidos por radio a las entradas de recepción de MC01.
3. Las frecuencias TX/RX a los componentes de radio correspondientes.
4. Las señales de diagnóstico de MC01 a MC02.

La transmisión y recepción efectiva dependen de la configuración del hardware de radio de Stormworks.

---

# 5. LIMITACIONES Y CONSIDERACIONES

- El sistema está diseñado para dos extremos por enlace.
- No implementa gestión de redes múltiples ni enrutamiento.
- AIR y GROUND son roles lógicos, no categorías de vehículos.
- La detección de pérdida de conexión no identifica su causa física.
- AFH requiere parámetros compatibles entre ambos extremos.
- No existe negociación dinámica de parámetros AFH.
- El sistema no implementa cifrado ni autenticación criptográfica.
- La gestión física de las antenas corresponde al montaje externo.

**Comportamiento de recuperación:** el código mantiene las frecuencias AFH después de recuperar la conexión. No existe un retorno automático explícito a las frecuencias base mientras AFH siga habilitado.

---

# 6. IDENTIFICACIÓN DEL SOFTWARE

| Microcontrolador | Versión | Sistema |
|---|---|---|
| MC01 – Universal Link System | 5.1.1 | 14.0 |
| MC02 – Diagnostic Display | 1.0.0 | 14.0 |

**Estándar de arquitectura:** MC Architecture Standard v1.0.

---

**OAI MIZUSHIMA YR-02 – UNIVERSAL LINK SYSTEM**  
*Universal point-to-point radio communication with heartbeat monitoring and adaptive frequency hopping.*