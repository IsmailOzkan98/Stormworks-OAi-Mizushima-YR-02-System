# OAI MIZUSHIMA YR-02
## Modular Flight Control

![Stormworks](https://img.shields.io/badge/Game-Stormworks-blue)
![Language](https://img.shields.io/badge/Language-Lua-blue)
![Version](https://img.shields.io/badge/Version-12.0-green)
![Status](https://img.shields.io/badge/Status-In%20Development-orange)

**OAI MIZUSHIMA YR-02 – Modular Flight Control** is an automated flight control system developed for Stormworks: Build and Rescue.

The system integrates multiple flight control functions into a single Lua script, managing aircraft stabilization, altitude control, autonomous navigation and automated flight sequencing.

---

## 1. Project Overview

The YR-02 flight control system is designed to automate the aircraft's flight operations through a sequence of sensor-based conditions.

The system combines three primary control functions:

- **Roll Stabilizer:** Automatic roll stabilization.
- **Altitude Hold:** Automatic altitude and vertical speed control.
- **Autopilot:** Autonomous coordinate navigation and heading correction.

These systems operate alongside an automated flight sequence responsible for managing the aircraft's propulsion and control systems.

### Main Characteristics

| Feature | Description |
|---|---|
| Architecture | Single File |
| Programming Language | Lua |
| Platform | Stormworks |
| Tick Rate | 60 Hz (configured reference) |
| Flight Control | Automated |
| Navigation | Coordinate-based |
| Stabilization | Roll stabilization |
| Altitude Control | PID-based vertical speed control |
| Flight Sequence | Automatic |
| Diagnostics | Integrated telemetry |

---

## 2. Flight Control Systems

### 2.1 Roll Stabilizer

Controls aircraft roll using the measured roll tilt and a configurable multiplier.

**Functions:**
- Roll compensation.
- Left and right aileron control.
- Automatic activation through the flight sequence.

### 2.2 Altitude Hold

Maintains the aircraft at a configurable target altitude.

The controller uses a cascaded control architecture:

**Outer Loop – Altitude Control**
- Calculates altitude error.
- Determines desired vertical speed.
- Applies climb and descent limits.

**Inner Loop – Vertical Speed Control**
- Calculates vertical speed error.
- Applies PID control.
- Implements integral limiting (anti-windup).
- Applies derivative compensation.
- Smooths elevator output.

### 2.3 Autopilot

Provides autonomous navigation using current and target coordinates.

**Functions:**
- Coordinate difference calculation.
- Distance calculation.
- Target heading calculation.
- Compass-based heading correction.
- Steering power adjustment.
- Configurable deadzone.
- Yaw smoothing.
- Target arrival detection.

The autopilot stops applying steering corrections when the target enters the configured cutoff distance.

---

## 3. Flight Sequence

The automated flight sequence consists of eight programmed stages.

| Step | Stage | Description |
|---|---|---|
| 01 | ENGINE_CHECK | Checks engine RPS and activates spoiler. |
| 02 | ROLL_STABILIZER | Activates roll stabilization. |
| 03 | MAIN_BOOSTER | Activates the main booster and monitors vertical speed. |
| 04 | DIRECTIONAL_BOOSTER | Selects and activates a directional booster. |
| 05 | ACCELERATION_BOOSTERS | Activates acceleration boosters. |
| 06 | ALTITUDE_HOLD | Activates automatic altitude control. |
| 07 | AUTOPILOT | Activates autonomous navigation. |
| 08 | AUTOPILOT_COMPLETE | Disables autopilot and completes the sequence. |

### Sequence Activation

The flight sequence starts when the `START` input detects a rising edge.

Once activated, each stage waits for its corresponding condition before advancing.

### Sequence Characteristics

- Automatic stage progression.
- Sensor-based conditions.
- Configurable condition margins.
- Altitude stability verification.
- Directional booster pulse control.
- Automatic completion.

**Current implementation limitations:**
- No abort functionality.
- No timeout functionality.

A stage can therefore remain active indefinitely if its transition condition is never satisfied.

---

## 4. Actuator Configuration

The system controls the following actuators:

| Actuator | Function |
|---|---|
| Main Booster | Main propulsion |
| North Booster | Directional propulsion |
| East Booster | Directional propulsion |
| South Booster | Directional propulsion |
| West Booster | Directional propulsion |
| Acceleration Boosters | Additional acceleration |
| Spoiler | Aerodynamic control |
| Left Aileron | Roll control |
| Right Aileron | Roll control |
| Left Elevator | Pitch control |
| Right Elevator | Pitch control |

---

## 5. Input Configuration

### Number Inputs

| Channel | Input | Description |
|---:|---|---|
| 1 | MULTIPLIER | Roll control multiplier |
| 2 | TILT_ROLL | Roll sensor |
| 3 | TILT_PITCH | Pitch sensor |
| 4 | TARGET_RPS | Target engine RPS |
| 5 | REAL_RPS | Actual engine RPS |
| 6 | ALTITUDE | Current altitude |
| 7 | ALTITUDE_TARGET | Target altitude |
| 8 | PID_P | Proportional gain |
| 9 | PID_I | Integral gain |
| 10 | PID_D | Derivative gain |
| 11 | ALT_HOLD_DELAY | Altitude hold activation delay |
| 12 | VERTICAL_SPEED | Current vertical speed |
| 13 | AP_KEYBOARD_X | Target X coordinate |
| 14 | AP_KEYBOARD_Y | Target Y coordinate |
| 15 | AP_SENSOR_X | Current X coordinate |
| 16 | AP_SENSOR_Y | Current Y coordinate |
| 17 | AP_COMPASS | Compass heading |
| 18 | AP_STEERING | Steering power |
| 19 | AP_CUTOFF | Target cutoff distance |
| 20 | AP_DEADZONE | Heading deadzone |
| 21 | AP_SMOOTHING | Yaw smoothing |
| 22 | VERTICAL_SPEED_TARGET | Target vertical speed threshold |

### Boolean Inputs

| Channel | Input | Description |
|---:|---|---|
| 1 | START | Flight sequence activation |

---

## 6. Output Configuration

### Number Outputs

| Channel | Output | Description |
|---:|---|---|
| 1 | ROLL_LEFT | Left aileron control |
| 2 | ROLL_RIGHT | Right aileron control |
| 3 | ELEVATOR_LEFT | Left elevator control |
| 4 | ELEVATOR_RIGHT | Right elevator control |
| 5 | SPOILER | Spoiler control |
| 6 | AP_YAW | Autopilot yaw output |
| 7 | AP_DISTANCE | Distance to target |
| 8 | AP_MY_X | Current X coordinate |
| 9 | AP_MY_Y | Current Y coordinate |
| 10 | AP_TARGET_X | Target X coordinate |
| 11 | AP_TARGET_Y | Target Y coordinate |
| 13 | VERTICAL_SPEED | Current vertical speed |
| 14 | DESIRED_SPEED | Desired vertical speed |
| 15 | SPEED_ERROR | Vertical speed error |
| 16 | ALT_CONTROL | Altitude controller output |
| 17 | ALTITUDE | Current altitude |
| 18 | ALTITUDE_TARGET | Target altitude |
| 19 | ALTITUDE_ERROR | Altitude error |

### Boolean Outputs

| Channel | Output | Description |
|---:|---|---|
| 1 | MAIN_BOOSTER | Main booster activation |
| 2 | ALT_HOLD | Altitude hold status |
| 3 | AP_TARGET_REACHED | Target reached |
| 4 | AP_ENABLED | Autopilot status |
| 5 | BOOSTER_NORTH | North booster activation |
| 6 | BOOSTER_EAST | East booster activation |
| 7 | BOOSTER_SOUTH | South booster activation |
| 8 | BOOSTER_WEST | West booster activation |
| 9 | ACCELERATION_BOOSTER | Acceleration booster activation |
| 32 | START_STATUS | Start input status |

**Additional note:** `ROLL_STABILIZER` is currently assigned to Boolean channel 0 in the source code. However, the optional output validation only accepts channels 1–32, so this status is not currently written.

---

## 7. System Configuration

Default parameters defined in the current implementation:

| Parameter | Default Value |
|---|---:|
| TICK_RATE | 60 |
| ALTITUDE_GAIN | 0.35 |
| MAX_CLIMB_SPEED | 110 |
| MAX_DESCENT_SPEED | 3 |
| CONTROL_MIN | -0.45 |
| CONTROL_MAX | 0.45 |
| INTEGRAL_LIMIT | 10 |
| CONTROL_RATE | 0.005 |
| ALTITUDE_STABLE_TIME | 2 seconds |
| DIRECTIONAL_BOOSTER_PULSE | 0.2 seconds |
| DEBUG | true |

---

## 8. Condition Margins

The flight sequence uses configurable tolerances.

| Parameter | Value | Description |
|---|---:|---|
| RPS | 1 | Engine RPS tolerance |
| ALTITUDE | 15 | Altitude stability tolerance |
| VERTICAL_SPEED | 2 | Reserved vertical speed tolerance |
| ROLL | 0.005 | Reserved roll tolerance |
| PITCH | 0.1 | Pitch stability tolerance |

Some declared margins are not currently used by the implemented transition conditions.

---

## 9. Diagnostics

The system includes integrated diagnostic outputs for monitoring flight performance.

Available telemetry:

- Current vertical speed.
- Desired vertical speed.
- Vertical speed error.
- Altitude control output.
- Current altitude.
- Target altitude.
- Altitude error.
- Autopilot yaw.
- Distance to target.
- Current coordinates.
- Target coordinates.

Diagnostics can be enabled or disabled through:

`CONFIG.DEBUG`

---

## 10. Installation

1. Open the Stormworks Lua microcontroller editor.
2. Copy the YR-02 flight control script.
3. Configure all numerical inputs.
4. Configure the START Boolean input.
5. Connect all actuator outputs.
6. Verify sensor calibration and signal direction.
7. Verify propulsion and control surface responses.
8. Test each subsystem independently.
9. Test the complete automated flight sequence.

**Important:** All actuator connections, signal ranges and sensor orientations must be verified in-game before operational use.

---

## 11. Development Structure

The project currently uses a single-file Lua architecture.

Recommended repository structure:

```text
OAI-MIZUSHIMA-YR-02/
│
├── README.md
├── CHANGELOG.md
├── LICENSE
│
└── src/
    └── yr02_flight_control.lua
```

---

## 12. Git Branch Strategy

The project follows a Git Flow-inspired development model.

| Branch | Purpose |
|---|---|
| `main` | Stable releases |
| `develop` | Main development branch |
| `feature/*` | New functionality |
| `fix/*` | Bug fixes |
| `release/*` | Release preparation |
| `hotfix/*` | Urgent production fixes |

Example feature branches:

```text
feature/roll-stabilizer
feature/altitude-hold
feature/autopilot
feature/flight-sequence
feature/directional-boosters
feature/diagnostics
```

New functionality should be developed independently and merged into `develop` after testing.

Stable releases are merged into `main`.

---

## 13. Versioning

The project uses a semantic versioning-inspired system.

| Version | Meaning |
|---|---|
| 12.0.0 | Major baseline release |
| 12.1.0 | New functionality |
| 12.1.1 | Bug fixes |
| 13.0.0 | Major system changes |

Git tags should identify stable releases.

Example:

```bash
git tag -a v12.0.0 -m "YR-02 Version 12.0.0"
git push origin v12.0.0
```

---

## 14. Current Development Status

| Component | Status |
|---|---|
| Roll Stabilizer | Implemented |
| Altitude Hold | Implemented |
| Autopilot | Implemented |
| Flight Sequence | Implemented |
| Directional Boosters | Implemented |
| Diagnostics | Implemented |
| Abort System | Not implemented |
| Timeout System | Not implemented |

*Implemented does not necessarily mean fully validated in-game.*

---

## 15. Important Technical Notes

The following points should be reviewed during future development:

- Verify the Boolean channel assignment for `ROLL_STABILIZER`.
- Review the unused `VERTICAL_SPEED` and `ROLL` margins.
- Validate PID gains and actuator response in-game.
- Verify compass normalization and heading calculations.
- Check sequence transitions under abnormal sensor conditions.
- Consider adding abort and timeout functionality in a future version.
- Verify that the declared 60 Hz reference matches the actual tick timing used by the controller.

---

## Project Information

**Project:** OAI MIZUSHIMA YR-02  
**System:** Modular Flight Control  
**Platform:** Stormworks: Build and Rescue  
**Language:** Lua  
**Current Version:** 12.0  
**Architecture:** Single File  

---

*OAI MIZUSHIMA YR-02 — Modular Flight Control*  
*Automated Flight Systems Development*
