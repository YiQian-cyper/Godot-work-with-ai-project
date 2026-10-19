extends Control

@export_file("*.tscn") var next_scene: String = "res://scences/world.tscn"

@onready var restart_button: Button = $Menu/RestartButton


func _ready() -> void:
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.grab_focus()


func _on_restart_pressed() -> void:
	get_tree().change_scene_to_file(next_scene)
