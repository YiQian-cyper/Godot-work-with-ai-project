extends Control

@export var amplitude: float = 0
@export var speed: float = 26.0
@export var speed_v: float = 33.0

var _base := Vector2.ZERO
var _applied := Vector2.ZERO
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	if position != _base + _applied:
		_base = position
	var offset := Vector2(sin(_time * speed), cos(_time * speed_v)) * amplitude
	_applied = offset
	position = _base + offset
