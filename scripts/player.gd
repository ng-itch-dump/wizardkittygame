extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -415.0
const SHOOT_COOLDOWN = 0.15
const MAX_BULLETS = 2
const DASH_SPEED = 900.0
const DASH_TIME = 0.15
const DASH_COOLDOWN = 0.6
const MOMENTUM_BOOST = 520.0
const MOMENTUM_BRAKE = 2400.0
const MOMENTUM_MAX = 800.0

@onready var bullet_scene: PackedScene = preload("res://bullet.tscn")
var can_shoot: bool = true
var shoot_cooldown_timer: float = 0.0
var active_bullets: int = 0
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var momentum_x: float = 0.0
var is_dead: bool = false
var health: int = 3
var max_health: int = 3

enum WeaponType { PEASHOOTER, STUN_SHOOTER, PEE_SHOOTER }
var current_weapon: WeaponType = WeaponType.PEASHOOTER

func _ready():
	add_to_group("Player")

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		velocity.x = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	if abs(momentum_x) > 0.0:
		velocity.x += momentum_x
		if direction != 0 and sign(direction) != sign(momentum_x):
			momentum_x = move_toward(momentum_x, 0.0, MOMENTUM_BRAKE * delta)
		elif direction == 0 and is_on_floor() and abs(velocity.x) < 5.0:
			momentum_x = 0.0
		
	if direction > 0:
		$Sprite2D.flip_h = false
	elif direction < 0:
		$Sprite2D.flip_h = true

	if Input.is_action_just_pressed("swap_pee"):
		_cycle_weapon()

	if Input.is_action_pressed("shoot") and can_shoot and active_bullets < MAX_BULLETS:
		_shoot_bullet()
		can_shoot = false
		shoot_cooldown_timer = SHOOT_COOLDOWN

	if Input.is_action_just_pressed("dahs") and not is_dashing and dash_cooldown_timer <= 0.0:
		_start_dash()

	if not can_shoot:
		shoot_cooldown_timer -= delta
		if shoot_cooldown_timer <= 0.0:
			can_shoot = true

	if is_dashing:
		dash_timer -= delta
		var dash_dir := -1.0 if $Sprite2D.flip_h else 1.0
		velocity.x = dash_dir * DASH_SPEED
		if dash_timer <= 0.0:
			is_dashing = false
			dash_cooldown_timer = DASH_COOLDOWN
			momentum_x = clamp( -MOMENTUM_BOOST if $Sprite2D.flip_h else MOMENTUM_BOOST, -MOMENTUM_MAX, MOMENTUM_MAX )

	if dash_cooldown_timer > 0.0:
		dash_cooldown_timer -= delta


	move_and_slide()

func _shoot_bullet() -> void:
	var bullet = bullet_scene.instantiate()
	var dir := Vector2.LEFT if $Sprite2D.flip_h else Vector2.RIGHT
	bullet.position = global_position + Vector2(dir.x * 36.0, 18.0)
	bullet.shooter = self
	bullet.direction = dir
	bullet.weapon_type = current_weapon
	get_tree().current_scene.add_child(bullet)
	active_bullets += 1
	bullet.tree_exited.connect(_on_bullet_exited)

func _cycle_weapon() -> void:
	var next_index := int(current_weapon) + 1
	if next_index > WeaponType.STUN_SHOOTER:
		next_index = WeaponType.PEASHOOTER
	current_weapon = next_index

func _on_bullet_exited() -> void:
	active_bullets = max(0, active_bullets - 1)

func _start_dash() -> void:
	is_dashing = true
	dash_timer = DASH_TIME

func die() -> void:
	print("PLAYER DIE() CALLED!")
	if is_dead:
		return
	is_dead = true
	get_tree().reload_current_scene()

func take_damage(amount: int = 1) -> void:
	if is_dead:
		return
	health -= amount
	print("Player took damage! Health: ", health)
	if health <= 0:
		die()
