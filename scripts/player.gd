extends CharacterBody2D

@export var speed: float = 120.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _facing := "down"


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)


func _update_animation(direction: Vector2) -> void:
	var moving := direction != Vector2.ZERO
	if moving:
		if absf(direction.x) >= absf(direction.y):
			_facing = "right" if direction.x > 0.0 else "left"
		else:
			_facing = "down" if direction.y > 0.0 else "up"

	var anim_dir := "right" if _facing == "left" else _facing
	sprite.flip_h = _facing == "left"

	var anim_name := ("walk_" if moving else "idle_") + anim_dir
	if sprite.animation != anim_name:
		sprite.play(anim_name)
