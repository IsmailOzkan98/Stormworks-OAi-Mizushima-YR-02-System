# OAI MIZUSHIMA YR-02
## Modular Flight Control System

| Property | Value |
|---|---|
| Project | OAI MIZUSHIMA YR-02 |
| System | Modular Flight Control System |
| System Version | 14.0 |
| Source Migration | V13.1.0 |
| Platform | Stormworks: Build and Rescue |
| Architecture | Modular Microcontroller Flight Control System |
| Language | Lua |
| Microcontrollers | MC01–MC07 |

---

# 1. General Description

The **OAI MIZUSHIMA YR-02** is a modular flight control system developed for Stormworks.

The architecture divides flight control functions into seven independent microcontrollers. Each module has a specific responsibility and communicates with the others through Composite connections.

The purpose of this architecture is to keep flight functions separate, simplify maintenance, and allow each module to be modified and tested individually.

## 1.1. Module Architecture

| MC | Module | Responsibility |
|---|---|---|
| MC01 | FLIGHT SEQUENCE | Mission management and flight sequence |
| MC02 | MASTER CONTROL | Distribution of general commands |
| MC03 | FLIGHT CONTROL | Roll stabilization |
| MC04 | ALTITUDE CONTROL | Altitude control using PID |
| MC05 | NAVIGATION | Navigation and heading calculation |
| MC06 | PROPULSION | Thruster and spoiler management |
| MC07 | TELEMETRY | Monitoring and HTTP transmission |

MC07 is optional. Its absence must not prevent the main flight controls from operating.

## 1.2. Architectural Principles

- Sensors are connected directly to the modules that require their measurements.
- General flight commands are distributed through MC02.
- Specific signals may be connected directly between the modules that generate them and those that require them.
- Outputs intended for actuators are documented separately from communication signals.
- MC07 receives information from other modules and sensors to generate telemetry.
- Composite connections must respect the data type and channel number of each signal.

---

# 2. Signal and Connection Conventions

This section establishes how to interpret the connection tables.

## 2.1. Channel Types

Stormworks provides two independent families of Composite channels:

| Type | Identification | Information Carried |
|---|---|---|
| Boolean | Bool | Binary states: on/off, true/false |
| Number | Num | Numerical values: measurements, parameters, calculations, and analog commands |

Boolean and Number channels are independent. For example, `Bool 3` and `Num 3` are not the same channel.

Each microcontroller supports up to 32 inputs and 32 outputs of each type.

## 2.2. Signal Nature

The channel type does not, by itself, indicate what the signal represents. The following categories are used to identify its function:

| Nature | Description | Examples |
|---|---|---|
| Physical Sensor | Value provided by a sensor installed on the vehicle | ALTITUDE, REAL_RPS, AP_COMPASS |
| Configuration Parameter | Adjustable value that modifies a controller's behavior | PID_P, PID_I, PID_D, MULTIPLIER |
| Control Command | Instruction sent to enable or activate a function | ALTITUDE_HOLD, AUTOPILOT |
| State | Information about the state of a sequence or system | RUNNING, COMPLETED |
| Control Calculation | Result produced by a control algorithm | DESIRED_VERTICAL_SPEED |
| Navigation Data | Position, distance, or heading information | AP_DISTANCE, AP_TARGET_HEADING |
| Actuator Output | Command intended to control an actuator | ELEVATOR_LEFT, MAIN_BOOSTER |
| Telemetry | Information collected for monitoring | SEQUENCE_TIMER, AP_YAW |

## 2.3. Table Interpretation

All connections are documented using the following structure:

| Column | Meaning |
|---|---|
| Source | Sensor, configuration, or microcontroller that generates the signal |
| Output | Channel through which the signal is transmitted |
| Destination | Receiving microcontroller or device |
| Input | Channel through which the signal is received |
| Signal | Identifier assigned to the information |
| Data | Boolean or Number |
| Nature | Function performed by the signal |
| Description | Explanation of what the signal represents and how it is used |

**Fundamental rule:** the output type and channel number of the source must match the input type and channel number of the destination.

Example:

| Source | Output | Destination | Input | Signal | Data | Nature |
|---|---|---|---|---|---|---|
| MC04 | Num 5 | MC07 | Num 6 | DESIRED_VERTICAL_SPEED | Number | Control Calculation |

This means that the Number 5 output of MC04 must be connected to the Number 6 input of MC07.

---

# 3. General Wiring Procedure

Assembly must follow the connection tables, not just the signal names.

## 3.1. Connections Between Microcontrollers

To connect two microcontrollers:

1. Identify the microcontroller that generates the signal.
2. Locate its output channel in the corresponding table.
3. Identify the microcontroller that requires the signal.
4. Locate the corresponding input channel.
5. Connect the source Composite to the destination Composite.
6. Check that both modules use the same channel type and number.
7. Verify the received value during testing.

A signal must not be connected to a different channel simply because it has the same name in another module.

## 3.2. Signal Distribution

A single signal may feed several modules when they all require the same data.

For example, an altitude measurement may feed MC01, MC04, and MC07.

Distribution must preserve the channel type and number expected by each receiver. If the modules use different channels, the corresponding assignment must be performed in the Composite distribution system.

## 3.3. Physical Sensors

Physical sensors are connected to the inputs of the microcontroller that uses them.

Not all sensors need to pass through MC02.

Examples:

- The altitude sensor feeds the modules that need to know the current altitude.
- The vertical speed sensor feeds the modules that require vertical speed measurements.
- The compass sensor feeds MC05.
- Tilt sensors feed the modules that perform stabilization calculations or orientation detection.

## 3.4. Configuration Parameters

Configuration parameters are values that must be supplied to the microcontroller through their corresponding Number inputs.

Examples:

- PID_P
- PID_I
- PID_D
- MULTIPLIER
- ALTITUDE_TARGET
- TARGET_RPS
- AP_STEERING
- AP_CUTOFF
- AP_DEADZONE
- AP_SMOOTHING
- etc.

They must not be confused with physical sensors: they represent configuration values, not measurements of the vehicle.

## 3.5. Actuator Outputs

Microcontroller outputs must be connected to the corresponding actuators while respecting the signal type.

- Boolean commands control activation states.
- Number commands transmit control values.

The assignment of each output to its physical actuator must be checked against the vehicle assembly diagram.

---

# 4. Master Table of Connections Between Microcontrollers

This is the main reference for Composite connections between modules.

## 4.1. MC01 → MC02 — Sequence Distribution

MC01 generates general commands and flight sequence status values. MC02 receives and distributes them to other controllers.

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC01 | Bool 1 | MC02 | Bool 1 | RUNNING | Boolean | State | Indicates that the sequence is running |
| MC01 | Bool 2 | MC02 | Bool 2 | COMPLETED | Boolean | State | Indicates that the sequence has finished |
| MC01 | Bool 3 | MC02 | Bool 3 | ROLL_STABILIZER | Boolean | Control Command | Enables roll stabilization |
| MC01 | Bool 4 | MC02 | Bool 4 | MAIN_BOOSTER | Boolean | Control Command | Requests activation of the main booster |
| MC01 | Bool 5 | MC02 | Bool 5 | DIRECTIONAL_BOOSTER_TRIGGER | Boolean | Control Command | Requests a directional booster pulse |
| MC01 | Bool 6 | MC02 | Bool 6 | BOTTOM_BOOSTERS | Boolean | Control Command | Enables the lower booster logic |
| MC01 | Bool 7 | MC02 | Bool 7 | ACCELERATION_BOOSTERS | Boolean | Control Command | Requests activation of the acceleration boosters |
| MC01 | Bool 8 | MC02 | Bool 8 | ALTITUDE_HOLD | Boolean | Control Command | Enables altitude hold |
| MC01 | Bool 9 | MC02 | Bool 9 | AUTOPILOT | Boolean | Control Command | Enables the autopilot |
| MC01 | Bool 10 | MC02 | Bool 10 | START_STATUS | Boolean | State | Status related to sequence initiation |
| MC01 | Num 1 | MC02 | Num 1 | SEQUENCE_STATE | Number | State | Identifier of the current flight phase |
| MC01 | Num 2 | MC02 | Num 2 | SEQUENCE_TIMER | Number | Sequence timer |
| MC01 | Num 3 | MC02 | Num 3 | SPOILER | Number | Control Command | Spoiler control value |
| MC01 | Num 4 | MC02 | Num 4 | ALTITUDE_STABLE_TIMER | Number | State | Altitude stability timer |
| MC01 | Num 5 | MC02 | Num 5 | ROLL_STABLE_TIMER | Number | State | Roll stability timer |

## 4.2. MC02 → MC03 — Flight Control

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 3 | MC03 | Bool 3 | ROLL_STABILIZER | Boolean | Control Command | Enables roll stabilization |

MC03 also requires its multiplier and horizontal tilt sensor to be connected directly.

## 4.3. MC02 → MC04 — Altitude Control

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 8 | MC04 | Bool 8 | ALTITUDE_HOLD | Boolean | Control Command | Enables automatic altitude control |

## 4.4. MC02 → MC05 — Navigation

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 9 | MC05 | Bool 9 | AUTOPILOT | Boolean | Control Command | Enables the autopilot |

## 4.5. MC02 → MC06 — Propulsion

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC02 | Bool 4 | MC06 | Bool 1 | MAIN_BOOSTER | Boolean | Control Command | Main booster control |
| MC02 | Bool 5 | MC06 | Bool 2 | DIRECTIONAL_BOOSTER_TRIGGER | Boolean | Control Command | Triggers directional booster selection |
| MC02 | Bool 6 | MC06 | Bool 3 | BOTTOM_BOOSTERS | Boolean | Control Command | Enables the lower boosters |
| MC02 | Bool 7 | MC06 | Bool 4 | ACCELERATION_BOOSTERS | Boolean | Control Command | Controls the acceleration boosters |
| MC02 | Num 3 | MC06 | Num 1 | SPOILER | Number | Control Command | Transmits the spoiler value |

## 4.6. MC05 → MC06 — Navigation to Propulsion

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC05 | Num 12 | MC06 | Num 2 | AP_TARGET_HEADING | Number | Navigation Data | Transmits the normalized heading towards the target |

**Important:** AP_TARGET_HEADING uses MC05 Number 12. It must not be connected from Number 7.

## 4.7. MC04 → MC07 — Telemetry

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC04 | Num 5 | MC07 | Num 6 | DESIRED_VERTICAL_SPEED | Number | Control Calculation | Desired vertical speed calculated by MC04 |

## 4.8. MC05 → MC07 — Telemetry

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC05 | Num 7 | MC07 | Num 11 | AP_DISTANCE | Number | Navigation Data | Current distance to the target |
| MC05 | Num 6 | MC07 | Num 12 | AP_YAW | Number | Control Calculation | Yaw correction calculated by the autopilot |
| MC05 | Num 8 | MC07 | Num 13 | AP_MY_X | Number | Navigation Data | Current X coordinate |
| MC05 | Num 9 | MC07 | Num 14 | AP_MY_Y | Number | Navigation Data | Current Y coordinate |
| MC05 | Num 10 | MC07 | Num 15 | AP_TARGET_X | Number | Navigation Data | Target X coordinate |
| MC05 | Num 11 | MC07 | Num 16 | AP_TARGET_Y | Number | Navigation Data | Target Y coordinate |

## 4.9. MC02 → MC07 — Telemetry

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC02 | Num 1 | MC07 | Num 1 | SEQUENCE_STATE | Number | State | Current sequence phase |
| MC02 | Num 2 | MC07 | Num 2 | SEQUENCE_TIMER | Number | State | Elapsed sequence time |
| MC02 | Num 3 | MC07 | Num 17 | SPOILER | Number | Control Command | Spoiler value |
| MC02 | Bool 1 | MC07 | Bool 1 | RUNNING | Boolean | State | Sequence running |
| MC02 | Bool 2 | MC07 | Bool 2 | COMPLETED | Boolean | State | Sequence completed |
| MC02 | Bool 3 | MC07 | Bool 6 | ROLL_STABILIZER | Boolean | State | Roll stabilization enabled |
| MC02 | Bool 4 | MC07 | Bool 4 | MAIN_BOOSTER | Boolean | State | Main booster requested |
| MC02 | Bool 7 | MC07 | Bool 7 | ACCELERATION_BOOSTERS | Boolean | State | Acceleration boosters requested |
| MC02 | Bool 8 | MC07 | Bool 5 | ALTITUDE_HOLD | Boolean | State | Altitude hold enabled |
| MC02 | Bool 9 | MC07 | Bool 3 | AUTOPILOT | Boolean | State | Autopilot enabled |

## 4.10. MC06 → MC07 — Telemetry

| Source | Output | Destination | Input | Signal | Data | Nature | Description |
|---|---|---|---|---|---|---|---|
| MC06 | Bool 5 | MC07 | Bool 8 | NORTH_BOOSTER | Boolean | Actuator State | North booster status |
| MC06 | Bool 6 | MC07 | Bool 9 | EAST_BOOSTER | Boolean | Actuator State | East booster status |
| MC06 | Bool 7 | MC07 | Bool 10 | SOUTH_BOOSTER | Boolean | Actuator State | South booster status |
| MC06 | Bool 8 | MC07 | Bool 11 | WEST_BOOSTER | Boolean | Actuator State | West booster status |

---

# 5. Master Table of Sensor and Configuration Inputs

This table identifies the signals that must be supplied by physical sensors or configuration values.

The listed channels correspond to the documented inputs of each controller. When the same sensor is used by multiple modules, its signal must be distributed to every destination that requires it.

| Signal | Nature | Data | MC01 | MC03 | MC04 | MC05 | MC06 | MC07 |
|---|---|---|---|---|---|---|---|---|
| TILT_ROLL_HORIZ | Physical Sensor | Number | Num 2 | Num 2 | — | — | Num 3 | Num 9 |
| TILT_PITCH | Physical Sensor | Number | Num 3 | — | — | — | — | Num 10 |
| TARGET_RPS | Configuration Parameter | Number | Num 4 | — | — | — | — | Num 8 |
| REAL_RPS | Physical Sensor | Number | Num 5 | — | — | — | — | Num 7 |
| ALTITUDE | Physical Sensor | Number | Num 6 | — | Num 1 | — | — | Num 3 |
| ALTITUDE_TARGET | Configuration Parameter | Number | Num 7 | — | Num 2 | — | — | Num 4 |
| VERTICAL_SPEED | Physical Sensor | Number | Num 12 | — | Num 6 | — | — | Num 5 |
| AP_KEYBOARD_X | Navigation Input | Number | Num 13 | — | — | Num 1 | — | — |
| AP_KEYBOARD_Y | Navigation Input | Number | Num 14 | — | — | Num 2 | — | — |
| AP_SENSOR_X | Position Sensor | Number | Num 15 | — | — | Num 3 | — | — |
| AP_SENSOR_Y | Position Sensor | Number | Num 16 | — | — | Num 4 | — | — |
| AP_COMPASS | Physical Sensor | Number | — | — | — | Num 5 | — | — |
| AP_STEERING | Configuration Parameter | Number | — | — | — | Num 6 | — | — |
| AP_CUTOFF | Configuration Parameter | Number | Num 19 | — | — | Num 7 | — | — |
| AP_DEADZONE | Configuration Parameter | Number | — | — | — | Num 8 | — | — |
| AP_SMOOTHING | Configuration Parameter | Number | — | — | — | Num 9 | — | — |
| VERTICAL_SPEED_TARGET | Configuration Parameter | Number | Num 22 | — | — | — | — | — |
| MULTIPLIER | Configuration Parameter | Number | — | Num 1 | — | — | — | — |
| TILT_ROLL_VERT | Physical Sensor | Number | — | — | — | — | Num 4 | — |
| PID_P | Configuration Parameter | Number | — | — | Num 3 | — | — | — |
| PID_I | Configuration Parameter | Number | — | — | Num 4 | — | — | — |
| PID_D | Configuration Parameter | Number | — | — | Num 5 | — | — | — |
| ALT_HOLD_DELAY | Configuration Parameter | Number | Num 11 | — | — | — | — | — |

**Note about this table:** dashes indicate that the signal is not listed as an input for that module in the documented distribution. They do not mean that the sensor cannot be used in other functions in the future.

## 5.1. Boolean Input Signals

| Signal | Nature | Source | Destination | Input |
|---|---|---|---|---|
| START | Control Command | Start switch | MC01 | Bool 1 |
| ROLL_STABILIZER | Control Command | MC02 | MC03 | Bool 3 |
| ALTITUDE_HOLD | Control Command | MC02 | MC04 | Bool 8 |
| AUTOPILOT | Control Command | MC02 | MC05 | Bool 9 |
| MAIN_BOOSTER | Control Command | MC02 | MC06 | Bool 1 |
| DIRECTIONAL_BOOSTER_TRIGGER | Control Command | MC02 | MC06 | Bool 2 |
| BOTTOM_BOOSTERS | Control Command | MC02 | MC06 | Bool 3 |
| ACCELERATION_BOOSTERS | Control Command | MC02 | MC06 | Bool 4 |

---

# 6. MC01 — FLIGHT SEQUENCE

**Responsibility:** mission management and flight sequence.

MC01 manages the flight phases and determines when the different control functions must be activated.

## 6.1. Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Bool 1 | START | Boolean | Control Command | Start switch |
| Num 2 | TILT_ROLL_HORIZ | Number | Physical Sensor | Tilt sensor |
| Num 3 | TILT_PITCH | Number | Physical Sensor | Tilt sensor |
| Num 4 | TARGET_RPS | Number | Parameter | Configuration |
| Num 5 | REAL_RPS | Number | Physical Sensor | RPS sensor |
| Num 6 | ALTITUDE | Number | Physical Sensor | Altitude sensor |
| Num 7 | ALTITUDE_TARGET | Number | Parameter | Configuration |
| Num 12 | VERTICAL_SPEED | Number | Physical Sensor | Vertical speed sensor |
| Num 13 | AP_KEYBOARD_X | Number | Navigation Input | Target configuration |
| Num 14 | AP_KEYBOARD_Y | Number | Navigation Input | Target configuration |
| Num 15 | AP_SENSOR_X | Number | Physical Sensor | Position sensor |
| Num 16 | AP_SENSOR_Y | Number | Physical Sensor | Position sensor |
| Num 19 | AP_CUTOFF | Number | Parameter | Configuration |
| Num 22 | VERTICAL_SPEED_TARGET | Number | Parameter | Configuration |
| Num 11 | ALT_HOLD_DELAY | Number | Parameter | Configuration |

## 6.2. Boolean Outputs

| Channel | Signal | Destination | Nature | Function |
|---|---|---|---|---|
| Bool 1 | RUNNING | MC02 Bool 1 | State | Sequence running |
| Bool 2 | COMPLETED | MC02 Bool 2 | State | Sequence completed |
| Bool 3 | ROLL_STABILIZER | MC02 Bool 3 | Control Command | Enables stabilization |
| Bool 4 | MAIN_BOOSTER | MC02 Bool 4 | Control Command | Activates the main booster |
| Bool 5 | DIRECTIONAL_BOOSTER_TRIGGER | MC02 Bool 5 | Control Command | Requests a directional booster |
| Bool 6 | BOTTOM_BOOSTERS | MC02 Bool 6 | Control Command | Enables the lower boosters |
| Bool 7 | ACCELERATION_BOOSTERS | MC02 Bool 7 | Control Command | Activates the acceleration boosters |
| Bool 8 | ALTITUDE_HOLD | MC02 Bool 8 | Control Command | Activates altitude hold |
| Bool 9 | AUTOPILOT | MC02 Bool 9 | Control Command | Activates the autopilot |
| Bool 10 | START_STATUS | MC02 Bool 10 | State | Start status |

## 6.3. Number Outputs

| Channel | Signal | Destination | Nature | Function |
|---|---|---|---|---|
| Num 1 | SEQUENCE_STATE | MC02 Num 1 | State | Current flight phase |
| Num 2 | SEQUENCE_TIMER | MC02 Num 2 | State | Sequence timer |
| Num 3 | SPOILER | MC02 Num 3 | Control Command | Spoiler value |
| Num 4 | ALTITUDE_STABLE_TIMER | MC02 Num 4 | State | Altitude stability timer |
| Num 5 | ROLL_STABLE_TIMER | MC02 Num 5 | State | Roll stability timer |

---

# 7. MC02 — MASTER CONTROL

**Responsibility:** distribution of general commands.

MC02 receives signals from MC01 and retransmits them through its corresponding outputs.

It does not perform roll stabilization, navigation, or altitude control calculations.

## 7.1. Inputs

| Channel | Signal | Data | Source |
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

## 7.2. Outputs

MC02 uses direct distribution: it preserves the type, channel number, and value of each input channel.

| Output Channel | Signal | Main Destination |
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
| Bool 10 | START_STATUS | Available for monitoring |
| Num 1 | SEQUENCE_STATE | MC07 Num 1 |
| Num 2 | SEQUENCE_TIMER | MC07 Num 2 |
| Num 3 | SPOILER | MC06 Num 1 / MC07 Num 17 |
| Num 4 | ALTITUDE_STABLE_TIMER | Available for monitoring |
| Num 5 | ROLL_STABLE_TIMER | Available for monitoring |

---

# 8. MC03 — FLIGHT CONTROL

**Responsibility:** roll stabilization.

MC03 calculates roll correction commands using horizontal tilt and the configured multiplier.

## 8.1. Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Num 1 | MULTIPLIER | Number | Parameter | Configuration |
| Num 2 | TILT_ROLL_HORIZ | Number | Physical Sensor | Tilt sensor |
| Bool 3 | ROLL_STABILIZER | Boolean | Control Command | MC02 Bool 3 |

## 8.2. Outputs

| Channel | Signal | Data | Nature | Destination |
|---|---|---|---|---|
| Num 1 | ROLL_RIGHT | Number | Actuator Output | Corresponding roll control |
| Num 2 | ROLL_LEFT | Number | Actuator Output | Corresponding roll control |

The outputs must be connected to the corresponding roll actuators according to the vehicle assembly.

## 8.3. Operation

When `ROLL_STABILIZER` is disabled, both outputs are set to zero.

When enabled, the controller calculates the correction using the tilt value and the multiplier.

The controller generates opposing commands for both sides.

---

# 9. MC04 — ALTITUDE CONTROL

**Responsibility:** altitude regulation using PID.

MC04 calculates the desired vertical speed and uses PID control to generate elevator commands.

## 9.1. Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Num 1 | ALTITUDE | Number | Physical Sensor | Altitude sensor |
| Num 2 | ALTITUDE_TARGET | Number | Parameter | Target altitude configuration |
| Num 3 | PID_P | Number | Parameter | PID configuration |
| Num 4 | PID_I | Number | Parameter | PID configuration |
| Num 5 | PID_D | Number | Parameter | PID configuration |
| Num 6 | VERTICAL_SPEED | Number | Physical Sensor | Vertical speed sensor |
| Bool 8 | ALTITUDE_HOLD | Boolean | Control Command | MC02 Bool 8 |

## 9.2. Outputs

| Channel | Signal | Data | Nature | Destination |
|---|---|---|---|---|
| Num 3 | ELEVATOR_RIGHT | Number | Actuator Output | Right elevator |
| Num 4 | ELEVATOR_LEFT | Number | Actuator Output | Left elevator |
| Num 5 | DESIRED_VERTICAL_SPEED | Number | Control Calculation | MC07 Num 6 |

**Important:** `DESIRED_VERTICAL_SPEED` is transmitted through Number 5. MC07 must receive it through Number 6.

Both elevators receive the same value calculated by MC04. They must not be interpreted as two independent commands.

## 9.3. Operation

MC04 performs the following operations:

1. Reads the current altitude.
2. Compares the current altitude with the target altitude.
3. Calculates the desired vertical speed.
4. Limits the desired vertical speed to the controller's defined limits.
5. Executes the PID calculation.
6. Applies integrator protection.
7. Limits and smooths the control output.
8. Publishes the desired vertical speed through Number 5.

When altitude hold is disabled, the controller performs the state resets specified by its implementation.

---

# 10. MC05 — NAVIGATION

**Responsibility:** navigation, distance to target, and heading calculation.

MC05 calculates the relative position to the target and generates navigation data used by other modules.

## 10.1. Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Num 1 | AP_KEYBOARD_X | Number | Navigation Input | Target X coordinate configuration |
| Num 2 | AP_KEYBOARD_Y | Number | Navigation Input | Target Y coordinate configuration |
| Num 3 | AP_SENSOR_X | Number | Physical Sensor | X position sensor |
| Num 4 | AP_SENSOR_Y | Number | Physical Sensor | Y position sensor |
| Num 5 | AP_COMPASS | Number | Physical Sensor | Compass |
| Num 6 | AP_STEERING | Number | Parameter | Steering configuration |
| Num 7 | AP_CUTOFF | Number | Parameter | Cutoff distance configuration |
| Num 8 | AP_DEADZONE | Number | Parameter | Deadzone configuration |
| Num 9 | AP_SMOOTHING | Number | Parameter | Smoothing configuration |
| Bool 9 | AUTOPILOT | Boolean | Control Command | MC02 Bool 9 |

## 10.2. Outputs

| Channel | Signal | Data | Nature | Destination |
|---|---|---|---|---|
| Num 6 | AP_YAW | Number | Navigation Data | Rudder / MC07 Num 12 |
| Num 7 | AP_DISTANCE | Number | Navigation Data | MC07 Num 11 |
| Num 8 | AP_MY_X | Number | Navigation Data | MC07 Num 13 |
| Num 9 | AP_MY_Y | Number | Navigation Data | MC07 Num 14 |
| Num 10 | AP_TARGET_X | Number | Navigation Data | MC07 Num 15 |
| Num 11 | AP_TARGET_Y | Number | Navigation Data | MC07 Num 16 |
| Num 12 | AP_TARGET_HEADING | Number | Navigation Data | MC06 Num 2 |

**Important:**

- `AP_DISTANCE` is on Number 7.
- `AP_TARGET_HEADING` is on Number 12.
- Number 7 must not be used to transmit `AP_TARGET_HEADING`.

## 10.3. Operation

MC05 performs the calculations required to:

- Obtain the difference between the current position and the target position.
- Calculate the distance to the target.
- Calculate the target angle and heading.
- Normalize the heading.
- Calculate the yaw error.
- Apply the steering parameters.
- Apply the deadzone.
- Apply the distance limit.
- Apply command smoothing.

The `AP_TARGET_HEADING` calculation is available regardless of whether the autopilot is enabled. The `AP_YAW` output is set to zero when the autopilot is disabled.

---

# 11. MC06 — PROPULSION

**Responsibility:** thruster and spoiler management.

MC06 receives flight sequence commands and navigation data to manage the thrusters.

It also uses its own tilt sensors to select the lower boosters.

## 11.1. Number Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Num 1 | SPOILER | Number | Control Command | MC02 Num 3 |
| Num 2 | TARGET_HEADING | Number | Navigation Data | MC05 Num 12 |
| Num 3 | TILT_ROLL_HORIZ | Number | Physical Sensor | Horizontal tilt sensor |
| Num 4 | TILT_ROLL_VERT | Number | Physical Sensor | Vertical tilt sensor |

## 11.2. Boolean Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Bool 1 | MAIN_BOOSTER | Boolean | Control Command | MC02 Bool 4 |
| Bool 2 | DIRECTIONAL_BOOSTER_TRIGGER | Boolean | Control Command | MC02 Bool 5 |
| Bool 3 | BOTTOM_BOOSTERS | Boolean | Control Command | MC02 Bool 6 |
| Bool 4 | ACCELERATION_BOOSTERS | Boolean | Control Command | MC02 Bool 7 |

## 11.3. Number Outputs

| Channel | Signal | Data | Nature | Destination |
|---|---|---|---|---|
| Num 5 | SPOILER | Number | Actuator Output | Spoiler system |

## 11.4. Boolean Outputs

| Channel | Signal | Data | Nature | Function |
|---|---|---|---|---|
| Bool 1 | MAIN_BOOSTER | Boolean | Actuator Output | Main booster activation |
| Bool 5 | NORTH_BOOSTER | Boolean | Actuator Output | North booster activation |
| Bool 6 | EAST_BOOSTER | Boolean | Actuator Output | East booster activation |
| Bool 7 | SOUTH_BOOSTER | Boolean | Actuator Output | South booster activation |
| Bool 8 | WEST_BOOSTER | Boolean | Actuator Output | West booster activation |
| Bool 9 | ACCELERATION_BOOSTER | Boolean | Actuator Output | Acceleration booster activation |

## 11.5. Directional Booster Selection

MC06 uses `TARGET_HEADING`, received from MC05, to select the corresponding directional booster.

The selection sectors are:

| Direction | Normalized Heading Sector |
|---|---|
| North | -0.125 ≤ heading < +0.125 |
| East | +0.125 ≤ heading < +0.375 |
| South | +0.375 ≤ heading ≤ +0.5 and -0.5 ≤ heading < -0.375 |
| West | -0.375 ≤ heading < -0.125 |

The activation request is received through `DIRECTIONAL_BOOSTER_TRIGGER`.

The controller generates an activation pulse lasting 0.2 seconds, according to the implemented logic.

## 11.6. Lower Booster Detection

MC06 uses its own tilt sensors to determine the vehicle's orientation.

The logic includes:

- Tilt magnitude calculation.
- Roll angle calculation.
- Opposite angle normalization.
- Identification of the four directional zones.
- Application of the defined angular limits.

The lower booster commands are combined with the directional booster commands through the same four Boolean outputs:

- NORTH_BOOSTER
- EAST_BOOSTER
- SOUTH_BOOSTER
- WEST_BOOSTER

Therefore, the four outputs represent the combined result of both control systems, not two independent groups of outputs.

## 11.7. Sequence Reset

The original flight logic includes the reset of states related to directional booster activation when a new sequence begins.

The reset mechanism between MC01 and MC06 must be verified during final integration. It must not be considered validated until the internal states and pulses have been confirmed to reset correctly across repeated flights.

---

# 12. MC07 — TELEMETRY

**Responsibility:** flight monitoring and HTTP transmission.

MC07 receives data from the other modules and physical sensors. It organizes this information to generate telemetry.

It does not directly control flight actuators.

## 12.1. Configuration

| Parameter | Value |
|---|---|
| ENABLED | true |
| PORT | 8080 |
| INTERVAL | 6 ticks |
| Nominal Frequency | 10 transmissions per second at 60 Hz |

## 12.2. Number Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Num 1 | SEQUENCE_STATE | Number | State | MC02 Num 1 |
| Num 2 | SEQUENCE_TIMER | Number | State | MC02 Num 2 |
| Num 3 | ALTITUDE | Number | Physical Sensor | Altitude sensor |
| Num 4 | ALTITUDE_TARGET | Number | Parameter | Configuration |
| Num 5 | VERTICAL_SPEED | Number | Physical Sensor | Vertical speed sensor |
| Num 6 | DESIRED_VERTICAL_SPEED | Number | Control Calculation | MC04 Num 5 |
| Num 7 | REAL_RPS | Number | Physical Sensor | RPS sensor |
| Num 8 | TARGET_RPS | Number | Parameter | Configuration |
| Num 9 | TILT_ROLL_HORIZ | Number | Physical Sensor | Tilt sensor |
| Num 10 | TILT_PITCH | Number | Physical Sensor | Tilt sensor |
| Num 11 | AP_DISTANCE | Number | Navigation Data | MC05 Num 7 |
| Num 12 | AP_YAW | Number | Control Calculation | MC05 Num 6 |
| Num 13 | AP_MY_X | Number | Navigation Data | MC05 Num 8 |
| Num 14 | AP_MY_Y | Number | Navigation Data | MC05 Num 9 |
| Num 15 | AP_TARGET_X | Number | Navigation Data | MC05 Num 10 |
| Num 16 | AP_TARGET_Y | Number | Navigation Data | MC05 Num 11 |
| Num 17 | SPOILER | Number | Control Command | MC06 Num 5 |

## 12.3. Boolean Inputs

| Channel | Signal | Data | Nature | Source |
|---|---|---|---|---|
| Bool 1 | RUNNING | Boolean | State | MC02 Bool 1 |
| Bool 2 | COMPLETED | Boolean | State | MC02 Bool 2 |
| Bool 3 | AUTOPILOT | Boolean | State | MC02 Bool 9 |
| Bool 4 | MAIN_BOOSTER | Boolean | Actuator State | MC06 Bool 1 |
| Bool 5 | ALTITUDE_HOLD | Boolean | State | MC02 Bool 8 |
| Bool 6 | ROLL_STABILIZER | Boolean | State | MC02 Bool 3 |
| Bool 7 | ACCELERATION_BOOSTERS | Boolean | Actuator State | MC06 Bool 9 |
| Bool 8 | NORTH_BOOSTER | Boolean | Actuator State | MC06 Bool 5 |
| Bool 9 | EAST_BOOSTER | Boolean | Actuator State | MC06 Bool 6 |
| Bool 10 | SOUTH_BOOSTER | Boolean | Actuator State | MC06 Bool 7 |
| Bool 11 | WEST_BOOSTER | Boolean | Actuator State | MC06 Bool 8 |

## 12.4. Transmitted Information

MC07 collects information about:

- Flight status and sequence phase.
- Sequence time.
- Current and target altitude.
- Altitude error.
- Current and desired vertical speed.
- Vertical speed error.
- Current and target RPS.
- Roll and pitch tilt.
- Autopilot status.
- Distance to target.
- Yaw correction.
- Current and target coordinates.
- Booster status.
- Altitude hold status.
- Stabilization status.
- Spoiler value.

## 12.5. HTTP Communication

Transmission uses the Stormworks Lua HTTP functionality:

`async.httpGet(8080, url)`

The endpoint uses the following format:

`/telemetry?...`

MC07 provides an HTTP communication output but does not have actuator control outputs within the described architecture.

---

# 13. Master Table of Actuator Outputs

This table identifies the control outputs that must be connected to the vehicle's actuators.

The logical channels are identified by the scripts. Their correspondence with physical components must be verified against the vehicle assembly.

| Controller | Output | Signal | Data | Actuator or System |
|---|---|---|---|---|
| MC03 | Num 1 | ROLL_RIGHT | Number | Right roll control |
| MC03 | Num 2 | ROLL_LEFT | Number | Left roll control |
| MC04 | Num 3 | ELEVATOR_RIGHT | Number | Right elevator |
| MC04 | Num 4 | ELEVATOR_LEFT | Number | Left elevator |
| MC05 | Num 6 | AP_YAW | Number | Rudder |
| MC06 | Num 5 | SPOILER | Number | Spoiler system |
| MC06 | Bool 1 | MAIN_BOOSTER | Boolean | Main booster |
| MC06 | Bool 9 | ACCELERATION_BOOSTER | Boolean | Acceleration booster |
| MC06 | Bool 5 | NORTH_BOOSTER | Boolean | North booster |
| MC06 | Bool 6 | EAST_BOOSTER | Boolean | East booster |
| MC06 | Bool 7 | SOUTH_BOOSTER | Boolean | South booster |
| MC06 | Bool 8 | WEST_BOOSTER | Boolean | West booster |

**Note:** the `DESIRED_VERTICAL_SPEED` output from MC04 and the navigation outputs from MC05 are internal communication signals between controllers, not physical actuator outputs.

---

# 14. Architecture Diagrams

## 14.1. General Distribution

```text
                 SENSORS AND CONFIGURATION
                           |
          +----------------+----------------+
          |                |                |
          v                v                v
       +------+         +------+         +------+
       | MC01 |         | MC03 |         | MC04 |
       | SEQ. |         | ROLL |         | ALT. |
       +------+         +------+         +------+
          |
          | Commands and states
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
       | ROLL |         | ALT. |         | NAV. |
       +------+         +------+         +------+
                                          |
                                          | AP_TARGET_HEADING
                                          | Num 12
                                          v
                                       +------+
                                       | MC06 |
                                       | PROP.|
                                       +------+

       MC02 -----------+
       MC04 -----------+----> MC07 ----> HTTP
       MC05 -----------+
       MC06 -----------+
       SENSORS -------+
```

The diagram represents functional relationships. It does not mean that all signals must pass through MC02.

## 14.2. Main Command Flow

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

## 14.3. Navigation and Propulsion Flow

```text
POSITION SENSORS
COMPASS SENSOR
TARGET COORDINATES
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
                DIRECTIONAL BOOSTERS
```

## 14.4. Altitude Control Flow

```text
ALTITUDE SENSOR --------+
                        |
ALTITUDE_TARGET --------+
                        |
VERTICAL_SPEED SENSOR --+
                        |
PID_P / PID_I / PID_D --+
                        |
                        v
                 MC04 ALTITUDE
                        |
              +---------+---------+
              |                   |
              v                   v
          ELEVATORS       DESIRED_VERTICAL_SPEED
                                  |
                                  | MC04 Num 5
                                  v
                               MC07 Num 6
```

---

# 15. Assembly Validation Procedure

Validation must be performed module by module before testing the complete system.

## 15.1. Composite Connection Checks

- [ ] All microcontrollers are installed.
- [ ] Each Composite is connected to the corresponding module.
- [ ] Boolean channels are connected to Boolean inputs.
- [ ] Number channels are connected to Number inputs.
- [ ] Channel numbers match the tables.
- [ ] There are no unintended duplicate assignments.
- [ ] All required signals reach their destinations.

## 15.2. Sensor Checks

- [ ] Altitude sensor.
- [ ] Vertical speed sensor.
- [ ] RPS sensor.
- [ ] Horizontal tilt sensor.
- [ ] Vertical tilt sensor.
- [ ] Pitch sensor.
- [ ] X position sensor.
- [ ] Y position sensor.
- [ ] Compass sensor.
- [ ] Configuration values.

## 15.3. Module Checks

| Module | Test |
|---|---|
| MC01 | Sequence start, progression, and completion |
| MC02 | Signal reception and retransmission |
| MC03 | Stabilization activation and response |
| MC04 | PID control, elevator output, and desired vertical speed |
| MC05 | Position, distance, heading, and navigation output |
| MC06 | Main booster, acceleration, directional boosters, and spoiler |
| MC07 | Data reception and HTTP transmission |

## 15.4. Integration Tests

- [ ] MC01 correctly transmits commands to MC02.
- [ ] MC02 correctly retransmits commands to the corresponding modules.
- [ ] MC03 receives the stabilization command.
- [ ] MC04 receives altitude measurements and parameters.
- [ ] MC04 publishes `DESIRED_VERTICAL_SPEED` through Number 5.
- [ ] MC07 receives `DESIRED_VERTICAL_SPEED` through Number 6.
- [ ] MC05 transmits `AP_TARGET_HEADING` through Number 12.
- [ ] MC06 receives `AP_TARGET_HEADING` through Number 2.
- [ ] MC06 generates the expected propulsion commands.
- [ ] MC07 receives navigation data and status signals.
- [ ] MC07 transmits telemetry correctly.
- [ ] The sequence can be started again without retaining unwanted states.

---

# 16. Pending Integration Considerations

The following items must be checked during assembly and physical testing.

| Item | Status | Required Action |
|---|---|---|
| MC05 AP_TARGET_HEADING | Channel defined: Num 12 | Connect to MC06 Num 2 |
| MC04 DESIRED_VERTICAL_SPEED | Channel defined: Num 5 | Connect to MC07 Num 6 |
| MC05 AP_DISTANCE | Channel defined: Num 7 | Connect to MC07 Num 11 |
| MC06 booster reset | Pending validation | Check reset between flights |
| Physical actuator wiring | To be checked on the vehicle | Confirm the correspondence of each output |
| Physical Composite distribution | To be checked on the vehicle | Verify connections and branches |
| HTTP telemetry | Pending integrated test | Verify reception on port 8080 |

The logical connections specified in this document must be respected even if the physical wiring layout is different.

---

# 17. Maintenance and Expansion

The architecture allows new functions to be added without unnecessarily modifying other controllers.

Any change must meet the following conditions:

1. Maintain a clearly defined responsibility for each microcontroller.
2. Document every new input and output.
3. Avoid reusing already assigned channels.
4. Maintain the correspondence between data type and channel.
5. Update the master connection table.
6. Update the tables for each affected module.
7. Verify the connections of the modules receiving the signals.
8. Test both individual and combined operation.

New signals must first be added to the master connection table and then to the corresponding microcontroller sections.

---

# 18. Version Policy

The project uses two levels of versioning.

| Version | Meaning |
|---|---|
| System Version | Overall architecture version |
| Module Version | Individual microcontroller version |

Current system version:

`SYSTEM VERSION: 14.0`

Each module must include its own header:

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

When a connection is modified, the documentation for both the source and destination must be updated.

A channel modification is not considered complete until both ends have been documented and verified.

---

# 19. Project Philosophy

The OAI MIZUSHIMA YR-02 is based on three principles:

**Modularity:** each microcontroller has a clearly defined responsibility.

**Preservation:** original calculations and behavior must be maintained unless an intentional modification is made.

**Expandability:** new functions must be integrated without introducing unnecessary dependencies.

The objective is to maintain a flight control system that is organized, verifiable, and easy to maintain.

---

**OAI MIZUSHIMA YR-02**  
*Modular Flight Control System — System Version 14.0*