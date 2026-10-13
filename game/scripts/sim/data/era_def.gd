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
