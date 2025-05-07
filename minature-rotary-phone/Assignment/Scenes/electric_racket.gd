extends Node3D

@onready var audio_stream_player_3d: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _on_area_3d_body_entered(body: Node3D) -> void:
	audio_stream_player_3d.play()
	body.queue_free()
