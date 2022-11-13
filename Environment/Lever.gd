extends Node2D

export var state = "0"

func _ready():
	if state == "0":
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true


func _on_Area2D_body_entered(_body):
	if state == "0":
		state = "1"
	else:
			state = "0"
			Global.LeverChanged()
	if state == "0":
		$Sprite.flip_h = false
	else:
		$Sprite.flip_h = true
	
	
			

	
