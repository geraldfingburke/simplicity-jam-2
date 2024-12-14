extends Area2D

@export var health = 10
@export var health_max = 10
@export var defense = 1
@export var torch = 0
@export var torch_min = 20
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
var steps = 0

var tile_size = 16
var inputs = {"right" : Vector2.RIGHT, "left" : Vector2.LEFT, "up" : Vector2.UP, "down" : Vector2.DOWN}

var move_speed = 3
var is_moving = false
var is_game_over = false
var stats_string = ""

var is_lit = false

var rng = RandomNumberGenerator.new()

@onready var ray = $RayCast2D
@onready var torch_sprite = $CanvasModulate/Sprite2D
@onready var stats_label = $Control/StatsLabel
@onready var alert_label = $Control/AlertLabel
@onready var sfx = $SFX
@onready var game_over_screen = $GameOverScreen
@onready var game_over_text = $GameOverScreen/Control/GameOverText
var hit_fx = load("res://Sound/FX/hit.wav")
var open_chest_fx = load("res://Sound/FX/openChest.wav")
var pickup_key_fx = load("res://Sound/FX/pickupKey.wav")
var pickup_torch_fx = load("res://Sound/FX/pickupTorch.wav")
var unlock_fx = load("res://Sound/FX/unlock.wav")
var secret_fx = load("res://Sound/FX/secret.wav")
var gerald_fx = load("res://Sound/FX/Wilhelm_Scream.ogg")
var wall_fx = load("res://Sound/FX/wall.wav")
var step_fx = load("res://Sound/FX/step.wav")

# Called when the node enters the scene tree for the first time.
func _ready():
	update_alert_label("Use directional keys to move")

func _unhandled_input(event):
	if is_moving:
		return
	elif is_game_over:
		if event.is_action_released("space"):
			get_tree().reload_current_scene()
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
		steps += 1
		play_sfx(step_fx)
		await tween.finished
		is_moving = false
		update_light()
		update_stats_label()
		if torches_collected > 0 and steps == 1:
			update_alert_label("[center]Kill the priest[/center]")
		elif torches_collected > 0 and steps == 2:
			update_alert_label("[center]Do not die[/center]")
	else:
		var object = ray.get_collider()
		match object.get_meta("Item"):
			"Torch":
				pickup_torch()
				play_sfx(pickup_torch_fx)
				object.queue_free()
				if torches_collected == 0:
					update_alert_label("[center]Torches light your way[/center]")
				else:
					update_alert_label("[center]You found a torch[/center]")
				torches_collected += 1
				return
			"Wall":
				update_alert_label("[center]There's a wall there[/center]")
				walls_bumped_into += 1
				play_sfx(wall_fx)
				return
			"Slime":
				play_sfx(hit_fx)
				battle(5)
				object.queue_free()
				update_stats_label()
				slimes_killed += 1
				return
			"Tentacle":
				play_sfx(hit_fx)
				battle(10)
				object.queue_free()
				update_stats_label()
				tentacles_killed += 1
				return
			"Priest":
				play_sfx(hit_fx)
				battle(20)
				object.queue_free()
				update_stats_label()
				priest_killed = 1
				game_over("victory")
				return
			"Chest":
				play_sfx(open_chest_fx)
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
				play_sfx(pickup_key_fx)
				update_alert_label("[center]You found a key![/center]")
				keys_collected += 1
				keys += 1
				object.queue_free()
				update_stats_label()
				return
			"Lock":
				play_sfx(unlock_fx)
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
				play_sfx(secret_fx)
				position = Vector2(-152,-280)
				return
			"Gerald":
				play_sfx(gerald_fx)
				secrets_found += 1
				object.queue_free()
				game_over("secret")
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
	is_game_over = true
	game_over_screen.visible = true
	game_over_text.text = build_stats_string(condition)

func play_sfx(sound):
	sfx.stream = sound
	sfx.play()

func build_stats_string(condition):
	var slime_slayer = 0
	var tentacle_tickler = 0
	var priest_ender = 0
	var treasure_charlie = 0
	var torch_hoarder = 0
	var key_master = 0
	var gate_keeper = 0
	
	match condition:
		"death":
			stats_string += "You were killed in the depths\n\n"
		"victory":
			stats_string += "You defeated the Priest and escaped with your life\n\n"
		"secret":
			stats_string += "You found the developer, thank you for playing!\n\n"
	
	stats_string += "Stats\n\n"
	stats_string += "Slimes Killed: %s\n\n" % slimes_killed
	stats_string += "Tentacles Killed: %s\n\n" % tentacles_killed
	stats_string += "Priest Killed: Yes\n\n" if priest_killed == 1 else "Priest Killed: No\n\n"
	stats_string += "Chests Opened: %s\n\n" % chests_collected
	stats_string += "Torches Collected: %s\n\n" % torches_collected
	stats_string += "Keys Collected: %s\n\n" % keys_collected
	stats_string += "Locks Opened: %s\n\n" % locks_unlocked
	stats_string += "Secret Found: Yes\n\n" if secrets_found == 1 else "Secret Found: No\n\n"
	stats_string += "Walls Bumped Into: %s\n\n" % walls_bumped_into
	stats_string += "\n\nBonuses\n\n"
	if slimes_killed == 19:
		stats_string += "Slime Slayer "
		slime_slayer = 50
	if tentacles_killed == 4:
		stats_string += "Tentacle Tickler "
		tentacle_tickler = 50
	if priest_killed == 1:
		stats_string += "Priest Ender "
		priest_ender = 50
	if chests_collected == 16:
		stats_string += "Treasure Charlie "
		treasure_charlie = 50
	if torches_collected == 10:
		stats_string += "Torch Hoarder "
		torch_hoarder = 50
	if keys_collected == 4:
		stats_string += "Key Master "
		key_master = 50
	if locks_unlocked == 4:
		stats_string += "Gate Keeper"
		gate_keeper = 50
	var score = (slimes_killed * 10) + (tentacles_killed * 50) + (priest_killed * 100) + (chests_collected * 5) + torches_collected + (keys_collected * 25) + (locks_unlocked * 25) + (secrets_found * 200) + slime_slayer + tentacle_tickler + priest_ender + treasure_charlie + torch_hoarder + key_master + gate_keeper
	stats_string += "\n\nFinal Score: %s" % score
	stats_string += "\n\nTake a screenshot and share in the comments!"
	stats_string += "\n\nThank you for playing! Press 'Space' to play again!"
	return stats_string
