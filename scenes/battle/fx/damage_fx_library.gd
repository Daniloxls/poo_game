class_name DamageFxLibrary
extends Resource
## Efeito (SpriteFrames) e som por tipo de dano. Vazio = efeito provisório.

@export var effects: Dictionary = {}  # DamageType.Kind -> SpriteFrames
@export var sounds: Dictionary = {}  # DamageType.Kind -> AudioStream


func effect_for(kind) -> SpriteFrames:
	return effects.get(kind) as SpriteFrames


func sound_for(kind) -> AudioStream:
	return sounds.get(kind) as AudioStream
