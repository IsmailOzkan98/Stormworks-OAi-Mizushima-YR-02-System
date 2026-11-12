# OAI MIZUSHIMA YR-02
## MODULAR FLIGHT CONTROL SYSTEM

**Project:** OAI MIZUSHIMA YR-02  
**Platform:** Stormworks: Build and Rescue  
**Language:** Lua  
**Current Version:** 13.1.0  
**Architecture:** Single-File Flight Control  
**Development Status:** Functional / Modularization Planned

---

# 1. PROJECT DESCRIPTION

The OAI MIZUSHIMA YR-02 is an advanced modular flight control system developed for Stormworks.

The current implementation uses a single Lua microcontroller script to manage flight stabilization, altitude control, autonomous navigation, propulsion systems, flight sequencing and telemetry.

The long-term objective is to evolve the existing single-file architecture into a distributed modular control system.

Each subsystem will operate through an independent Lua microcontroller, coordinated by a central authority responsible for system permissions, operational priorities and fault management.

The project is designed to support future expansion without requiring modifications to unrelated control systems.

---

# 2. CURRENT SYSTEM ARCHITECTURE

**Version 13.1.0 — Single File**

The current implementation contains the following functional modules:

### 2.1 ROLL STABILIZER
- Roll stabilization.
- Horizontal tilt compensation.
- Configurable control multiplier.
- Independent activation through flight sequence.

### 2.2 ALTITUDE HOLD
- Outer altitude control loop.
- Inner vertical speed control loop.
- PID controller.
- Integral anti-windup.
- Derivative acceleration compensation.
- Elevator output smoothing.
- Configurable climb and descent speed limits.

### 2.3 AUTOPILOT
- Coordinate-based navigation.
- X/Y position tracking.
- Target heading calculation.
- Compass integration.
- Yaw error calculation.
- Steering power adjustment.
- Configurable deadzone.
- Target distance cutoff.
- Yaw smoothing.
- Current and target position telemetry.

### 2.4 DIRECTIONAL BOOSTER SYSTEM
- Automatic directional booster selection.
- North, East, South and West selection.
- Target heading-based orientation.
- Single activation per flight sequence.
- Configurable activation pulse duration.
- Directional selection captured at activation.

### 2.5 BOTTOM BOOSTER SYSTEM
- Tilt sensor magnitude detection.
- Roll angle reconstruction.
- Bottom orientation detection.
- Four directional detection zones.
- Configurable detection margins.
- Integration with directional booster outputs.

### 2.6 MAIN BOOSTER
- Automatic activation through flight sequence.
- Vertical speed threshold monitoring.
- Configurable target vertical speed.

### 2.7 ACCELERATION BOOSTERS
- Automatic activation through flight sequence.
- Integrated spoiler management.
- Independent boolean output.

### 2.8 FLIGHT SEQUENCE
The current flight program consists of ten sequential stages:

1. ENGINE CHECK
2. ROLL STABILIZER
3. MAIN BOOSTER
4. DIRECTIONAL BOOSTER
5. BOTTOM BOOSTER SYSTEM
6. ACCELERATION BOOSTERS
7. ROLL STABILITY CHECK
8. ALTITUDE HOLD
9. AUTOPILOT
10. AUTOPILOT COMPLETE

Sequence management includes:
- Start button edge detection.
- Automatic stage transitions.
- RPS verification.
- Vertical speed threshold detection.
- Pitch stability verification.
- Roll stability verification.
- Altitude stability timer.
- Altitude hold delay.
- Autopilot target arrival detection.
- Flight completion state.

**Current limitations:**
- No abort system.
- No sequence timeout.
- No automatic sequence restart after completion.
- No distributed authorization system.
- No inter-microcontroller fault monitoring.

### 2.9 TELEMETRY
- HTTP telemetry transmission.
- Configurable transmission interval.
- Configurable communication port.
- Flight stage monitoring.
- Altitude monitoring.
- Vertical speed monitoring.
- RPS monitoring.
- Roll and pitch monitoring.
- Autopilot position and distance.
- Booster activation status.
- Flight function status.

Telemetry endpoint:

`/telemetry`

Default port:

`8080`

Telemetry transmission is asynchronous through `async.httpGet()`.

---

# 3. CURRENT HARDWARE INTERFACE

## 3.1 NUMBER INPUTS

| Channel | Signal |
|---|---|
| 1 | Multiplier |
| 2 | Tilt Roll Horizontal |
| 3 | Tilt Pitch |
| 4 | Target RPS |
| 5 | Real RPS |
| 6 | Altitude |
| 7 | Altitude Target |
| 8 | PID P |
| 9 | PID I |
| 10 | PID D |
| 11 | Altitude Hold Delay |
| 12 | Vertical Speed |
| 13 | AP Keyboard X |
| 14 | AP Keyboard Y |
| 15 | AP Sensor X |
| 16 | AP Sensor Y |
| 17 | AP Compass |
| 18 | AP Steering |
| 19 | AP Cutoff |
| 20 | AP Deadzone |
| 21 | AP Smoothing |
| 22 | Vertical Speed Target |
| 23 | Tilt Roll Vertical |

## 3.2 BOOLEAN INPUTS

| Channel | Signal |
|---|---|
| 1 | START |

## 3.3 NUMBER OUTPUTS

| Channel | Signal |
|---|---|
| 1 | Roll Left |
| 2 | Roll Right |
| 3 | Elevator Left |
| 4 | Elevator Right |
| 5 | Spoiler |
| 6 | AP Yaw |
| 7 | AP Distance |
| 8 | AP My X |
| 9 | AP My Y |
| 10 | AP Target X |
| 11 | AP Target Y |

## 3.4 BOOLEAN OUTPUTS

| Channel | Signal |
|---|---|
| 1 | Main Booster |
| 5 | Booster North |
| 6 | Booster East |
| 7 | Booster South |
| 8 | Booster West |
| 9 | Acceleration Booster |
| 32 | Start Status |

---

# 4. SYSTEM CONFIGURATION

## 4.1 FLIGHT CONTROL

| Parameter | Default |
|---|---:|
| Tick Rate | 60 Hz |
| Altitude Gain | 0.35 |
| Maximum Climb Speed | 105 |
| Maximum Descent Speed | 125 |
| Control Minimum | -0.45 |
| Control Maximum | 0.45 |
| Integral Limit | 10 |
| Control Rate | 0.005 |

## 4.2 STABILITY MARGINS

| Parameter | Default |
|---|---:|
| RPS Margin | 1 |
| Altitude Margin | 15 |
| Roll Margin | 0.005 |
| Pitch Margin | 0.08 |
| Pitch Stability Trigger | 0.01 |

## 4.3 STABILITY TIMERS

| Parameter | Default |
|---|---:|
| Altitude Stable Time | 2 seconds |
| Roll Stable Time | 0.2 seconds |

## 4.4 BOOSTER CONFIGURATION

| Parameter | Default |
|---|---:|
| Directional Booster Pulse | 0.2 seconds |
| Bottom Booster Detection Zone | 25 / 360 turns |
| Minimum Sensor Magnitude | 0.001 |

## 4.5 TELEMETRY CONFIGURATION

| Parameter | Default |
|---|---:|
| Enabled | True |
| Port | 8080 |
| Interval | 6 ticks |

---

# 5. PLANNED MODULAR ARCHITECTURE

**Future Development — Distributed Control Architecture**

The long-term architecture will separate the existing systems into independent Lua microcontrollers.

Each microcontroller has:

- 32 numerical inputs.
- 32 numerical outputs.
- 32 boolean inputs.
- 32 boolean outputs.

The distributed architecture will use independent subsystem controllers coordinated by a central authority.

## 5.1 LEVEL 01 — CENTRAL AUTHORITY

### MC01 — SYSTEM AUTHORITY

Central authorization and system coordination.

Responsibilities:
- Global system permissions.
- System authorization.
- Operational priorities.
- Emergency state management.
- Maintenance mode.
- Critical fault coordination.
- Controller availability monitoring.
- Global operating modes.

System Authority will authorize operations but will not directly control subsystem actuators.

## 5.2 LEVEL 02 — MISSION MANAGEMENT

### MC02 — FLIGHT SEQUENCE

Independent flight sequence controller.

Responsibilities:
- Flight stages.
- Stage transitions.
- Sequence timers.
- Flight conditions.
- Function activation requests.
- Sequence completion.
- Flight progression.

### MC03 — MISSION MANAGEMENT

Future mission coordination system.

Responsibilities:
- Mission modes.
- Mission selection.
- Navigation requests.
- Operational modes.
- Mission priorities.
- System coordination.

## 5.3 LEVEL 03 — SYSTEM CONTROLLERS

### MC04 — FLIGHT CONTROL

Responsibilities:
- Roll Stabilizer.
- Altitude Hold.
- PID controller.
- Elevator control.
- Aileron control.

### MC05 — AUTOPILOT

Responsibilities:
- Coordinate navigation.
- Target heading.
- Compass integration.
- Yaw control.
- Distance calculation.
- Navigation smoothing.

### MC06 — PROPULSION

Responsibilities:
- Main Booster.
- Directional Boosters.
- Bottom Booster System.
- Acceleration Boosters.
- Booster pulse management.

### MC07 — ENGINE MANAGEMENT

Responsibilities:
- Engine monitoring.
- RPS management.
- Engine readiness.
- Engine status.
- Engine fault reporting.

### MC08 — DEFENSE SYSTEM

Future independent defensive systems controller.

Responsibilities:
- System availability.
- Authorization management.
- Operating states.
- Fault monitoring.
- Local interlocks.

### MC09 — INHIBITOR SYSTEM

Future subsystem inhibition controller.

Responsibilities:
- System inhibition.
- Operational restrictions.
- Maintenance locks.
- Activation interlocks.
- Incompatible operation prevention.
- Inhibition status reporting.

### MC10 — ENERGY MANAGEMENT

Responsibilities:
- Energy monitoring.
- Battery status.
- Energy distribution.
- Consumer priorities.
- Energy availability.
- Power fault reporting.

### MC11 — SENSOR MANAGEMENT

Responsibilities:
- Sensor validation.
- Sensor availability.
- Invalid signal detection.
- Out-of-range detection.
- Sensor fault reporting.
- Validated sensor data distribution.

## 5.4 LEVEL 04 — TELEMETRY AND DIAGNOSTICS

### MC12 — TELEMETRY & DIAGNOSTICS

Responsibilities:
- HTTP communication.
- Flight telemetry.
- Controller status monitoring.
- Fault reporting.
- Heartbeat monitoring.
- System diagnostics.
- Operational logging.

Telemetry must remain independent from flight control and must never be required for normal aircraft operation.

---

# 6. DISTRIBUTED COMMUNICATION PROTOCOL

**Protocol Name:** YR02 SYSTEM COMMUNICATION PROTOCOL  
**Abbreviation:** YSCP  
**Planned Version:** 1.0

All microcontrollers will use standardized communication interfaces.

## 6.1 COMMUNICATION PRINCIPLES

Every controller will distinguish:

**REQUEST**
A subsystem requests permission to perform an operation.

**GRANT**
System Authority authorizes or denies the requested operation.

**COMMAND**
An authorized controller receives an instruction to execute a function.

**STATUS**
The subsystem reports its actual operating condition.

A request does not mean that an operation is active.

A grant does not mean that an operation has successfully executed.

An active status must only be reported when the subsystem confirms actual operation.

## 6.2 STANDARD BOOLEAN INPUTS

| Channel | Signal |
|---|---|
| 1 | System Grant |
| 2 | Emergency Active |
| 3 | Maintenance Active |
| 4 | Function Enable |
| 5 | Reset Request |
| 6 | Manual Override |

## 6.3 STANDARD BOOLEAN OUTPUTS

| Channel | Signal |
|---|---|
| 1 | System Ready |
| 2 | System Active |
| 3 | System Fault |
| 4 | System Inhibited |
| 5 | Emergency State |
| 6 | Command Accepted |

## 6.4 STANDARD NUMERICAL OUTPUTS

| Channel | Signal |
|---|---|
| 1 | System State |
| 2 | System Heartbeat |
| 3 | Fault Code |
| 4 | Active Function ID |

Additional subsystem-specific signals will use reserved channels.

## 6.5 STANDARD SYSTEM STATES

| Code | State |
|---:|---|
| 0 | OFFLINE |
| 1 | STANDBY |
| 2 | REQUESTING |
| 3 | ACTIVE |
| 4 | INHIBITED |
| 5 | FAULT |
| 6 | EMERGENCY |

## 6.6 HEARTBEAT MONITORING

Every controller will provide a numerical heartbeat counter.

System Authority will monitor changes in heartbeat values to detect controllers that stop updating their outputs.

Heartbeat monitoring will include:
- Update detection.
- Communication timeout.
- Controller availability.
- Fault reporting.

Loss of communication must cause the affected subsystem to enter its predefined safe state.

---

# 7. SYSTEM AUTHORITY AND PRIORITIES

The planned priority hierarchy is:

| Priority | Category |
|---:|---|
| 100 | SAFETY |
| 90 | EMERGENCY |
| 80 | FLIGHT CRITICAL |
| 70 | MISSION |
| 60 | DEFENSE |
| 50 | ENERGY |
| 30 | AUXILIARY |
| 10 | TELEMETRY |

System Authority will resolve incompatible requests according to this hierarchy.

Subsystems will retain their own local interlocks and safety conditions.

No controller may override local safety restrictions through a global authorization signal.

Emergency management will use subsystem-specific safe-state policies rather than indiscriminately disabling all controllers.

---

# 8. FUTURE DEVELOPMENT ROADMAP

| Phase | Development |
|---:|---|
| 1 | YSCP Communication Protocol |
| 2 | MC01 System Authority |
| 3 | MC02 Flight Sequence |
| 4 | MC04 Flight Control |
| 5 | MC05 Autopilot |
| 6 | MC06 Propulsion |
| 7 | MC12 Telemetry |
| 8 | MC07 Engine Management |
| 9 | MC11 Sensor Management |
| 10 | MC09 Inhibitor System |
| 11 | MC08 Defense System |
| 12 | MC10 Energy Management |
| 13 | MC03 Mission Management |
| 14 | Complete System Integration |

Each development phase must be tested independently before integration into the complete aircraft.

---

# 9. PROJECT DEVELOPMENT RULES

The following rules apply to all future YR-02 development.

1. Every microcontroller must have an independent Lua script.
2. No subsystem may directly modify another subsystem's internal state.
3. System Authority manages permissions, not actuator execution.
4. Flight Sequence manages mission stages, not subsystem algorithms.
5. Every actuator must have a single designated controller.
6. All communication channels must be documented.
7. All controllers must implement standardized system states.
8. Heartbeat monitoring must be supported.
9. Critical systems must have local safety interlocks.
10. Telemetry must never interfere with normal flight operation.
11. Existing functionality must be preserved during migration unless explicitly redesigned.
12. New features must not silently change existing channel assignments.
13. Communication protocol changes must be versioned.
14. Every subsystem must be independently testable.

---

# 10. PROJECT DIRECTORY

Proposed development structure:

    OAI_MIZUSHIMA_YR02/
    |
    |-- 01_CORE/
    |   |-- MC01_SYSTEM_AUTHORITY.lua
    |   |-- MC02_FLIGHT_SEQUENCE.lua
    |   |-- MC03_MISSION_MANAGEMENT.lua
    |
    |-- 02_FLIGHT/
    |   |-- MC04_FLIGHT_CONTROL.lua
    |   |-- MC05_AUTOPILOT.lua
    |
    |-- 03_PROPULSION/
    |   |-- MC06_PROPULSION.lua
    |   |-- MC07_ENGINE_MANAGEMENT.lua
    |
    |-- 04_SYSTEMS/
    |   |-- MC08_DEFENSE_SYSTEM.lua
    |   |-- MC09_INHIBITOR_SYSTEM.lua
    |   |-- MC10_ENERGY_MANAGEMENT.lua
    |   |-- MC11_SENSOR_MANAGEMENT.lua
    |
    |-- 05_TELEMETRY/
    |   |-- MC12_TELEMETRY.lua
    |
    |-- 06_DOCUMENTATION/
        |-- YR02_INPUT_MAP.md
        |-- YR02_OUTPUT_MAP.md
        |-- YR02_COMMUNICATION.md
        |-- YR02_SYSTEM_REGISTRY.md

---

# 11. VERSION MANAGEMENT

Current implemented version:

**YR-02 v13.1.0**

Planned architecture:

**YR-02 Distributed Architecture 1.0**

The distributed architecture is a development target and does not represent functionality already implemented in version 13.1.0.

Each microcontroller will maintain its own version number.

The communication protocol will also maintain an independent version number.

---

# 12. PROJECT OBJECTIVE

The ultimate objective is to transform the OAI MIZUSHIMA YR-02 from a single-file flight control system into a fully distributed modular aircraft management architecture.

The system must remain expandable, maintainable and independently testable.

New systems must be incorporable without requiring changes to unrelated controllers.

**OAI MIZUSHIMA YR-02**

*MODULAR FLIGHT CONTROL*  
*DISTRIBUTED SYSTEM ARCHITECTURE*  
*INDEPENDENT SUBSYSTEMS — CENTRAL AUTHORITY*

---

END OF README