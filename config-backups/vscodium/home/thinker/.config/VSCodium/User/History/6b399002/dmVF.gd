extends Control

var count := 0
onready var count_label := $Label
onready var push_button := $Button

func _ready():
    push_button.text = "PUSH HERE!"
    push_button.connect("pressed", self, "_on_push_button_pressed")
    update_label()

func _on_push_button_pressed():
    count += 1
    update_label()

func update_label():
    # Format count as 3 digits
    count_label.text = "TOUCH COUNT : %03d" % count
