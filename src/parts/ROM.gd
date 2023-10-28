class_name ROM

extends Part

var max_value = 0
var max_address = 0
var values = []
var old_address = 0

func _init():
	order = 80
	category = ASYNC
	data["bits"] = 16
	data["size"] = "8K"
	pins = { [0, 0]: 0, [0, 1]: 0 }


func _ready():
	super()
	set_max_value()
	%Bits.text = str(data.bits)
	max_address = get_max_address(data.size)
	resize_memory(max_address + 1)
	$Size.text = data.size


func _on_size_text_submitted(new_text):
	if new_text.length() > 0:
		if new_text.is_valid_int() or new_text.right(1) in ["K", "M"]\
			and new_text.left(-1).is_valid_int():
				data.size = new_text
				max_address = get_max_address(data.size)


func _on_bits_text_submitted(new_text):
	if new_text.is_valid_int():
		data.bits = clampi(int(new_text), 1, 1024)
		set_max_value()
	else:
		%Bits.text = ""


func set_max_value():
	max_value = int(pow(2, data.bits) - 1)


func get_max_address(dsize: String) -> int:
	var n = 0
	if dsize.is_valid_int():
		n = int(dsize)
	else:
		n = int(dsize.left(-1))
		if dsize.right(1) == "M":
			n *= 1000
		n *= 1000
	return n - 1


func evaluate_bus_output_value(side, port, _value):
	if side == LEFT and port == 1: # Change of address
		set_output_data()


func set_output_data():
	var address = clampi(pins[[LEFT, 1]], 0, max_address)
	$Address.text = "%04X" % [address]
	$Data.text = "%02X" % [values[address]]
	update_output_value(RIGHT, OUT, values[address])


func resize_memory(num_bytes):
	values.resize(num_bytes)
	values.fill(0)
