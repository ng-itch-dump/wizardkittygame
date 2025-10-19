extends Area2D

@export var speed: float = 900.0
@export var lifetime: float = 1.2
@export var direction: Vector2 = Vector2.RIGHT
@export var weapon_type: int = 0
@export var is_enemy_bullet: bool = false

var time_alive: float = 0.0
var shooter: Node = null

func _ready() -> void:
	monitoring = false
	call_deferred("_enable_monitoring_after_spawn")
	_set_sprite_by_weapon()

func _enable_monitoring_after_spawn() -> void:
	monitoring = true

func _physics_process(delta: float) -> void:
	position += direction.normalized() * speed * delta
	time_alive += delta
	if time_alive >= lifetime:
		queue_free()

func _on_bullet_body_entered(body: Node) -> void:
	if body == shooter:
		return
	
	if is_enemy_bullet:
		if body.is_in_group("Player"):
			if body.has_method("take_damage"):
				body.take_damage(1)
			elif body.has_method("die"):
				body.die()
			else:
				body.queue_free()
			queue_free()
	else:
		if body.is_in_group("Player"):
			return
		if body.is_in_group("Enemy"):
			if body.has_method("on_bullet_hit"):
				body.on_bullet_hit(weapon_type)
			else:
				body.queue_free()
			queue_free()

func _set_sprite_by_weapon() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	match weapon_type:
		0:
			sprite.texture = load("res://images/peeshooter.png")
		1:
			sprite.texture = load("res://images/stunshooter.png")
		2:
			sprite.texture = load("res://images/truePEEshooter.png")
