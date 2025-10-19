extends CharacterBody2D

const SPEED = 100.0

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

@onready var sprite_2d = $Sprite2D
@onready var enemy_collision_shape: CollisionShape2D = $CollisionShape2D
var health: int = 2
var stunned_until: float = 0.0

func _ready():
	add_to_group("Enemy")

func _physics_process(delta):
	var now := Time.get_unix_time_from_system()
	var is_stunned := now < stunned_until
	velocity.y += gravity * delta
	velocity.x = 0 if is_stunned else -SPEED
	
	move_and_slide()

func _on_hitbox_body_entered(body):
	if body.is_in_group("Player"):
		var player_shape: CollisionShape2D = body.get_node_or_null("CollisionShape2D")
		if player_shape == null or enemy_collision_shape == null:
			return
		var player_extents_y := 0.0
		var enemy_extents_y := 0.0
		if player_shape.shape is RectangleShape2D:
			player_extents_y = (player_shape.shape as RectangleShape2D).extents.y * abs(body.global_scale.y)
		if enemy_collision_shape.shape is RectangleShape2D:
			enemy_extents_y = (enemy_collision_shape.shape as RectangleShape2D).extents.y * abs(global_scale.y)
		var player_shape_offset_y: float = player_shape.position.y * abs(body.global_scale.y)
		var enemy_shape_offset_y: float = enemy_collision_shape.position.y * abs(global_scale.y)
		var player_bottom_y: float = body.global_position.y + player_shape_offset_y + player_extents_y
		var enemy_top_y: float = global_position.y + enemy_shape_offset_y - enemy_extents_y
		var margin: float = 8.0
		var downward_threshold: float = 20.0
		var stomp: bool = (player_bottom_y <= enemy_top_y + margin) and (body.velocity.y >= downward_threshold)
		if stomp:
			queue_free()
			body.velocity.y = body.JUMP_VELOCITY * 0.6
		else:
			if body.has_method("die"):
				body.die()
			else:
				body.queue_free()

func on_bullet_hit(weapon_type: int) -> void:
	match weapon_type:
		0:
			health -= 1
			if health <= 0:
				queue_free()
		1:
			var dur := randf_range(1.5, 2.5)
			stunned_until = Time.get_unix_time_from_system() + dur
		2:
			queue_free()
