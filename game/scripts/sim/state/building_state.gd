class_name BuildingState
extends Resource
## A building under construction or finished.

@export var id: StringName = &""
@export var def_id: StringName = &""
@export var complete: bool = false
## Builder-ticks of work done so far.
@export var progress: float = 0.0
@export var started_tick: int = 0
@export var completed_tick: int = 0
