extends Polygon2D

export (int) var points = 180
export (int) var radius = 25

# For drawing the disk
var max_s = 2
var stretch = 1

func shape(strch):
	var arr = Vector2Array()
	var unit = Vector2(radius, 0)
	for i in range(points):
		var angle = 2 * PI * i / points
		var vec = unit.rotated(angle)
		vec.x *= cos(angle) * 0.5 * (strch - 1) + strch
		vec.y /= (max_s - 1) * (strch - 1) + strch
		arr.append(vec)
	set_polygon(arr)

func _ready():
	shape(stretch)
