extends Control

@export_file("*.tscn") var next_scene: String = "res://scences/world.tscn"
@export_file("*.tscn") var title_scene: String = "res://scences/title.tscn"

@onready var restart_button: Button = $Menu/Buttons/RestartButton
@onready var back_button: Button = $Menu/Buttons/BackButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	back_button.pressed.connect(_on_back_pressed)
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(title_scene)
