# 🚀 Stormworks OAi Mizushima YR-02 System

![Version](https://img.shields.io/badge/Version-14.0--develop-blue.svg)
![Game](https://img.shields.io/badge/Stormworks-Lua%20%2F%20HTTP-orange.svg)
![Backend](https://img.shields.io/badge/Backend-Python%20%7C%20Flask%20%7C%20Docker-green.svg)

El **Sistema Mizushima YR-02** desarrollado por **OAi (OIA)** es un ecosistema avanzado de guiado, control de vuelo autónomo, enlace universal de datos (RX/TX) y telemetría en tiempo real para misiles de crucero dentro de *Stormworks: Build and Rescue*. 

Esta versión (`V14.0` en la rama `develop`) evoluciona desde una arquitectura monolítica hacia un sistema completamente **modular** en Lua, acompañado de un servidor backend en Python con un panel de control web interactivo, grabador de cajas negras (Flight Recorder) y analizador post-vuelo.

---

## 📑 Tabla de Contenidos

1. [Arquitectura del Repositorio](#-arquitectura-del-repositorio)
2. [Documentación de Componentes (Referencias)](#-documentación-de-componentes-referencias)
3. [Guía de Instalación del Servidor / Backend](#-guía-de-instalación-del-servidor--backend)
   - [Opción A: Despliegue con Docker (Recomendado)](#opción-a-despliegue-con-docker-recomendado)
   - [Opción B: Instalación Manual en Local (Python)](#opción-b-instalación-manual-en-local-python)
4. [Configuración en Stormworks](#-configuración-en-stormworks)
5. [Herramientas Adicionales](#-herramientas-adicionales)

---

## 📂 Arquitectura del Repositorio

El proyecto se divide en tres bloques tecnológicos principales:

```text
Stormworks-OAi-Mizushima-YR-02-System/
├── Cruise Missle System V14.0/          # Última versión modular del sistema de vuelo (Lua)
│   ├── Main-Microprocessor-Air/         # Microcontrolador principal del misil (MC01 a MC08)
│   └── RX-TX-Microprocessor/            # Sistema de enlace de comunicaciones y HUD (MC01 y MC02)
├── Cruise Missle System V13.1.0/        # Versión legacy monolítica
└── Server/                              # Ecosistema Backend y Telemetría Web
    ├── Tools/                           # Analizador de vuelos independiente (flight_analyzer.html)
    ├── telemetry-monitor/               # Aplicación Web (Python/JS Modular/Temas CSS)
    ├── Dockerfile                       # Imagen de contenedor para el servidor
    └── docker-compose.yml               # Orquestación rápida del servicio
```

---

## 📚 Documentación de Componentes (Referencias)

Para mantener este documento limpio, la documentación técnica profunda de los canales de bus compuesto (Composite I/O), algoritmos PID y esquemas JSON se encuentra dividida en sus respectivos módulos:

* ✈️ **[Microprocesador Principal de Vuelo (V14.0)](./Cruise%20Missle%20System%20V14.0/Main-Microprocessor-Air/README.md)**
  * Explicación detallada de los 8 submódulos Lua (`MC01` Secuencia de vuelo, `MC02` Control Maestro, `MC03` Control de Vuelo/Estabilización, `MC04` Altitud, `MC05` Navegación por Waypoints, `MC06` Propulsión, `MC07` Telemetría HTTP y `MC08` Perfil de Descenso Adaptativo).
* 📡 **[Sistema Universal de Enlace RX-TX (V14.0)](./Cruise%20Missle%20System%20V14.0/RX-TX-Microprocessor/README.md)**
  * Documentación sobre el protocolo de enlace de radio bidireccional (`MC01_UNIVERSAL_LINK_SYSTEM.lua`) y la interfaz en pantalla del operador (`MC02_UNIVERSAL_LINK_SYSTEM_DISPLAY.lua`).
* 🖥️ **[Servidor de Telemetría y Dashboard Web](./Server/README.md)**
  * Arquitectura de la API REST, configuración del esquema de telemetría (`telemetry_schema.json`), módulos del frontend (gráficas, diagnósticos, eventos) y sistema de temas visuales (OIA Mizushima, NieR, Cyberpunk, Militar, etc.).
* 📜 **[Sistema Legacy (V13.1.0)](./Cruise%20Missle%20System%20V13.1.0/README.md)**
  * Documentación de referencia para el script monolítico `Modular_Flight_Control-MIZUSHIMA_YR-02.lua`.

---

## 🛠️ Guía de Instalación del Servidor / Backend

El servidor de telemetría recibe los paquetes enviados desde Stormworks a través del puerto local (HTTP) y los representa en tiempo real en tu navegador web.

### Requisitos Previos
* Tener instalado [Git](https://git-scm.com/).
* **Para la Opción A:** [Docker Desktop](https://www.docker.com/products/docker-desktop/) (Windows/Mac) o Docker Engine + Docker Compose (Linux).
* **Para la Opción B:** [Python 3.9+](https://www.python.org/downloads/).

---

### Opción A: Despliegue con Docker (Recomendado)

Es la forma más rápida y limpia de levantar el servidor sin preocuparse por dependencias de Python.

1. Abre una terminal y sitúate en la carpeta `Server` del repositorio:
   ```bash
   cd "Stormworks-OAi-Mizushima-YR-02-System/Server"
   ```
2. Construye y levanta el contenedor en segundo plano usando Docker Compose:
   ```bash
   docker-compose up -d --build
   ```
3. Verifica que el contenedor está corriendo:
   ```bash
   docker-compose ps
   ```
4. Abre tu navegador web y entra en:
   👉 **`http://localhost:5000`** *(Nota: Si has configurado otro puerto en tu `docker-compose.yml`, usa ese puerto).*

Para detener el servidor en cualquier momento:
```bash
docker-compose down
```

---

### Opción B: Instalación Manual en Local (Python)

Si prefieres ejecutar el servidor directamente en tu sistema operativo o vas a desarrollar/modificar el código del backend:

1. Abre una terminal y entra en el directorio `Server`:
   ```bash
   cd "Stormworks-OAi-Mizushima-YR-02-System/Server"
   ```
2. Crea un entorno virtual de Python para aislar las librerías:
   ```bash
   python -m venv venv
   ```
3. Activa el entorno virtual:
   * **En Windows (PowerShell):**
     ```powershell
     .\venv\Scripts\Activate.ps1
     ```
   * **En Linux / macOS:**
     ```bash
     source venv/bin/activate
     ```
4. Instala las dependencias necesarias desde `requirements.txt`:
   ```bash
   pip install -r requirements.txt
   ```
5. Entra en el directorio de la aplicación y ejecuta el servidor:
   ```bash
   cd telemetry-monitor
   python app.py
   ```
6. Accede al panel de control desde tu navegador en **`http://127.0.0.1:5000`**.

---

## 🎮 Configuración en Stormworks

Para que el misil en Stormworks pueda comunicarse con el servidor que acabas de montar:

1. Asegúrate de que el servidor (Docker o Python) esté ejecutándose **antes** de lanzar el misil.
2. En tu vehículo de Stormworks, verifica que el bloque Lua `MC07_TELEMETRY.lua` esté conectado y apunte al puerto configurado en tu `app/config.py` (por defecto `localhost:5000`).
3. Durante la misión, el panel web detectará automáticamente la conexión a través del módulo `connectionManager.js` y comenzará a graficar los datos y registrar eventos.

---

## 📊 Herramientas Adicionales

* **Flight Analyzer (`Server/Tools/flight_analyzer.html`):** Herramienta web autónoma (no requiere servidor activo) que te permite cargar los archivos JSON generados por el *Flight Recorder* (`recorder_service.py`) para analizar gráficas de telemetría post-misión, estudiar fallos de PID o revisar el perfil de descenso.