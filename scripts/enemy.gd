extends CharacterBody2D

const ARRIVE_EPSILON := 2.0

@export var detect_radius: float = 150.0
@export var attack_radius: float = 48.0
@export var attack_release_radius: float = 64.0
@export var attack_cooldown: float = 1.0
@export var move_speed: float = 76.5
@export var attack_damage: float = 0.5
@export var hit_frame: int = 3
@export var max_hp: int = 3
@export var hurt_time: float = 0.5

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _spawn_position: Vector2
var _in_attack := false
var _attacking := false
var _cooldown := 0.0
var _has_hit := false
var hp: int
var _dead := false
var _hurt_timer := 0.0


func _ready() -> void:
	_spawn_position = global_position
	hp = max_hp
	sprite.animation_finished.connect(_on_animation_finished)
	queue_redraw()


func _physics_process(delta: float) -> void:
	if _dead:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _hurt_timer > 0.0:
		_hurt_timer = maxf(_hurt_timer - delta, 0.0)
		velocity = Vector2.ZERO
		move_and_slide()
		if _hurt_timer == 0.0:
			sprite.modulate = Color.WHITE
		return
	var target := _get_player()
	var distance := INF if target == null else global_position.distance_to(target.global_position)

	if target == null:
		_in_attack = false
	elif _in_attack:
		_in_attack = distance <= attack_release_radius
	elif distance <= attack_radius:
		_in_attack = true

	if _in_attack:
		_attack(target)
		return

	_attacking = false
	var chasing := target != null and distance <= detect_radius
	var desired := _desired_velocity(chasing, target)
	velocity = desired
	var moving := not desired.is_zero_approx()
	move_and_slide()
	_update_facing(desired.x)
	_set_animation(&"move" if moving else &"idle")


func take_damage(amount: int = 1) -> void:
	if _dead:
		return
	hp = maxi(hp - amount, 0)
	if hp == 0:
		_die()
		return
	_attacking = false
	_hurt_timer = hurt_time
	sprite.modulate = Color(1.0, 0.5, 0.5)
	sprite.play(&"hurt")


func _die() -> void:
	_dead = true
	_attacking = false
	_in_attack = false
	velocity = Vector2.ZERO
	move_and_slide()
	sprite.modulate = Color.WHITE
	sprite.play(&"die")
	$CollisionShape2D.set_deferred("disabled", true)
	queue_redraw()


func _attack(target: Node2D) -> void:
	if not _attacking and _cooldown <= 0.0:
		_attacking = true
		_has_hit = false
		sprite.play(&"attack")
	velocity = Vector2.ZERO
	move_and_slide()
	_update_facing((target.global_position - global_position).x)
	if _attacking and not _has_hit and sprite.frame >= hit_frame:
		_has_hit = true
		if global_position.distance_to(target.global_position) <= attack_radius and target.has_method("take_damage"):
			target.call("take_damage", attack_damage)


func _on_animation_finished() -> void:
	if sprite.animation == &"attack":
		_attacking = false
		_cooldown = attack_cooldown
		sprite.play(&"idle")


func _desired_velocity(chasing: bool, target: Node2D) -> Vector2:
	if chasing:
		return global_position.direction_to(target.global_position) * move_speed
	if global_position.distance_to(_spawn_position) > ARRIVE_EPSILON:
		return global_position.direction_to(_spawn_position) * move_speed
	return Vector2.ZERO


func _update_facing(dx: float) -> void:
	if is_zero_approx(dx):
		return
	sprite.flip_h = dx < 0.0


func _draw() -> void:
	if not OS.is_debug_build():
		return
	if _dead:
		return
	draw_arc(Vector2.ZERO, detect_radius, 0.0, TAU, 64, Color(1.0, 0.4, 0.4, 0.6), 2.0)
	draw_arc(Vector2.ZERO, attack_radius, 0.0, TAU, 64, Color(1.0, 0.75, 0.2, 0.7), 2.0)


func _get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


func _set_animation(anim_name: StringName) -> void:
	if sprite.animation != anim_name:
		sprite.play(anim_name)
