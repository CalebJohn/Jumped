extends StaticBody2D

export (int) var resolution = 10

onready var area2d = get_node("Area2D")

func interp(x, y1, y2):
	var s = x*x*(3 - 2*x)
	return y1 + (y2 - y1)*s
	
func start_segment(V):
	var s = SegmentShape2D.new()
	s.set_a(V[-1])
	return s
	
func add_seg(V):
	var s = SegmentShape2D.new()
	s.set_a(V[-2])
	s.set_b(V[-1])
	add_shape(s)
	area2d.add_shape(s)
	
func hill_point(i, left, right, width, offset):
	return Vector2(i * width + offset, interp(i, left, right))
	
func curve(i, width, height, offset):
	return cos(i * resolution * (2 * PI) / width) * (height / 2) + offset

func fract(x):
	return x - x.floor()
func fractf(x):
	return x - floor(x)
func dot(v1, v2):
	return v1.dot(v2)
func mix(x, y, a):
	return x * (1 - a) + y * a

func hassh(x):
	var k = Vector2( 0.3183099, 0.3678794 )
	x = x * k + Vector2(k.y, k.x)
	return Vector2(-1.0, -1.0) + 2.0*fract( 16.0 * k*fractf( x.x*x.y*(x.x+x.y)))
#	return Vector2(fractf(sin(x.dot(Vector2(48.17, 83.37)))*43542.2156), fractf(sin(x.dot(Vector2(18.39, 43.71)))*34517.3751))
		
func smooth(f):
	return f * f * 3.0 - 2.0 * f * f * f

func noise(x):
	var p = Vector2(x + 0.05, 0.0)
	var i = p.floor()
	var f = fract(p)

	var u = smooth(f)
	return mix( mix( dot( hassh( i + Vector2(0.0,0.0) ), f - Vector2(0.0,0.0) ), 
					dot( hassh( i + Vector2(1.0,0.0) ), f - Vector2(1.0,0.0) ), u.x),
				mix( dot( hassh( i + Vector2(0.0,1.0) ), f - Vector2(0.0,1.0) ),
					dot( hassh( i + Vector2(1.0,1.0) ), f - Vector2(1.0,1.0) ), u.x), u.y)

func set_layer(layer):
	set_layer_mask(layer)
	area2d.set_layer_mask(layer ^ 3)
	
func can_switch(name):
	print("-----------")
	for b in area2d.get_overlapping_bodies():
		print(b.get_name())
#		if b.get_name() == name:
#			return false
	return true

func spawn(hill_width, num_hills, offset):
	set_pos(Vector2(offset, get_pos().y))
	clear_shapes()
	var Vec2 = Vector2Array()
	var Colours = ColorArray()
	# Add point on the bottom of the screen
	Vec2.append(Vector2(0, -100))
	Colours.append(Color(1, 1, 1, 1))
	
	var size = hill_width * num_hills / resolution

	for i in range(size):
#		var p = Vector2(i * resolution, curve(i, hill_width, 200, 205) + curve(i, 400, 20, 0))
		var p = Vector2(i * resolution, (noise(i * resolution / hill_width + offset) + 0.5) * 600)
		
		var hw = hill_width / resolution
		# Smooths terrain in and out for transitions
		if i < hw:
			p.y *= smooth(i / hw)
		elif i > size - hw:
			p.y *= smooth((size - i) / hw)
			
		Vec2.append(p)
		Colours.append(Color(0, 1 - i / float(size), i / float(size), 1))
		add_seg(Vec2)
		
	# Add point on bottom of screen
	Vec2.append(Vector2(size * resolution, -100))
	add_seg(Vec2)
	
	get_child(0).set_polygon(Vec2)
	get_child(0).set_vertex_colors(Colours)