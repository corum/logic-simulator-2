class_name Block

# This Part allows for loading a circuit as a Block
# Then a part is created with inputs and outputs derived from the IO parts of the circuit.
# And the circuit within a block may also contain blocks.
# Have to think about a requested feature of surfacing embedded displays.
# This could be via a right-click feature.
# Also, there should be reports of how the block is comprised in terms of a tree.
# Again, a possible right-click feature.

extends Part

enum { PART, PORT }

var circuit
var parts = {}
var input_map = []
var output_map = []
var input_pin_count = 0
var output_pin_count = 0
var inputs = []
var outputs = []

func _init():
	data["circuit_file"] = ""


func block_setup():
	circuit = Circuit.new()
	var load_result = circuit.load_data(data.circuit_file)
	if load_result != OK:
		emit_signal("warning", "The circuit block data from %s was invalid!" % [data.circuit_file.get_file()])
		return
	# Every circuit opened as a block is added to the available parts list
	var cname = circuit.data.title
	if cname.is_empty():
		cname = data.circuit_file.get_file()
	if not G.settings.blocks.has(cname):
		G.settings.blocks[cname] = data.circuit_file
	for part in circuit.data.parts:
		if part.part_type == "IO":
			if is_input(part):
				inputs.append(part)
				input_pin_count += part.data.num_wires + 1
			if is_output(part):
				outputs.append(part)
				output_pin_count += part.data.num_wires + 1
	# Sort according to position offset
	inputs.sort_custom(compare_offsets)
	outputs.sort_custom(compare_offsets)
	# Create IO pin maps
	for io_part in inputs:
		# [part_name, port]
		input_map.append([io_part.node_name, 0])
		for n in io_part.data.num_wires:
			input_map.append([io_part.node_name, n + 1])
	for io_part in outputs:
		# [part_name, port]
		output_map.append([io_part.node_name, 0])
		for n in io_part.data.num_wires:
			output_map.append([io_part.node_name, n + 1])
	add_parts()


func _ready():
	super()
	block_setup()
	set_slots(max(input_pin_count, output_pin_count))
	configure_pins()


func configure_pins():
	clear_all_slots()
	var slot_idx = 1
	for input in inputs:
		var label_idx = 0
		set_slot_enabled_left(slot_idx, true)
		set_slot_type_left(slot_idx, BUS_TYPE)
		set_slot_color_left(slot_idx, Color.hex(input.data.bus_color))
		get_child(slot_idx).get_child(0).text = input.data.labels[label_idx]
		for n in input.data.num_wires:
			slot_idx += 1
			if label_idx + 1 < input.data.labels.size():
				label_idx += 1
			get_child(slot_idx).get_child(0).text = input.data.labels[label_idx]
			set_slot_enabled_left(slot_idx, true)
			set_slot_type_left(slot_idx, WIRE_TYPE)
			set_slot_color_left(slot_idx, Color.hex(input.data.wire_color))
		slot_idx += 1
	slot_idx = 1
	for output in outputs:
		var label_idx = 0
		set_slot_enabled_right(slot_idx, true)
		set_slot_type_right(slot_idx, BUS_TYPE)
		set_slot_color_right(slot_idx, Color.hex(output.data.bus_color))
		get_child(slot_idx).get_child(1).text = output.data.labels[label_idx]
		for n in output.data.num_wires:
			slot_idx += 1
			if label_idx + 1 < output.data.labels.size():
				label_idx += 1
			get_child(slot_idx).get_child(1).text = output.data.labels[label_idx]
			set_slot_enabled_right(slot_idx, true)
			set_slot_type_right(slot_idx, WIRE_TYPE)
			set_slot_color_right(slot_idx, Color.hex(output.data.wire_color))
		slot_idx += 1


func is_input(part):
	# If there are no wires connected to the part input side, then it is an input to the circuit.data
	for con in circuit.data.connections:
		if con.to == part.node_name:
			return false
	return true


func is_output(part):
	# If there are no wires connected to the part output side, then it is an output to the circuit.data
	for con in circuit.data.connections:
		if con.from == part.node_name:
			return false
	return true


func set_slots(num_slots):
	var num_pins = get_child_count() - 2
	var to_add = num_slots - num_pins
	# Text is added later if there is a pin
	$Slot1.get_child(0).text = ""
	$Slot1.get_child(1).text = ""
	if to_add > 0:
		for n in to_add:
			var slot = $Slot1.duplicate()
			slot.name = "Slot" + str(n + 2)
			add_child(slot)
		# Move Tag to the end
		var tag_node = $Tag
		remove_child(tag_node)
		add_child(tag_node)
	if to_add < 0:
		for n in -to_add:
			var node_to_remove = get_child(-2 - n)
			remove_child(node_to_remove)
			node_to_remove.queue_free()
	# Shrinking leaves a gap at the bottom
	size = Vector2.ZERO # Fit to the new size automatically


func add_parts():
	for node in circuit.data.parts:
		var part = Parts.get_instance(node.part_type)
		part.tag = node.tag
		part.part_type = node.part_type
		part.data = node.data
		# Part instances have a name but only circuit.data.parts have node_name
		part.name = node.node_name
		part.show_display = false
		part.controller = self
		add_connections_to_part(part)
		if part.part_type == "Block":
			part.block_setup()
		parts[part.name] = part


func get_map(side, port):
	return input_map[port] if side == LEFT else output_map[port]


# Map external input to internal part
func evaluate_output_level(side, port, level):
	if DEBUG:
		prints("block evaluate_output_level", self.name, side, port, level)
	var map = get_map(side, port)
	parts[map[PART]].update_output_level(FLIP_SIDES[side], map[PORT], level)


# Map external bus input to internal part
func evaluate_bus_output_value(side, port, value):
	var map = get_map(side, port)
	# Flip the side to the output side
	parts[map[PART]].update_output_value(FLIP_SIDES[side], map[PORT], value)


func output_level_changed_handler(part, side, port, level):
	if DEBUG:
		prints("block output_level_changed_handler", part.name, side, port, level)
	var map_idx = [str(part.name), port] # part.name seems to be a pointer to a string
	var port_idx = [input_map, output_map][side].find(map_idx)
	if port_idx > -1:
		controller.output_level_changed_handler(self, side, port_idx, level)
	else:
		update_internal_input_level(part, side, port, level)


func update_internal_input_level(part, side, port, level):
	if DEBUG:
		prints("block update_internal_input_level", part.name, side, port, level)
	var cons = part.connections.get([side, port])
	if cons:
		for connection in cons:
			parts[connection[0]].update_input_level(int(side == 0), connection[1], level)


func add_connections_to_part(part):
	for con in circuit.data.connections:
		if con.from == part.name:
			var key = [RIGHT, con.from_port]
			var value = [con.to, con.to_port]
			add_to_connections(part, key, value)
		elif con.to == part.name:
			var key = [LEFT, con.to_port]
			var value = [con.from, con.from_port]
			add_to_connections(part, key, value)


func add_to_connections(part, key, value):
	if part.connections.has(key):
		part.connections[key].append(value)
	else:
		part.connections[key] = [value]


func bus_value_changed_handler(part, side, port, value):
	var map_idx = [str(part.name), port]
	var port_idx = [input_map, output_map][side].find(map_idx)
	if port_idx > -1:
		controller.bus_value_changed_handler(self, side, port_idx, value)
	else:
		update_internal_bus_input_value(part, side, port, value)


func update_internal_bus_input_value(part, side, port, value):
	var cons = part.connections.get([side, port])
	if cons:
		for connection in cons:
			parts[connection[0]].update_bus_input_value(int(side == 0), connection[1], value)


func reset_block_race_counters():
	for part in parts.values():
		part.race_counter.clear()
		if part is Block:
			part.reset_block_race_counters()


func unstable_handler(_name, side, port):
	controller.unstable_handler(name + ":" + _name, side, port)


func compare_offsets(a, b):
		return Vector2(a.offset[0], a.offset[1]).length() < Vector2(b.offset[0], b.offset[1]).length()
