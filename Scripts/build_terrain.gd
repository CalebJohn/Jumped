extends Node2D

export (float) var hill_width = 1000.0
export (int) var num_hills = 60
export (int) var hill_separation = 500
export (int) var layer = 1

var hill = preload("../Scenese/Hill.tscn").instance()
onready var ball = get_node("../Ball")
var hills = Array()
var current_hill = 0
var hill_position = 0

func _process(delta):
	if ball.get_pos().x - hill_position > (num_hills * hill_width) * 0.8:
		hill_position += hill_separation + num_hills * hill_width
		gen_hill()

func gen_hill():
	var h = hills[current_hill]
	h.spawn(hill_width, num_hills, hill_position)
	
	current_hill += 1
	
	if current_hill > 1:
		current_hill = 0
		
func can_switch(name):
	for h in hills:
		if not h.can_switch(name):
			return false
	return true

func _ready():
	set_process(true)
	hills.append(hill.duplicate(true))
	hills.append(hill.duplicate(true))
	
	for h in hills:
		add_child(h)
		h.set_layer(layer)
		
	# These spawns an unseen dumby because godot will use a default collider
	hills[1].spawn(hill_width, num_hills, -2 * num_hills * hill_width)
	gen_hill()
