extends CharacterBody2D

signal health_changed(current: float, maximum: float)

const HURT_COLOR := Color(1.0, 0.4, 0.4)

@export var speed: float = 120.0
@export var max_hp: int = 5
@export var invincible_time: float = 0.6
@export var blink_interval: float = 0.08
@export var attack_damage: int = 1
@export var attack_range: float = 52.0
@export var attack_hit_frame: int = 1
@export var keep_on_screen: bool = true

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var hp: float
var _facing := "down"
var _invincible := 0.0
var _dead := false
var _attacking := false
var _attack_hit := false


func _ready() -> void:
	hp = float(max_hp)
	sprite.animation_finished.connect(_on_animation_finished)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_update_hurt(delta)

	if _attacking:
		velocity = Vector2.ZERO
		move_and_slide()
		_clamp_to_screen()
		_update_attack()
		return

	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_action_just_pressed(&"attack"):
		_update_facing(direction)
		_start_attack()
		return

	velocity = direction * speed
	move_and_slide()
	_clamp_to_screen()
	_update_animation(direction)


func take_damage(amount: float = 1.0) -> void:
	if _dead or _invincible > 0.0:
		return
	hp = maxf(hp - amount, 0.0)
	health_changed.emit(hp, float(max_hp))
	_invincible = invincible_time
	sprite.modulate = HURT_COLOR
	if hp <= 0.0:
		_die()


func _die() -> void:
	_dead = true
	_attacking = false
	velocity = Vector2.ZERO
	sprite.modulate = Color.WHITE
	sprite.play(&"death")


func _start_attack() -> void:
	_attacking = true
	_attack_hit = false
	sprite.flip_h = _facing == "left"
	sprite.play(&"attack_" + ("right" if _facing == "left" else _facing))


func _update_attack() -> void:
	if not _attack_hit and sprite.frame >= attack_hit_frame:
		_attack_hit = true
		_damage_enemies()


func _damage_enemies() -> void:
	for enemy in get_tree().get_nodes_in_group(&"enemy"):
		var to_enemy: Vector2 = enemy.global_position - global_position
		if to_enemy.length() > attack_range:
			continue
		if to_enemy.normalized().dot(_facing_vector()) <= 0.0:
			continue
		enemy.call("take_damage", attack_damage)


func _facing_vector() -> Vector2:
	match _facing:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
		_:
			return Vector2.DOWN


func _on_animation_finished() -> void:
	if _attacking:
		_attacking = false


func _clamp_to_screen() -> void:
	if not keep_on_screen:
		return
	var view := _visible_world_rect()
	if view.size == Vector2.ZERO:
		return
	var bounds := _sprite_bounds()
	global_position.x = clampf(global_position.x, view.position.x - bounds.position.x, view.end.x - bounds.end.x)
	global_position.y = clampf(global_position.y, view.position.y - bounds.position.y, view.end.y - bounds.end.y)


func _visible_world_rect() -> Rect2:
	var canvas := get_viewport().get_canvas_transform()
	var screen := get_viewport_rect()
	var to_world := canvas.affine_inverse()
	return Rect2(to_world * screen.position, Vector2.ZERO).expand(to_world * screen.end)


func _sprite_bounds() -> Rect2:
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if tex == null:
		return Rect2()
	var size := tex.get_size()
	var pos := sprite.offset
	if sprite.centered:
		pos -= size * 0.5
	var r := Rect2(pos, size)
	var a := sprite.transform * r.position
	var b := sprite.transform * Vector2(r.end.x, r.position.y)
	var c := sprite.transform * Vector2(r.position.x, r.end.y)
	var d := sprite.transform * r.end
	var mn := a.min(b).min(c).min(d)
	var mx := a.max(b).max(c).max(d)
	return Rect2(mn, mx - mn)


func _update_hurt(delta: float) -> void:
	if _invincible <= 0.0:
		return
	_invincible = maxf(_invincible - delta, 0.0)
	if _invincible == 0.0:
		sprite.modulate = Color.WHITE
		return
	var alpha := 0.3 if fmod(_invincible, blink_interval * 2.0) < blink_interval else 1.0
	sprite.modulate = Color(HURT_COLOR.r, HURT_COLOR.g, HURT_COLOR.b, alpha)


func _update_facing(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return
	if absf(direction.x) >= absf(direction.y):
		_facing = "right" if direction.x > 0.0 else "left"
	else:
		_facing = "down" if direction.y > 0.0 else "up"


func _update_animation(direction: Vector2) -> void:
	var moving := direction != Vector2.ZERO
	_update_facing(direction)

	var anim_dir := "right" if _facing == "left" else _facing
	sprite.flip_h = _facing == "left"

	var anim_name := ("walk_" if moving else "idle_") + anim_dir
	if sprite.animation != anim_name:
		sprite.play(anim_name)
