extends CharacterBody2D

signal health_changed(current: int, maximum: int)

const HURT_COLOR := Color(1.0, 0.4, 0.4)

@export var speed: float = 120.0
@export var max_hp: int = 5
@export var invincible_time: float = 0.6
@export var blink_interval: float = 0.08

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var hp: int
var _facing := "down"
var _invincible := 0.0
var _dead := false


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_update_hurt(delta)
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = direction * speed
	move_and_slide()
	_update_animation(direction)


func take_damage(amount: int = 1) -> void:
	if _dead or _invincible > 0.0:
		return
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	_invincible = invincible_time
	sprite.modulate = HURT_COLOR
	if hp == 0:
		_die()


func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.play(&"death")


func _update_hurt(delta: float) -> void:
	if _invincible <= 0.0:
		return
	_invincible = maxf(_invincible - delta, 0.0)
	if _invincible == 0.0:
		sprite.modulate = Color.WHITE
		return
	var alpha := 0.3 if fmod(_invincible, blink_interval * 2.0) < blink_interval else 1.0
	sprite.modulate = Color(HURT_COLOR.r, HURT_COLOR.g, HURT_COLOR.b, alpha)


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
