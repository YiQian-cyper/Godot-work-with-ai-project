extends Control

const GameState := preload("res://scripts/game_state.gd")

const DIFFICULTY_NAMES := ["Easy", "Medium", "Hard"]

@export_file("*.tscn") var next_scene: String = "res://scences/world.tscn"

@onready var start_button: Button = $Menu/StartButton
@onready var difficulty_button: Button = $Menu/DifficultyButton
@onready var difficulty_menu: PopupMenu = $Menu/DifficultyButton/DifficultyMenu


func _ready() -> void:
	for value in DIFFICULTY_NAMES.size():
		difficulty_menu.add_radio_check_item(DIFFICULTY_NAMES[value], value)
	start_button.pressed.connect(_on_start_pressed)
	difficulty_button.pressed.connect(_on_difficulty_pressed)
	difficulty_menu.id_pressed.connect(_on_difficulty_selected)
	_update_difficulty_ui()
	start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)


func _on_difficulty_pressed() -> void:
	var below: Vector2 = difficulty_button.get_global_transform_with_canvas() * Vector2(0.0, difficulty_button.size.y)
	difficulty_menu.position = Vector2i(below)
	difficulty_menu.popup()


func _on_difficulty_selected(id: int) -> void:
	GameState.difficulty = id
	_update_difficulty_ui()


func _update_difficulty_ui() -> void:
	difficulty_button.text = "Difficulty: " + DIFFICULTY_NAMES[GameState.difficulty]
	for value in DIFFICULTY_NAMES.size():
		difficulty_menu.set_item_checked(value, value == GameState.difficulty)
