class_name VillagerPlan
extends RefCounted
## Where a villager should be and what they should be doing, as the view sees it.

const HIDDEN_ASLEEP: StringName = &"asleep"
const HIDDEN_AWAY: StringName = &"away"

var visible: bool = true
## Why they are out of sight, when not visible.
var hidden_reason: StringName = &""
## Feet position in art pixels.
var target: Vector2 = Vector2.ZERO
## idle, chop or hammer: what to do on arrival.
var pose: StringName = &"idle"
## Face towards this x on arrival (-1 to keep the walking direction).
var focus_x: float = -1.0
## True for aimless wandering: the actor keeps its current goal until it reaches it.
var wander: bool = false
