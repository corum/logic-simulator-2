class_name MemoryProbe

extends Part

# This needs to be set when connecting to this part
var memory: BaseMemory

func fetch_data():
	if memory and memory.values.size() > data.address:
		return memory.values[data.address]
	else:
		return 0


# Called from Memory part when the values change
func update_data():
	var value = fetch_data()
	display_data(value)
	update_output_value(RIGHT, OUT, value)


func _init():
	category = UTILITY
	order = 72
	data["address"] = 0


func _ready():
	super()
	display_address(data.address)


func _on_address_text_submitted(new_text):
	var value = 0
	if new_text.is_valid_int():
		value = int(new_text)
	if new_text.is_valid_hex_number(true):
		value = new_text.hex_to_int()
	display_address(value)
	data.address = value
	update_data()


func display_address(value):
	%Address.text = get_display_hex_value(value)
	# The following line avoids the caret blinking at the start of the text
	%Address.caret_column =%Address.text.length()


func display_data(value):
	%Data.text = get_display_hex_value(value)
