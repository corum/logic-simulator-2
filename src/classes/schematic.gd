class_name Schematic

extends GraphEdit

const PART_INITIAL_OFFSET = Vector2(50, 50)

var part_scene = preload("res://parts/part.tscn")
var circuit: Circuit
var selected_parts = []
var part_initial_offset_delta = Vector2.ZERO

func _ready():
	circuit = Circuit.new()
	node_deselected.connect(deselect_part)
	node_selected.connect(select_part)
	delete_nodes_request.connect(delete_selected_parts)
	connection_request.connect(connect_wire)
	disconnection_request.connect(disconnect_wire)
	duplicate_nodes_request.connect(duplicate_selected_parts)


func connect_wire(from_part, from_pin, to_part, to_pin):
	# Add guards against invalid connections
	connect_node(from_part, from_pin, to_part, to_pin)
	# Propagate bus value or level


func disconnect_wire(from_part, from_pin, to_part, to_pin):
	disconnect_node(from_part, from_pin, to_part, to_pin)


func remove_connections_to_part(part):
	for con in get_connection_list():
		if con.to == part.name or con.from == part.name:
			disconnect_node(con.from, con.from_port, con.to, con.to_port)


func clear():
	clear_connections()
	for node in get_children():
		if node is Part:
			node.queue_free()


func select_part(part):
	selected_parts.append(part)


func deselect_part(part):
	selected_parts.erase(part)


func delete_selected_parts(_arr):
	# _arr only lists parts with a close button
	for part in selected_parts:
		delete_selected_part(part)
	selected_parts.clear()
	circuit.connections = get_connection_list()


func delete_selected_part(part):
	for con in get_connection_list():
		if con.to == part.name or con.from == part.name:
			disconnect_node(con.from, con.from_port, con.to, con.to_port)
	part.queue_free()


func duplicate_selected_parts():
	var offset = get_local_mouse_position()
	var first_part = true
	for part in selected_parts:
		if first_part:
			first_part = false
			offset = abs(offset) - part.position_offset
		var new_part = part.duplicate()
		new_part.selected = false
		new_part.position_offset += offset
		new_part.name = "part" + circuit.get_next_id()
		add_child(new_part)


func add_part():
	var part = part_scene.instantiate()
	part.position_offset = PART_INITIAL_OFFSET + scroll_offset / zoom \
		+ part_initial_offset_delta
	var x = part_initial_offset_delta.x
	var y = part_initial_offset_delta.y
	y += 20
	if y > 60:
		y = 0
		x += 20
		if x > 60:
			x = 0
	part_initial_offset_delta = Vector2(x, y)
	part.name = "part" + circuit.get_next_id()
	part.node_name = part.name
	add_child(part)


func save_circuit():
	circuit.connections = get_connection_list()
	circuit.parts = []
	for node in get_children():
		if node is Part:
			circuit.parts.append(node)
	circuit.snap_distance = snap_distance
	circuit.use_snap = use_snap
	circuit.minimap_enabled = minimap_enabled
	circuit.zoom = zoom
	circuit.scroll_offset = scroll_offset
	circuit.save_data("res://temp.tres")


func load_circuit():
	clear()
	setup_graph()
	# Be sure that the old circuit nodes have been deleted
	await get_tree().create_timer(0.1).timeout
	circuit = Circuit.new().load_data("res://temp.tres")
	add_parts()
	add_connections()


func add_parts():
	for node in circuit.parts:
		var part = part_scene.instantiate()
		add_child(part)
		part.name = node.node_name
		part.position_offset = node.position_offset


func add_connections():
	for con in circuit.connections:
		connect_node(con.from, con.from_port, con.to, con.to_port)


func setup_graph():
	snap_distance = circuit.snap_distance
	use_snap = circuit.use_snap
	zoom = circuit.zoom
	scroll_offset = circuit.scroll_offset
	minimap_enabled = circuit.minimap_enabled
