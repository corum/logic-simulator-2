extends Part

class_name Gnd

func _init():
	category = UTILITY
	order = 80


func _ready():
	super()
	set_color()


func reset():
	super()
	call_deferred("apply_power")


func apply_power():
	update_output_level(RIGHT, 1, false)
	update_output_value(RIGHT, 0, 0)


func set_color():
	$ColorRect.color = G.settings.logic_low_color
	set_slot_color_right(1, G.settings.logic_low_color)
