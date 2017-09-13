##shader can handle a maximum of two lights
##more could be added but for the sake of complexity I left it at two
#lights are simply locations, as the color is handled outside of light

#all color scheme is based on terrain_color, which should be extracted from
#this node by calling get_terrain_color() every frame and setting terrain
#accordingly

#set_resolution must be called if resolution different from 1024,600

#set speed must be called every frame to accurately move lights

#lights exist in a conic volume of extents (-z*aspect-z*aspect, -z-z, 0-10)

#a higher falloff value decreases the reach of the light, thus decreasing the size of the light

#HDR is used to turn HDR on (1.0) or off (0.0)

#posibble improvements include:
#	arbitrary lights
#	3d noise for light behavior
extends CanvasLayer


var noise = preload("noise.gd").new()
var shader
var terrain_color = Color(0.2, 0.3, 0.6)
var aspect = 1024.0/600.0
var speed = Vector3(0.0, 0.0, 0.0)

#parameters to be passed to shader
var light1
var color1 = Color(0.5, 0.3, 0.3)
var light2
var color2 = Color(0.4, 0.7, 0.3)
var HDR
var falloff
var density
var con = 0.08
var background = Color(0.1, 0.5, 0.8)


class Light:
	var pos
	var aspect
	var falloff
	var density
	var noise = preload("noise.gd").new()
	var con
	signal move(x, y)
	func _init(x, y, z, a, f, d, c):
		pos = Vector3(x, y, z)
		aspect = a
		falloff = f
		density = d
		con = c
	func fadein(x):
		pos.z = x

	func constant(x, y):
		pos.y-= y*0.02
		pos.x-= x*0.02*aspect
	
	func noise(x=0, y=0, o=0, s=1, a = 1.0):
		pos.x -= 0.05*x
		pos.y -= 0.05*y
		var n = noise.simplex(pos*0.03*s+Vector3(o, o, 0))*4.0*a
		var dir = Vector3(sin(n), cos(n), 0)
		pos+=dir*0.08

	func curl(x=0, y=0, o=0, s=1, a = 0.05):
		pos.x-= 0.005*x*pos.z
		pos.y-= 0.005*y*pos.z#automatically scale by distance
		var n = noise.curl(pos*0.1*s+Vector3(o, o, 0))*a
		pos+=Vector3(n.x, n.y, 0)
	func noisez(x=1, y=1, o=0, s=1, a=1):
		pos.z += noise.simplex(pos*0.01*s*Vector3(x, y, 0)+Vector3(o,o,0))*a
		
	func on_screen():
		var on = true
		var center_on = true
		var dist = 0.0
		if pos.x<-pos.z*aspect:
			dist = -pos.x-pos.z*aspect
			center_on = false
		elif pos.x>pos.z*aspect:
			dist = pos.x-pos.z*aspect
			center_on = false
		if pos.y>pos.z:
			dist = max(dist, pos.y-pos.z)
			center_on = false
		elif pos.y<-pos.z:
			dist = max(dist, -pos.y-pos.z)
			center_on = false
		if pos.z>15:
			on = false
			
		if not center_on:
			pos.z+=0.01
		
		var atten = exp(-density*dist)/(dist*dist*falloff)
		if atten<1.0:
			on= false
		return on

#returns the color of terrain to update in main game loop
func get_terrain_color():
	return terrain_color

#this will offset the light speed so that it appears that the lights are detached from the screen
#should be updated every frame so that the speed is accurate
func set_speed(x):
	speed = Vector3(x.x, x.y, 0.0)

func set_resolution(x, y):
	shader.set_shader_param("resolution", Vector2(x, y))
	aspect = x/y
	
func set_HDR(val):
	HDR = val
	shader.set_shader_param("HDR", val)

func set_falloff(val):
	falloff = val
	shader.set_shader_param("falloff", val)

func set_density(val):
	density = val
	shader.set_shader_param("density", val)

func _process(delta):
	shader.set_shader_param("background", background)
	background.v = 0.5
	background.s = 0.7
	background.h +=0.001
	color1.v = 1.0
	color1.s = 1.0
	color1.h = background.h+0.6
	color2.v = 1.0
	color2.s = 1.0
	color2.h = background.h+0.4

	if light1.pos.z<light2.pos.z:
		terrain_color.h = (color1.h+0.5)
		if light2.pos.z-light1.pos.z<3.0:
			var mix = (light2.pos.z-light1.pos.z)/3.0
			terrain_color.h = (color1.h+0.5)*mix+(color2.h+0.5)*(1.0-mix)
	else:
		terrain_color.h = (color2.h+0.5)
		if light1.pos.z-light2.pos.z<3.0:
			var mix = (light1.pos.z-light2.pos.z)/3.0
			terrain_color.h = (color2.h+0.5)*mix+(color1.h+0.5)*(1.0-mix)
	light1.emit_signal("move")
	light2.emit_signal("move")
	light1.pos-=speed
	light2.pos-=speed
	if not light1.on_screen():
		replace_light(1)
	if not light2.on_screen():
		replace_light(2)
	shader.set_shader_param("light1", light1.pos)
	shader.set_shader_param("light2", light2.pos)
#	shader.set_shader_param("color2", Vector3(color2.r, color2.g, color2.b))
	shader.set_shader_param("color1", Vector3(color1.r, color1.g, color1.b))

#updates colors based on terrain color
func update_colors():
	pass

# replacing light should really just move their position and path
#as color should be set globally for aesthetic reasons
func replace_light(number):
	#number 1 tends to be large and slow 
	if number == 1:
		var z = pow(randf(), 3)*7.0
		var x = (randf()*2.0-0.6)*z*aspect
		var y = (randf()*2.0-1.0)*z
		light1 = Light.new(x, y, 15, aspect, falloff, density, con)
		var twee = Tween.new()
		add_child(twee)
		twee.set_tween_process_mode(0)
		twee.interpolate_method(light1, "fadein", 15.0, z, 5, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		light1.connect("move", light1, "curl", [(randf()-0.5)*0.5, 0, randi(), 0, 0])
		if randf()<0.1:
			light1.connect("move", light1, "noisez", [1,1])
		twee.start()
		#replace light 1
		##change colors onlywhen new light appears
#		shader.set_shader_param("color1", Vector3(color1.r, color1.g, color1.b))
	#number 2 is going to move quicker and more erratically
	elif number == 2:
		var z = pow(randf(), 2)*10.0
		var x = (randf()*2.0-0.8)*z*aspect
		var y = (randf()*2.0-1.0)*z
		light2 = Light.new(x, y, 15, aspect, falloff, density, con)
		var twee = Tween.new()
		add_child(twee)
		twee.set_tween_process_mode(0)
		twee.interpolate_method(light2, "fadein", 15.0, z, 3, Tween.TRANS_QUAD, Tween.EASE_IN_OUT)
		light2.connect("move", light2, "curl", [randf()-0.5, 0, randi(), 1+(randf()-0.5)*0.2, 0.05])
		if randf()<0.1:
			light2.connect("move", light2, "noisez", [1,1])
		twee.start()
		##replace light 2
		shader.set_shader_param("color2", Vector3(color2.r, color2.g, color2.b))
	else:
		print(number+ " is not a valid light identifier number")
	
func _ready():
	shader = get_node("backQuad").get_material()
	randomize()
	set_falloff(0.01)
	set_HDR(1.0)
	set_density(0.03)
	shader.set_shader_param("con", con)
	light1 = Light.new(0, -100, 2, aspect, falloff, density, con)
	
	light2 = Light.new(10, 100, 13, aspect, falloff, density, con)
	terrain_color.v = 0.25
	terrain_color.s = 0.6
	set_process(true)
