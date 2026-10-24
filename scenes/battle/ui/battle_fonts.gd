class_name BattleFonts
extends RefCounted

static func display() -> Font:
	return load("res://assets/fonts/ChakraPetch-Bold.ttf")

static func mono() -> Font:
	var f := FontVariation.new()
	f.base_font = load("res://assets/fonts/JetBrainsMono.ttf")
	f.variation_opentype = {"wght": 700}
	return f
