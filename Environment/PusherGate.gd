extends Area2D

func _ready():
	connect("body_entered", self, "open_gate")
	connect("body_exited", self, "close_gate")

func open_gate(body):
	if body.name == "Player":
		$StaticBody2D/CollisionShape2D.disabled = true
		$Door/AnimationPlayer.play("Open")
	else:
		$StaticBody2D/CollisionShape2D.disabled = false
		$Door/AnimationPlayer.play("Close")
		
func close_gate(body):
	if body.name == "Player":
		$StaticBody2D/CollisionShape2D.disabled = false
		$Door/AnimationPlayer.play("Close")
	else:
		$StaticBody2D/CollisionShape2D.disabled = true
		$Door/AnimationPlayer.play("Open")
