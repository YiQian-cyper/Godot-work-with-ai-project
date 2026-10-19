extends AnimatedSprite2D

enum Actor { PLAYER, SLIME }

const PLAYER_SHEET := preload("res://sprites/characters/player.png")
const SLIME_SHEET := preload("res://sprites/characters/slime.png")

const PLAYER_CELL := 48
const PLAYER_COLS := 6
const PLAYER_STARTS := {
	"idle_down": 0,
	"idle_right": 6,
	"idle_up": 12,
	"walk_down": 18,
	"walk_right": 24,
	"walk_up": 30,
	"attack_down": 36,
	"attack_right": 42,
	"attack_up": 48,
}
const PLAYER_COUNTS := {
	"idle_down": 6,
	"idle_right": 6,
	"idle_up": 6,
	"walk_down": 6,
	"walk_right": 6,
	"walk_up": 6,
	"attack_down": 4,
	"attack_right": 4,
	"attack_up": 4,
}

const SLIME_CELL := 32
const SLIME_COLS := 7

@export var actor: Actor = Actor.PLAYER
@export var move_speed: float = 64.0
@export var idle_time_min: float = 0.3
@export var idle_time_max: float = 1.5
@export var edge_margin: float = 72.0
@export var wander_area: Rect2 = Rect2()
@export var partner_path: NodePath
@export var attack_distance: float = 100.0
@export var attack_cooldown: float = 1.5

var _target := Vector2.ZERO
var _idle := 0.0
var _facing := "down"
var _partner: Node2D = null
var _attacking := false
var _cooldown := 0.0


func _ready() -> void:
	sprite_frames = _build_frames()
	animation_finished.connect(_on_animation_finished)
	_set_animation(_idle_anim())
	if not partner_path.is_empty():
		_partner = get_node_or_null(partner_path) as Node2D
	_pick_target()


func _process(delta: float) -> void:
	if _attacking:
		return
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _can_attack():
		_start_attack()
		return
	if _idle > 0.0:
		_idle = maxf(_idle - delta, 0.0)
		_set_animation(_idle_anim())
		return
	var to_target := _target - position
	if to_target.length() <= 2.0:
		_idle = randf_range(idle_time_min, idle_time_max)
		_pick_target()
		_set_animation(_idle_anim())
		return
	var direction := to_target.normalized()
	position += direction * move_speed * delta
	_update_facing(direction)
	_set_animation(_walk_anim())


func _can_attack() -> bool:
	if _partner == null or _cooldown > 0.0:
		return false
	return global_position.distance_to(_partner.global_position) <= attack_distance


func _start_attack() -> void:
	_attacking = true
	_idle = 0.0
	_update_facing(_partner.global_position - global_position)
	play(_attack_anim())


func _on_animation_finished() -> void:
	if not _attacking:
		return
	_attacking = false
	_cooldown = attack_cooldown
	_pick_target(true)
	_set_animation(_idle_anim())


func _pick_target(retreat: bool = false) -> void:
	var area := _wander_rect()
	var attempts := 1
	if retreat and _partner != null:
		attempts = 8
	var best := Vector2.ZERO
	var best_distance := -1.0
	for i in attempts:
		var candidate := Vector2(randf_range(area.position.x, area.end.x), randf_range(area.position.y, area.end.y))
		if attempts == 1:
			best = candidate
			break
		var distance := candidate.distance_to(_partner.global_position)
		if distance > best_distance:
			best_distance = distance
			best = candidate
	_target = best


func _wander_rect() -> Rect2:
	if wander_area.size != Vector2.ZERO:
		return wander_area
	var size := get_viewport_rect().size
	var margin := Vector2(edge_margin, edge_margin)
	return Rect2(margin, (size - margin * 2.0).max(Vector2(1.0, 1.0)))


func _update_facing(direction: Vector2) -> void:
	if is_zero_approx(direction.x) and is_zero_approx(direction.y):
		return
	if absf(direction.x) >= absf(direction.y):
		_facing = "right" if direction.x > 0.0 else "left"
	else:
		_facing = "down" if direction.y > 0.0 else "up"
	flip_h = _facing == "left"


func _anim_dir() -> String:
	return "right" if _facing == "left" else _facing


func _idle_anim() -> StringName:
	return &"idle" if actor == Actor.SLIME else StringName("idle_" + _anim_dir())


func _walk_anim() -> StringName:
	return &"move" if actor == Actor.SLIME else StringName("walk_" + _anim_dir())


func _attack_anim() -> StringName:
	return &"attack" if actor == Actor.SLIME else StringName("attack_" + _anim_dir())


func _set_animation(anim_name: StringName) -> void:
	if animation != anim_name:
		play(anim_name)


func _build_frames() -> SpriteFrames:
	return _build_slime_frames() if actor == Actor.SLIME else _build_player_frames()


func _build_player_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for key in PLAYER_STARTS:
		var anim_name := String(key)
		_add_animation(frames, PLAYER_SHEET, PLAYER_CELL, PLAYER_COLS, anim_name, PLAYER_STARTS[key], PLAYER_COUNTS[key], 8.0, not anim_name.begins_with("attack"))
	return frames


func _build_slime_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	_add_animation(frames, SLIME_SHEET, SLIME_CELL, SLIME_COLS, "idle", 0, 4, 9.0, true)
	_add_animation(frames, SLIME_SHEET, SLIME_CELL, SLIME_COLS, "move", SLIME_COLS, 6, 7.0, true)
	_add_animation(frames, SLIME_SHEET, SLIME_CELL, SLIME_COLS, "attack", SLIME_COLS * 2, 7, 6.0, false)
	return frames


func _add_animation(frames: SpriteFrames, sheet: Texture2D, cell: int, cols: int, anim_name: String, anim_start: int, count: int, fps: float, loop: bool) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_speed(anim_name, fps)
	frames.set_animation_loop(anim_name, loop)
	for i in count:
		var index := anim_start + i
		var texture := AtlasTexture.new()
		texture.atlas = sheet
		texture.region = Rect2(float(index % cols) * cell, float(index / cols) * cell, cell, cell)
		frames.add_frame(anim_name, texture)
