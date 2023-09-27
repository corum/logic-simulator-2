extends Control

func _ready():
	var add_part_menu: PopupMenu = $VB/HB/AddPartMenu.get_popup()
	for part_name in Parts.names:
		add_part_menu.add_item(part_name)
	add_part_menu.index_pressed.connect(part_to_add)


func part_to_add(part_index):
	var part_name = Parts.names[part_index]
	$VB/Schematic.add_part(part_name)


func _on_save_button_pressed():
	$VB/Schematic.save_circuit()


func _on_load_button_pressed():
	$VB/Schematic.load_circuit()
