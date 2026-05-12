# Bachelor_Project_P6 : Aircraft Boarding CPS

This repository contains the implementation of a Cyber-Physical System (CPS) model for simulating aircraft boarding. The project models passenger boarding as a state-based simulation, where global boarding control logic interacts with individual passenger behavior inside a simplified aircraft cabin.

The goal is to evaluate how different boarding strategies and control policies affect boarding performance, while ensuring that the simulation remains valid and consistent with the model constraints.

## Project Overview

Aircraft boarding is a time-dependent and variable process where passenger behavior, aircraft layout, luggage handling, and boarding rules influence each other. Delays may occur when passengers block the aisle, stow luggage, wait for access to their row, or experience seat interference.

This project approaches aircraft boarding as a CPS by separating the system into two interacting parts:

- **Global state machine**: represents the supervisory control logic of the boarding process.
- **Passenger state machine**: represents the behavior of each individual passenger from gate to seat.

These state machines make it possible to simulate boarding under controlled assumptions and compare different boarding strategies.

## Main Features

- FSM-based aircraft boarding simulation
- Global boarding control with phases such as preboarding, general boarding, hold, final call, and door closed
- Individual passenger behavior modeled through states such as at gate, scanned, in corridor, in aisle, waiting, stowing luggage, seating, and seated
- Shared aircraft resources such as aisle positions and seats
- Modeling of aisle blocking and seat interference
- Support for assigned seating
- Comparison of selected boarding strategies
- Evaluation using correctness checks and boarding performance measures

## Boarding Strategies

The project focuses on selected boarding strategies. These include:

- Random boarding
- Back-to-front boarding
- Outside-in boarding
- Reverse pyramid boarding
- Half-Block mix boarding
- Steffen boarding

These strategies can be compared under the same operating conditions to analyze their impact on boarding time, congestion, waiting time, and interference.

## Model Structure

### Global State Machine

The global state machine controls the overall boarding process. It handles:

- Boarding phases
- Scanner status
- Passenger admission rate
- Boarding eligibility filters
- Corridor congestion
- Door closing

The main global states are:

- `Init`
- `Preboard`
- `General`
- `Hold`
- `Final Call`
- `Door Closed`

### Passenger State Machine

Each passenger is modeled as an individual state machine. This allows passenger-specific behavior such as walking speed, assigned seat, luggage status, and waiting time to affect the simulation.

The main passenger states are:

- `At Gate`
- `Scanned`
- `In Corridor`
- `In Aisle`
- `Advance`
- `Waiting`
- `At Row`
- `Stowing Luggage`
- `Seating`
- `Waiting For Seat`
- `Seated`

## Simulation Scope

The simulation is limited to the boarding process inside the aircraft cabin. It starts when passengers are called to board and ends when all passengers are seated.

Included in the model:

- Assigned seating
- A single-aisle aircraft layout
- One front boarding door
- Passenger movement through corridor and aisle
- Luggage stowage
- Aisle blocking
- Seat interference
- Priority boarding conditions
- Boarding strategy rules

Outside the scope:

- Open seating strategies
- Deboarding
- Airport logistics outside the boarding process
- Checked baggage loading
- Cabin crew operations
- Multiple aircraft doors

## Evaluation

The model can be evaluated using two categories of measures.

### Correctness and Validity Checks

These checks ensure that the simulation does not produce impossible states:

- All passengers are eventually seated
- No passenger remains indefinitely in the corridor or queue
- At most one passenger occupies a seat
- At most one passenger occupies each aisle position at a time

### Performance Measures

These measures are used to compare boarding strategies:

- Total boarding time
- Scanner utilization
- Average and peak aisle occupancy
- Average and peak corridor occupancy
- Total waiting time in the aisle
- Queue and congestion behavior

## Repository Structure

```text
.
├── README.md
├── src/
│   ├── main.m
├── tests/
│  
├── data/
├── results/
└── docs/
```

## Getting Started

### Prerequisites

### Installation

### Running the Simulation

## Contributors

- Casper 
- Elma 
- Nelisa 
- Oskar 

## Project Context

This project was developed as part of the 6th semester Computer Science project at Aalborg University.

## License

This repository is currently intended for academic project work. Add a license file if the repository should be made public or reused by others.
