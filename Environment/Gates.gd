extends Node2D

export var code = "0"
var CodeFromLevers = ""
var Levers = []


func _ready():
	Levers = get_node("Levers").get_children()
	Global.connect("LeverChanged", self, "CheckCode")
	for lever in Levers:
		print(lever.name, '', lever.state)
	
func CheckCode():
	var CodeFromLevers = ""
	for lever in Levers:
		CodeFromLevers += lever.state
		
	if code == CodeFromLevers:
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", true)
		$Fence.visible = false
	else:
		$StaticBody2D/CollisionShape2D.set_deferred("disabled", false)
		$Fence.visible = true
	
