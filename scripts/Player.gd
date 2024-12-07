extends Area2D

@export var health = 10
@export var health_max = 10
@export var defense = 1
@export var torch = 0
@export var torch_min = 10
@export var keys = 0

var slimes_killed = 0
var tentacles_killed = 0
var priest_killed = 0
var torches_collected = 0
var chests_collected = 0
var keys_collected = 0
var locks_unlocked = 0
var secrets_found = 0
var walls_bumped_into = 0
var score = 0

var tile_size = 16
var inputs = {"right" : Vector2.RIGHT, "left" : Vector2.LEFT, "up" : Vector2.UP, "down" : Vector2.DOWN}

var move_speed = 3
var is_moving = false
var is_game_over = false

var is_lit = false

var rng = RandomNumberGenerator.new()

@onready var ray = $RayCast2D
@onready var torch_sprite = $CanvasModulate/Sprite2D
@onready var stats_label = $Control/StatsLabel
@onready var alert_label = $Control/AlertLabel

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _unhandled_input(event):
	if is_moving:
		return
	elif is_game_over:
		pass
	for dir in inputs.keys():
		if event.is_action_pressed(dir):
			move(dir)

func move(dir):
	clear_label()
	ray.target_position = inputs[dir] * tile_size
	ray.force_raycast_update()
	if !ray.is_colliding():
		var tween = create_tween()
		tween.tween_property(self, "position", position + inputs[dir] * tile_size, 1.0/move_speed).set_trans(Tween.TRANS_SINE)
		is_moving = true
		await tween.finished
		is_moving = false
		update_light()
		update_stats_label()
	else:
		var object = ray.get_collider()
		match object.get_meta("Item"):
			"Torch":
				pickup_torch()
				object.queue_free()
				update_alert_label("[center]You found a torch[/center]")
				torches_collected += 1
				return
			"Wall":
				update_alert_label("[center]There's a wall there[/center]")
				walls_bumped_into += 1
				return
			"Slime":
				battle(5)
				object.queue_free()
				update_stats_label() 
				slimes_killed += 1
				return
			"Tentacle":
				battle(10)
				object.queue_free()
				update_stats_label()
				tentacles_killed += 1
				return
			"Priest":
				battle(20)
				object.queue_free()
				update_stats_label()
				priest_killed = 1
				return
			"Chest":
				chests_collected += 1
				object.queue_free()
				match rng.randi_range(0,2):
					0:
						update_alert_label("[center]You found an HP buff[/center]")
						health_max += 1
						health = health_max
					1:
						update_alert_label("[center]You found a DF buff[/center]")
						defense += 1
					2:
						update_alert_label("[center]You found a light buff[/center]")
						torch_min += 1
						pickup_torch()
				update_stats_label()
				return
			"Key":
				update_alert_label("[center]You found a key![/center]")
				keys_collected += 1
				keys += 1
				object.queue_free()
				update_stats_label()
				return
			"Lock":
				if keys >= 1:
					locks_unlocked += 1
					object.queue_free()
					keys -= 1
					update_stats_label()
					update_alert_label("[center]You unlocked the way[/center]")
				else:
					update_alert_label("[center]You need a key[/center]")
				return
			"Secret":
				position = Vector2(-152,-280)
				return
			"Gerald":
				return

func update_light():
	if torch > 0:
		torch -= 1
		light()
	if torch <= 0:
		is_lit = false
		light()

func pickup_torch():
	is_lit = true
	torch += torch_min
	light()
	update_stats_label()

func light():
	if (is_lit):
		torch_sprite.min_diameter = 3
		torch_sprite.max_diameter = 3.1
	else:
		torch_sprite.min_diameter = 1
		torch_sprite.max_diameter = 1.1

func clear_label():
	alert_label.text = ""

func update_alert_label(text):
	alert_label.text = text

func update_stats_label():
	stats_label.text = "HP: %s DF: %s Light: %s Keys: %s" % [health, defense, torch, keys]

func battle(enemy_level):
	var damage
	if defense >= enemy_level:
		damage = 0
	else:
		damage = randi_range(0, enemy_level - defense)
	update_alert_label("[center]You took %s damage[/center]" % damage)
	health -= damage
	if health <= 0:
		game_over("death")

func game_over(condition):
	match condition:
		"death":
			pass
		"victory":
			pass
		"secret":
			pass
	get_tree().reload_current_scene()
