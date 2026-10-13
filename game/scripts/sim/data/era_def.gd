class_name EraDef
extends Resource
## An age of the settlement's long arc (Cave Age, Settled Age...). An age is a content and art
## pack plus a tech level; content is gated by era through conditions on `order`.

@export var id: StringName = &""
@export var display_name: String = ""
## Position in the timeline, starting at 0. Conditions compare against this.
@export_range(0, 20) var order: int = 0
@export_multiline var description: String = ""
## Journal line written when the settlement enters this age.
@export_multiline var intro_text: String = ""
@export_group("Entry gate (never shown to the player)")
## Achievements the settlement must have earned before it can enter this age.
@export var required_achievements: Array[StringName] = []
## How long the settlement must have spent in the previous age, in ticks. Stops luck from
## rushing an age; time while the game is closed counts.
@export var min_ticks_in_previous_era: int = 0
## Optional event fired when the gate opens. Every one of its choices must ADVANCE_ERA to this
## age: it decides how the settlement turns, not whether. Empty means advance immediately.
@export var turn_event: StringName = &""
