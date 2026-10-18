extends Control

const HEART_WIDTH := 26.0
const HEART_SPACING := 32.0
const MARGIN := Vector2(20.0, 24.0)
const FILLED_COLOR := Color(0.9, 0.22, 0.28)
const EMPTY_COLOR := Color(0.18, 0.18, 0.22, 0.65)

var _player = null
var _hp := 0.0
var _max_hp := 0
var _left_half := PackedVector2Array()
var _right_half := PackedVector2Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_heart()
	_player = get_tree().get_first_node_in_group("player")
	if _player != null:
		_player.health_changed.connect(_on_health_changed)
		_on_health_changed(_player.hp, float(_player.max_hp))


func _on_health_changed(current: float, maximum: float) -> void:
	_hp = current
	_max_hp = int(maximum)
	queue_redraw()


func _draw() -> void:
	for i in _max_hp:
		var center := MARGIN + Vector2(i * HEART_SPACING + HEART_WIDTH * 0.5, HEART_WIDTH * 0.5)
		_draw_heart(center, clampf(_hp - float(i), 0.0, 1.0))


func _draw_heart(center: Vector2, fill: float) -> void:
	_draw_poly(_right_half, center, EMPTY_COLOR)
	_draw_poly(_left_half, center, EMPTY_COLOR)
	if fill > 0.0:
		_draw_poly(_left_half, center, FILLED_COLOR)
	if fill >= 1.0:
		_draw_poly(_right_half, center, FILLED_COLOR)


func _draw_poly(points: PackedVector2Array, center: Vector2, color: Color) -> void:
	var moved := PackedVector2Array()
	for p in points:
		moved.append(p + center)
	var indices := Geometry2D.triangulate_polygon(moved)
	if indices.is_empty():
		draw_colored_polygon(moved, color)
		return
	var i := 0
	while i + 2 < indices.size():
		draw_colored_polygon(PackedVector2Array([moved[indices[i]], moved[indices[i + 1]], moved[indices[i + 2]]]), color)
		i += 3


func _build_heart() -> void:
	var steps := 48
	var raw := PackedVector2Array()
	var mn := Vector2(INF, INF)
	var mx := Vector2(-INF, -INF)
	for i in steps + 1:
		var t := TAU * float(i) / float(steps)
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		var p := Vector2(x, -y)
		raw.append(p)
		mn = mn.min(p)
		mx = mx.max(p)
	var factor := HEART_WIDTH / (mx.x - mn.x)
	var mid := (mn + mx) * 0.5
	var centered := PackedVector2Array()
	for p in raw:
		centered.append((p - mid) * factor)
	var half := steps / 2
	_right_half = centered.slice(0, half + 1)
	_left_half = centered.slice(half, steps + 1)
