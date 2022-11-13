extends Node2D


func _ready():
	$AnimationPlayer.play("Unpressed")
	$AnimationPlayer.play("DoorC")
	

func _on_Area2D_body_entered(body):
	if body.is_in_group("Player"):
		$AnimationPlayer.play("Pressed")
		$AnimationPlayer2.play("DoorO")
		print("im in")
		
func _on_Area2D_body_exited(body):
	if body.is_in_group("Player"):
		$AnimationPlayer.play_backwards("Pressed");
		$AnimationPlayer2.play_backwards("DoorO")
		print("im out")
		

	
