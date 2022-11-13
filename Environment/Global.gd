extends Node2D

var key_founded = []

signal LeverChanged

func LeverChanged():
	emit_signal("LeverChanged")
