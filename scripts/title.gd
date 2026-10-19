extends Control

@export_file("*.tscn") var next_scene: String = "res://scences/world.tscn"

@onready var start_button: Button = $Menu/StartButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	start_button.grab_focus()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)
