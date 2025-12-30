extends Control

var count := 0
@onready var count_label := $Label
@onready var push_button := $Button

func _ready():
	# Use Callable syntax in Godot 4
	push_button.pressed.connect(Callable(self, "_on_push_button_pressed"))
	update_label()

func _on_push_button_pressed():
	count += 1
	update_label()

func update_label():
	count_label.text = "TOUCH COUNT : %03d" % count
