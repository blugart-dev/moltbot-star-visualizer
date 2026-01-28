class_name MilestoneParticles
extends GPUParticles3D
## Subtle particle burst effect for milestone celebrations.
##
## Triggers a one-shot particle explosion when milestones are reached.
## Intensity scales with milestone size.

## Base number of particles for smallest milestone.
@export var base_amount: int = 50

## Maximum number of particles for largest milestone.
@export var max_amount: int = 200


func _ready() -> void:
	emitting = false
	one_shot = true
	explosiveness = 0.9


## Triggers a celebratory particle burst scaled to the milestone size.
func trigger_burst(milestone: int, _star_count: int = 0) -> void:
	var intensity := _calculate_intensity(milestone)
	amount = int(base_amount + intensity * (max_amount - base_amount))
	emitting = true


func _calculate_intensity(milestone: int) -> float:
	if milestone >= 50000:
		return 1.0
	elif milestone >= 10000:
		return 0.7
	elif milestone >= 1000:
		return 0.4
	return 0.2
