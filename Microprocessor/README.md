# OAI MIZUSHIMA YR-02
## Modular Flight Control System

**System Version:** 14.0  
**Migration Source:** V13.1.0  
**Platform:** Stormworks: Build and Rescue  
**Architecture:** Modular Microcontroller Flight Control System  
**Programming Language:** Lua

---

# 1. PROJECT OVERVIEW

The **OAI MIZUSHIMA YR-02** is a modular flight control system designed for Stormworks.

The project is based on the migration of the original V13.1.0 flight control logic into a modular architecture, with the objective of improving maintainability, expanding functionality and simplifying future development without changing the original flight behavior.

The system separates flight sequence management, master control, flight stabilization, altitude control, navigation, propulsion and telemetry into independent microcontrollers.

Each microcontroller has a clearly defined responsibility and communicates with other modules through Composite connections.

The system is designed to preserve the original control calculations and operating logic wherever possible.

## Main objectives

- Preserve the original V13.1.0 flight behavior.
- Divide the system into independent functional modules.
- Simplify troubleshooting and maintenance.
- Allow individual modules to be upgraded independently.
- Reduce unnecessary dependencies between controllers.
- Keep physical sensors connected directly to the controllers that require them.
- Exchange only the necessary information between microcontrollers.
- Provide optional HTTP telemetry.
- Create a foundation for future flight control improvements.

---

# 2. SYSTEM ARCHITECTURE

The system consists of seven microcontrollers.

| MC | Module | Main responsibility |
|---|---|---|
| MC01 | FLIGHT SEQUENCE | Mission logic and flight phases |
| MC02 | MASTER CONTROL | Command distribution and general management |
| MC03 | FLIGHT CONTROL | Roll stabilization |
| MC04 | ALTITUDE CONTROL | Altitude PID and elevator control |
| MC05 | NAVIGATION | Autopilot navigation and yaw control |
| MC06 | PROPULSION | Boosters and spoiler management |
| MC07 | TELEMETRY | Flight monitoring and HTTP transmission |

MC07 is optional. The main flight control system can operate without it.

## Architecture principles

### Independent physical sensors

Sensors are connected directly to the microcontroller that needs their measurements.

For example:

- MC01 reads the sensors required for flight sequence transitions.
- MC03 reads its own roll sensor.
- MC04 reads altitude and vertical speed.
- MC05 reads position and compass information.
- MC06 reads the tilt sensors required for bottom booster detection.
- MC07 receives the measurements required for telemetry.

This avoids unnecessary dependence on a centralized sensor controller.

### Intermodule communication

Microcontrollers exchange information through Composite connections.

The architecture does not require all signals to pass through MC02.

MC02 distributes general flight commands, while other modules can exchange the specific information they need directly.

### Stormworks limitations

Each microcontroller supports:

- 32 Boolean inputs.
- 32 Number inputs.
- 32 Boolean outputs.
- 32 Number outputs.

Boolean and Number channels are separate.

The architecture must respect these limits when assigning Composite channels.

---

# 3. MODULE DESCRIPTIONS

## MC01 — FLIGHT SEQUENCE

**Version:** 1.0.0

**Responsibility:** Mission management and automatic flight sequence execution.

MC01 is the main mission logic controller.

It manages the ten flight sequence stages and determines when the aircraft advances from one stage to another.

### Main functions

- Start sequence management.
- Flight stage progression.
- RPS threshold monitoring.
- Vertical speed monitoring.
- Pitch stability detection.
- Altitude hold activation.
- Altitude stability monitoring.
- Roll stability monitoring.
- Autopilot activation.
- Flight completion detection.
- Directional booster activation request.

### Physical sensor inputs

| Signal | Source |
|---|---|
| START | Start switch |
| REAL_RPS | RPS sensor |
| ALTITUDE | Altitude sensor |
| ALTITUDE_TARGET | Target altitude configuration |
| TILT_ROLL_HORIZ | Tilt sensor |
| TILT_PITCH | Tilt sensor |
| VERTICAL_SPEED | Vertical speed sensor |
| AP_MY_X | MC05 output 3 |
| AP_MY_Y | MC05 output 4 |
| AP_TARGET_X | MC05 output 5 |
| AP_TARGET_Y | MC05 output 6 |

The exact MC01 physical input channel allocation must follow the final MC01 script.

### Outputs

**Boolean outputs**

| Channel | Signal | Destination |
|---|---|---|
| 1 | RUNNING | MC02 input 1 |
| 2 | COMPLETED | MC02 input 2 |
| 3 | ROLL_STABILIZER | MC02 input 3 |
| 4 | MAIN_BOOSTER | MC02 input 4 |
| 5 | DIRECTIONAL_BOOSTER_TRIGGER | MC02 input 5 |
| 6 | BOTTOM_BOOSTERS | MC02 input 6 |
| 7 | ACCELERATION_BOOSTERS | MC02 input 7 |
| 8 | ALTITUDE_HOLD | MC02 input 8 |
| 9 | AUTOPILOT | MC02 input 9 |
| 10 | START_STATUS | MC02 input 10 |

**Number outputs**

| Channel | Signal | Destination |
|---|---|---|
| 1 | SEQUENCE_STATE | MC02 input 1 |
| 2 | SEQUENCE_TIMER | MC02 input 2 |
| 3 | SPOILER | MC02 input 3 |
| 4 | ALTITUDE_STABLE_TIMER | MC02 input 4 |
| 5 | ROLL_STABLE_TIMER | MC02 input 5 |

---

## MC02 — MASTER CONTROL

**Version:** 1.0.0

**Responsibility:** Command distribution and general management.

MC02 receives the general flight commands from MC01 and distributes them to the appropriate controllers.

It does not perform flight stabilization, navigation or altitude calculations.

### Main functions

- Receive flight sequence commands.
- Distribute Boolean control signals.
- Distribute general numerical information.
- Provide a consistent interface for downstream controllers.

### Inputs

**Boolean inputs**

| Channel | Signal | Source |
|---|---|---|
| 1 | RUNNING | MC01 output 1 |
| 2 | COMPLETED | MC01 output 2 |
| 3 | ROLL_STABILIZER | MC01 output 3 |
| 4 | MAIN_BOOSTER | MC01 output 4 |
| 5 | DIRECTIONAL_BOOSTER_TRIGGER | MC01 output 5 |
| 6 | BOTTOM_BOOSTERS | MC01 output 6 |
| 7 | ACCELERATION_BOOSTERS | MC01 output 7 |
| 8 | ALTITUDE_HOLD | MC01 output 8 |
| 9 | AUTOPILOT | MC01 output 9 |
| 10 | START_STATUS | MC01 output 10 |

**Number inputs**

| Channel | Signal | Source |
|---|---|---|
| 1 | SEQUENCE_STATE | MC01 output 1 |
| 2 | SEQUENCE_TIMER | MC01 output 2 |
| 3 | SPOILER | MC01 output 3 |
| 4 | ALTITUDE_STABLE_TIMER | MC01 output 4 |
| 5 | ROLL_STABLE_TIMER | MC01 output 5 |

### Outputs

MC02 uses a direct passthrough arrangement.

Its output channel numbers and values are identical to its input channel numbers.

| Output | Destination |
|---|---|
| Boolean 3 — ROLL_STABILIZER | MC03 input Boolean 3 |
| Boolean 8 — ALTITUDE_HOLD | MC04 input Boolean 8 |
| Boolean 9 — AUTOPILOT | MC05 input Boolean 9 |
| Boolean 4 — MAIN_BOOSTER | MC06 input Boolean 1 |
| Boolean 5 — DIRECTIONAL_BOOSTER_TRIGGER | MC06 input Boolean 2 |
| Boolean 6 — BOTTOM_BOOSTERS | MC06 input Boolean 3 |
| Boolean 7 — ACCELERATION_BOOSTERS | MC06 input Boolean 4 |
| Number 3 — SPOILER | MC06 input Number 1 |

Other MC02 outputs remain available for monitoring and future system functions.

---

## MC03 — FLIGHT CONTROL

**Version:** 1.0.0

**Responsibility:** Roll stabilization control.

MC03 manages the aircraft's roll stabilization.

It reproduces the original roll control calculation without introducing additional filtering or control algorithms.

### Inputs

| Channel | Type | Signal | Source |
|---|---|---|---|
| 1 | Number | ROLL_MULTIPLIER | Configuration input |
| 2 | Number | TILT_ROLL_HORIZ | Physical tilt sensor |
| 3 | Boolean | ROLL_STABILIZER | MC02 Boolean output 3 |

### Outputs

| Channel | Type | Signal |
|---|---|---|
| 1 | Number | ROLL_LEFT |
| 2 | Number | ROLL_RIGHT |

### Control logic

When roll stabilization is disabled, both outputs are zero.

When enabled:

- ROLL_LEFT = TILT_ROLL_HORIZ × ROLL_MULTIPLIER
- ROLL_RIGHT = -ROLL_LEFT

No independent pitch actuator controller is currently implemented in MC03.

Pitch stability is monitored by MC01 as part of the flight sequence.

---

## MC04 — ALTITUDE CONTROL

**Version:** 1.0.0

**Responsibility:** Altitude PID and elevator control.

MC04 manages altitude regulation through a PID controller.

It preserves the original altitude control behavior, including its integral protection and elevator smoothing.

### Inputs

| Channel | Type | Signal | Source |
|---|---|---|---|
| 1 | Number | ALTITUDE | Physical altitude sensor |
| 2 | Number | ALTITUDE_TARGET | Target altitude configuration |
| 3 | Number | PID_P | PID configuration |
| 4 | Number | PID_I | PID configuration |
| 5 | Number | PID_D | PID configuration |
| 6 | Number | VERTICAL_SPEED | Physical vertical speed sensor |
| 8 | Boolean | ALTITUDE_HOLD | MC02 Boolean output 8 |

### Outputs

| Channel | Type | Signal |
|---|---|---|
| 1 | Number | ELEVATOR_LEFT |
| 2 | Number | ELEVATOR_RIGHT |
| 3 | Number | DESIRED_VERTICAL_SPEED |

**Integration note:** Number output 3 is required to expose the desired vertical speed to MC07 telemetry. It must be added to the current MC04 implementation if it is not already present.

### Main control characteristics

- Fixed control tick rate: 60 Hz.
- Altitude error converted into desired vertical speed.
- Desired vertical speed limited to the original climb and descent limits.
- PID proportional, integral and derivative calculations.
- Integral anti-windup.
- Altitude control output limited to the original range.
- Elevator output smoothing.
- Integral and smoothing reset when altitude hold is disabled.

---

## MC05 — NAVIGATION

**Version:** 1.0.0

**Responsibility:** Autopilot navigation and yaw control.

MC05 calculates the direction and distance to the selected target coordinates.

It generates the yaw correction required by the autopilot and exposes the normalized target heading for MC06.

### Inputs

| Channel | Type | Signal | Source |
|---|---|---|---|
| 1 | Number | AP_KEYBOARD_X | Target coordinate input |
| 2 | Number | AP_KEYBOARD_Y | Target coordinate input |
| 3 | Number | AP_SENSOR_X | Position sensor |
| 4 | Number | AP_SENSOR_Y | Position sensor |
| 5 | Number | AP_COMPASS | Physical compass sensor |
| 6 | Number | AP_STEERING | Configuration input |
| 7 | Number | AP_CUTOFF | Configuration input |
| 8 | Number | AP_DEADZONE | Configuration input |
| 9 | Number | AP_SMOOTHING | Configuration input |
| 9 | Boolean | AUTOPILOT | MC02 Boolean output 9 |

### Outputs

| Channel | Type | Signal | Destination |
|---|---|---|---|
| 1 | Number | AP_YAW | Flight control |
| 2 | Number | AP_DISTANCE | MC07 input 11 |
| 3 | Number | AP_MY_X | MC01 / MC07 |
| 4 | Number | AP_MY_Y | MC01 / MC07 |
| 5 | Number | AP_TARGET_X | MC01 / MC07 |
| 6 | Number | AP_TARGET_Y | MC01 / MC07 |
| 7 | Number | AP_TARGET_HEADING | MC06 input 2 |

### Main functions

- Coordinate difference calculation.
- Distance to target calculation.
- Target angle calculation.
- Normalized target heading calculation.
- Yaw error calculation.
- Steering power multiplication.
- Yaw output limitation.
- Deadzone handling.
- Distance cutoff.
- Yaw smoothing.
- Autopilot enable and disable handling.

**Important:** AP_TARGET_HEADING is calculated even when the autopilot is disabled. AP_YAW is set to zero when the autopilot is disabled.

---

## MC06 — PROPULSION

**Version:** 1.0.0

**Responsibility:** Booster and spoiler management.

MC06 manages the propulsion-related outputs controlled by the flight sequence and navigation systems.

It handles the main booster, acceleration booster, directional boosters, bottom booster detection and spoiler output.

### Inputs

**Number inputs**

| Channel | Signal | Source |
|---|---|---|
| 1 | SPOILER | MC02 Number output 3 |
| 2 | TARGET_HEADING | MC05 Number output 7 |
| 3 | TILT_ROLL_HORIZ | Physical tilt sensor |
| 4 | TILT_ROLL_VERT | Physical tilt sensor |

**Boolean inputs**

| Channel | Signal | Source |
|---|---|---|
| 1 | MAIN_BOOSTER | MC02 Boolean output 4 |
| 2 | DIRECTIONAL_BOOSTER_TRIGGER | MC02 Boolean output 5 |
| 3 | BOTTOM_BOOSTERS | MC02 Boolean output 6 |
| 4 | ACCELERATION_BOOSTERS | MC02 Boolean output 7 |

### Outputs

**Number outputs**

| Channel | Signal |
|---|---|
| 1 | SPOILER |

**Boolean outputs**

| Channel | Signal |
|---|---|
| 1 | MAIN_BOOSTER |
| 2 | ACCELERATION_BOOSTER |
| 5 | NORTH_BOOSTER |
| 6 | EAST_BOOSTER |
| 7 | SOUTH_BOOSTER |
| 8 | WEST_BOOSTER |

### Directional booster selection

MC06 uses the target heading received from MC05 to select the appropriate directional booster.

The directional sectors are:

| Direction | Normalized heading sector |
|---|---|
| North | -0.125 to +0.125 |
| East | +0.125 to +0.375 |
| South | +0.375 to +0.5 and -0.5 to -0.375 |
| West | -0.375 to -0.125 |

The directional booster pulse duration is based on the original 0.2-second pulse at 60 ticks per second.

### Bottom booster detection

MC06 uses its own physical tilt sensors.

The original bottom booster detection algorithm is retained:

- Tilt magnitude calculation.
- Roll angle calculation.
- Opposite-angle normalization.
- Four directional detection zones.
- Original angular zone width.

The bottom booster outputs are combined with directional booster outputs.

**Integration item:** The original flight sequence resets its directional booster pending and pulse state when a new sequence starts. A reset mechanism between MC01 and MC06 must be finalized and tested to guarantee equivalent behavior after repeated flights.

---

## MC07 — TELEMETRY

**Version:** 1.0.0

**Responsibility:** Flight monitoring and HTTP telemetry transmission.

MC07 is an optional monitoring module.

It receives flight data from the other controllers and physical sensors, builds telemetry information and transmits it through HTTP.

### Configuration

| Parameter | Value |
|---|---|
| ENABLED | true |
| PORT | 8080 |
| INTERVAL | 6 ticks |
| Nominal transmission rate | 10 transmissions per second at 60 Hz |

### Number inputs

| Channel | Signal | Source |
|---|---|---|
| 1 | SEQUENCE_STATE | MC02 Number output 1 |
| 2 | SEQUENCE_TIMER | MC02 Number output 2 |
| 3 | ALTITUDE | Physical altitude sensor |
| 4 | ALTITUDE_TARGET | Target altitude configuration |
| 5 | VERTICAL_SPEED | Physical vertical speed sensor |
| 6 | DESIRED_VERTICAL_SPEED | MC04 Number output 3 |
| 7 | REAL_RPS | Physical RPS sensor |
| 8 | TARGET_RPS | Target RPS configuration |
| 9 | TILT_ROLL_HORIZ | Physical tilt sensor |
| 10 | TILT_PITCH | Physical tilt sensor |
| 11 | AP_DISTANCE | MC05 Number output 2 |
| 12 | AP_YAW | MC05 Number output 1 |
| 13 | AP_MY_X | MC05 Number output 3 |
| 14 | AP_MY_Y | MC05 Number output 4 |
| 15 | AP_TARGET_X | MC05 Number output 5 |
| 16 | AP_TARGET_Y | MC05 Number output 6 |
| 17 | SPOILER | MC02 Number output 3 |

### Boolean inputs

| Channel | Signal | Source |
|---|---|---|
| 1 | RUNNING | MC02 Boolean output 1 |
| 2 | COMPLETED | MC02 Boolean output 2 |
| 3 | AUTOPILOT | MC02 Boolean output 9 |
| 4 | MAIN_BOOSTER | MC02 Boolean output 4 |
| 5 | ALTITUDE_HOLD | MC02 Boolean output 8 |
| 6 | ROLL_STABILIZER | MC02 Boolean output 3 |
| 7 | ACCELERATION_BOOSTERS | MC02 Boolean output 7 |
| 8 | NORTH_BOOSTER | MC06 Boolean output 5 |
| 9 | EAST_BOOSTER | MC06 Boolean output 6 |
| 10 | SOUTH_BOOSTER | MC06 Boolean output 7 |
| 11 | WEST_BOOSTER | MC06 Boolean output 8 |

### Telemetry information

MC07 reports:

- Flight stage and sequence state.
- Flight status.
- Sequence timer.
- Current altitude and target altitude.
- Altitude error.
- Vertical speed and desired vertical speed.
- Vertical speed error.
- Real and target RPS.
- Roll and pitch measurements.
- Autopilot status.
- Autopilot distance and yaw.
- Current and target coordinates.
- Main booster status.
- Altitude hold status.
- Roll stabilization status.
- Acceleration booster status.
- Directional booster status.
- Spoiler value.

### HTTP endpoint

The original telemetry endpoint format is retained:

`/telemetry?...`

The HTTP request is sent using Stormworks Lua HTTP functionality:

`async.httpGet(8080, url)`

The telemetry module is not required for the aircraft's flight control functions.

---

# 4. INTERMODULE CONNECTION DIAGRAM

The general architecture is:

```text
                 PHYSICAL SENSORS
                        |
                        v
              +-------------------+
              | MC01              |
              | FLIGHT SEQUENCE   |
              +-------------------+
                        |
                 Composite data
                        |
                        v
              +-------------------+
              | MC02              |
              | MASTER CONTROL    |
              +-------------------+
                 |      |      |
          _______|      |______|________
         |              |               |
         v              v               v
    +---------+    +---------+     +---------+
    | MC03    |    | MC04    |     | MC05    |
    | FLIGHT  |    | ALTITUDE|     | NAV     |
    | CONTROL |    | CONTROL |     |IGATION  |
    +---------+    +---------+     +---------+
                                      |
                               TARGET_HEADING
                                      |
                                      v
                                +-----------+
                                | MC06      |
                                | PROPULSION|
                                +-----------+

       MC01 / MC02 / MC04 / MC05 / MC06
                        |
                        v
                 +-------------+
                 | MC07        |
                 | TELEMETRY   |
                 +-------------+
                        |
                        v
                   HTTP SERVER
                    PORT 8080
```

The diagram represents logical signal relationships, not a requirement to route every signal through MC02.

---

# 5. MASTER CONNECTION REFERENCE

This section summarizes the most important Composite connections.

| Source | Output | Destination | Input |
|---|---|---|---|
| MC01 | Boolean 1 RUNNING | MC02 | Boolean 1 |
| MC01 | Boolean 2 COMPLETED | MC02 | Boolean 2 |
| MC01 | Boolean 3 ROLL_STABILIZER | MC02 | Boolean 3 |
| MC01 | Boolean 4 MAIN_BOOSTER | MC02 | Boolean 4 |
| MC01 | Boolean 5 DIRECTIONAL_BOOSTER_TRIGGER | MC02 | Boolean 5 |
| MC01 | Boolean 6 BOTTOM_BOOSTERS | MC02 | Boolean 6 |
| MC01 | Boolean 7 ACCELERATION_BOOSTERS | MC02 | Boolean 7 |
| MC01 | Boolean 8 ALTITUDE_HOLD | MC02 | Boolean 8 |
| MC01 | Boolean 9 AUTOPILOT | MC02 | Boolean 9 |
| MC01 | Boolean 10 START_STATUS | MC02 | Boolean 10 |
| MC01 | Number 1 SEQUENCE_STATE | MC02 | Number 1 |
| MC01 | Number 2 SEQUENCE_TIMER | MC02 | Number 2 |
| MC01 | Number 3 SPOILER | MC02 | Number 3 |
| MC01 | Number 4 ALTITUDE_STABLE_TIMER | MC02 | Number 4 |
| MC01 | Number 5 ROLL_STABLE_TIMER | MC02 | Number 5 |
| MC02 | Boolean 3 ROLL_STABILIZER | MC03 | Boolean 3 |
| MC02 | Boolean 8 ALTITUDE_HOLD | MC04 | Boolean 8 |
| MC02 | Boolean 9 AUTOPILOT | MC05 | Boolean 9 |
| MC02 | Boolean 4 MAIN_BOOSTER | MC06 | Boolean 1 |
| MC02 | Boolean 5 DIRECTIONAL_BOOSTER_TRIGGER | MC06 | Boolean 2 |
| MC02 | Boolean 6 BOTTOM_BOOSTERS | MC06 | Boolean 3 |
| MC02 | Boolean 7 ACCELERATION_BOOSTERS | MC06 | Boolean 4 |
| MC02 | Number 3 SPOILER | MC06 | Number 1 |
| MC05 | Number 7 AP_TARGET_HEADING | MC06 | Number 2 |

---

# 6. TELEMETRY CONNECTION REFERENCE

MC07 receives information from several modules.

| MC07 input | Source |
|---|---|
| Number 1–5 | MC02 outputs 1–5 |
| Number 6 | MC04 Number output 3 |
| Number 7–10 | Physical sensors/configuration |
| Number 11–16 | MC05 outputs 2–6 |
| Number 17 | MC02 Number output 3 |
| Boolean 1–9 | MC02 outputs 1–9 |
| Boolean 10–11 | MC06 outputs 7–8 |

The physical sensor and configuration inputs are connected directly to MC07 where required.

---

# 7. FLIGHT CONTROL CAPABILITIES

The modular system is designed to support the following capabilities:

### Automatic flight sequence

The flight sequence controller manages the ten original mission stages and their transition conditions.

### Roll stabilization

The flight control module provides roll correction using the original roll multiplier calculation.

### Altitude hold

The altitude controller maintains the target altitude using the original PID logic.

### Autopilot navigation

The navigation controller calculates target distance, heading and yaw correction from current and target coordinates.

### Directional propulsion

The propulsion controller selects directional boosters according to the target heading and manages the original booster activation logic.

### Bottom booster detection

The propulsion controller identifies the aircraft's bottom orientation through its own tilt sensors.

### Flight telemetry

The optional telemetry module provides remote flight monitoring through HTTP.

---

# 8. DEVELOPMENT AND EXPANSION POSSIBILITIES

The modular architecture provides a foundation for future improvements.

Potential developments include:

- Additional flight modes.
- Improved navigation logic.
- Additional flight stability functions.
- Expanded telemetry information.
- Flight event logging.
- System diagnostics.
- Booster activation monitoring.
- Additional safety interlocks.
- Independent module testing.
- Expanded mission sequence logic.

Future modifications should preserve existing functionality unless a deliberate change is approved.

Each module should be tested independently before full system integration.

---

# 9. VERSIONING POLICY

The system follows two version levels.

**System version:** Represents the complete aircraft control architecture.

**Module version:** Represents an individual microcontroller implementation.

Current system version:

`SYSTEM VERSION: 14.0`

Every module uses its own version declaration:

`VERSION: 1.0.0`

Every module must include the standard project header:

```lua
-- OAI MIZUSHIMA YR-02
-- MC 0X: MODULE NAME
-- VERSION: 1.0.0
-- SYSTEM VERSION: 14.0
-- MIGRATED FROM v13.1.0
--
--
-- RESPONSIBILITY:
--   Module responsibility
```

---

# 10. INTEGRATION STATUS AND VALIDATION

The architecture and module interfaces have been drafted, but the complete system must still be validated in Stormworks.

The following items require particular attention:

1. Confirm the final physical input channel assignments of MC01.
2. Add and verify MC04 Number output 3 for desired vertical speed.
3. Confirm MC05 Number output 7 is connected to MC06 Number input 2.
4. Finalize the directional booster reset mechanism between MC01 and MC06.
5. Verify the timing of directional booster trigger and pulse behavior across microcontrollers.
6. Confirm all Composite connections and channel assignments.
7. Test all ten flight sequence stages.
8. Compare the modular system against the original V13.1.0 behavior.
9. Verify telemetry transmission and HTTP reception.
10. Test repeated flight starts to ensure internal states are correctly reset.

**Important:** The migration is intended to preserve the original V13.1.0 behavior. No module should be considered fully validated until its behavior has been tested in-game.

---

# 11. PROJECT DESIGN PHILOSOPHY

The OAI MIZUSHIMA YR-02 is built around three principles:

**Modularity:** Each microcontroller has a clearly defined responsibility.

**Preservation:** Original calculations and control behavior must remain unchanged unless an intentional modification is approved.

**Expandability:** New capabilities should be integrated without unnecessarily affecting existing modules.

The objective is not simply to divide a large script into smaller scripts.

The objective is to build a maintainable, expandable and reliable flight control architecture for Stormworks.

---

**OAI MIZUSHIMA YR-02**  
*Modular Flight Control System — Version 14.0*