class_name SimConfig
extends RefCounted
## Fixed constants shared by the whole simulation.
##
## Values here affect determinism, so changing one changes the result of every
## stored snapshot. Tunable gameplay numbers belong in content Resources instead.

## Simulation steps per second of game time. Renderers interpolate between ticks.
const TICKS_PER_SECOND: int = 30

## Sim distances are integers in milli-cells: 1000 units = 1 grid cell.
## A speed of 1500 means 1.5 cells per second.
const UNITS_PER_CELL: int = 1000
