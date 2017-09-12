extends RigidBody2D

export (int) var min_speed = 50
export (float) var gravity_mult = 5
export (float) var gravity_penalty = 3
export (int) var maximum_stretch_point = 800
export (int) var start_stretch_point = 0
export (float) var min_gravity = 0.5
export (float) var shake_trigger = 0.5

var gravity_default = 1
var moving_up = false
var gravity_on = false
var prev_vel = Vector2(0, 0)

signal shake_camera

func smooth(x):
	return abs(x*x*(3 - 2*x))

func _integrate_forces(state):
	var y = get_pos().y
	if y < -start_stretch_point:
		set_rot(0)
		y = max(y, -maximum_stretch_point)
		var stretch = smooth((y + start_stretch_point) / -maximum_stretch_point)
		get_node("Shape").shape(min(2, stretch + 1))
		if not gravity_on:
			set_gravity_scale(gravity_default - (gravity_default - min_gravity) * stretch)
	
	var vel = get_linear_velocity()
	if vel.x < min_speed:
		set_linear_velocity(Vector2(min_speed, vel.y))

	elif vel.y < 0:
		if not moving_up and gravity_on:
			set_gravity_scale(gravity_penalty)
		moving_up = true
	elif vel.y >= 0:
		if gravity_on:
			set_gravity_scale(gravity_mult)
		else:
			moving_up = false
	
	if vel.length_squared() < shake_trigger * prev_vel.length_squared():
		emit_signal("shake_camera", prev_vel.length_squared())
	prev_vel = vel

func _input(event):
	if event.type == InputEvent.SCREEN_TOUCH:
		if event.pressed:
			set_gravity_scale(gravity_mult)
			gravity_on = true
		else:
			set_gravity_scale(gravity_default)
			gravity_on = false
	
func _ready():
	gravity_default = get_gravity_scale()
	set_process_input(true)