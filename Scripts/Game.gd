extends Node

onready var ball = get_node("Ball")
onready var terrainb = get_node("Terrainb")
onready var terrainf = get_node("Terrainf")

func _process(delta):
	if Input.is_action_pressed("ui_cancel"):
		get_tree().quit()
		
func _input(event):
	if event.type == InputEvent.SCREEN_TOUCH:
		if event.pressed:
			if event.x < get_viewport().get_rect().size.width / 2:
				print("terrain b---")
				if ball.get_collision_mask() == 1 and terrainb.can_switch(ball.get_name()):
					ball.set_collision_mask(ball.get_collision_mask() ^ 3)
				print("terrain a---")
				if ball.get_collision_mask() == 2 and terrainf.can_switch(ball.get_name()):
					ball.set_collision_mask(ball.get_collision_mask() ^ 3)
#				terrainf.set_z(terrainf.get_z() ^ 1)
#				terrainb.set_z(terrainb.get_z() ^ 1)

func _ready():
	set_process(true)
	set_process_input(true)
