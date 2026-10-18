extends Area2D

signal player_entered(portal: Area2D)

static var pending_spawn: StringName = &""

@export var trigger_size: Vector2 = Vector2(100.0, 100.0):
	set(value):
		trigger_size = value
		_apply_shape()

@export_file("*.tscn") var target_scene: String = ""
@export var target_spawn: StringName = &""
@export var one_shot: bool = true
@export var debug_draw: bool = true

var _armed := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_apply_shape()


func _apply_shape() -> void:
	var node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if node == null:
		return
	var rect := node.shape as RectangleShape2D
	if rect == null:
		rect = RectangleShape2D.new()
		node.shape = rect
	rect.size = trigger_size
	queue_redraw()


func _on_body_entered(body: Node2D) -> void:
	if not _armed or not body.is_in_group(&"player"):
		return
	if one_shot:
		_armed = false
	player_entered.emit(self)
	if target_scene.is_empty():
		print("[Portal] ", name, ": target_scene is empty, staying in this scene")
		return
	pending_spawn = target_spawn
	get_tree().call_deferred("change_scene_to_file", target_scene)


func _draw() -> void:
	if not debug_draw:
		return
	draw_rect(Rect2(-trigger_size * 0.5, trigger_size), Color(0.2, 0.8, 1.0, 0.6), false, 2.0)
