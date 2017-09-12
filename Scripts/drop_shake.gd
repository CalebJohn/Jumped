extends Camera2D

# Taken from https://godotengine.org/qa/438/camera2d-screen-shake-extension?show=438#q438
# Written by: Hammer Bro
# Edited by: Me

export (int) var max_shake_sqr_vel = 2000000

var _max_duration = 0.4
var _duration = 0.4
var _frequency = 30
var _period_in_ms = 0.0
var _max_amplitude = 10
var _amplitude = 7
var _timer = 0.0
var _last_shook_timer = 0
var _previous_x = 0.0
var _previous_y = 0.0
var _last_offset = Vector2(0, 0)

# Shake with decreasing intensity while there's time remaining.
func _process(delta):
	# Only shake when there's shake time remaining.
	if _timer == 0:
		return
	# Only shake on certain frames.
	_last_shook_timer = _last_shook_timer + delta
	# Be mathematically correct in the face of lag; usually only happens once.
	while _last_shook_timer >= _period_in_ms:
		_last_shook_timer = _last_shook_timer - _period_in_ms
		# Lerp between [amplitude] and 0.0 intensity based on remaining shake time.
		var intensity = _amplitude * (1 - ((_duration - _timer) / _duration))
		# Noise calculation logic from http://jonny.morrill.me/blog/view/14
		var new_x = rand_range(-1.0, 1.0)
		var x_component = intensity * (_previous_x + (delta * (new_x - _previous_x)))
		var new_y = rand_range(-1.0, 1.0)
		var y_component = intensity * (_previous_y + (delta * (new_y - _previous_y)))
		_previous_x = new_x
		_previous_y = new_y
		# Track how much we've moved the offset, as opposed to other effects.
		var new_offset = Vector2(x_component, y_component)
		set_offset(get_offset() - _last_offset + new_offset)
		_last_offset = new_offset
	# Reset the offset when we're done shaking.
	_timer = _timer - delta
	if _timer <= 0:
		_timer = 0
		set_offset(get_offset() - _last_offset)

# Kick off a new screenshake effect.
func shake(vel_sqr_amp):
	_amplitude = _max_amplitude * vel_sqr_amp / max_shake_sqr_vel
	_duration = _max_duration
	if vel_sqr_amp > max_shake_sqr_vel:
		_duration *= vel_sqr_amp / max_shake_sqr_vel
	# Initialize variables.
	_timer = _duration
	_period_in_ms = 1.0 / _frequency
	_previous_x = rand_range(-1.0, 1.0)
	_previous_y = rand_range(-1.0, 1.0)
	# Reset previous offset, if any.
	set_offset(get_offset() - _last_offset)
	_last_offset = Vector2(0, 0)

func _ready():
	set_process(true)