extends Button

@export var amplitude: float = 0.06
@export var speed: float = 18.0
@export var pop: float = 1.6

var _time := 0.0
var _hovered := false


func _ready() -> void:
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	resized.connect(_center_pivot)
	_center_pivot()


func _on_mouse_entered() -> void:
	_hovered = true
	_time = 0.0


func _on_mouse_exited() -> void:
	_hovered = false


func _process(delta: float) -> void:
	if _hovered:
		_time += delta
		var strength := amplitude * (1.0 + pop * exp(-4.0 * _time))
		var offset := strength * sin(_time * speed)
		scale = Vector2(1.0 + offset, 1.0 - offset)
	elif scale != Vector2.ONE:
		scale = scale.lerp(Vector2.ONE, minf(delta * 16.0, 1.0))
		if scale.distance_to(Vector2.ONE) < 0.002:
			scale = Vector2.ONE


func _center_pivot() -> void:
	pivot_offset = size * 0.5
