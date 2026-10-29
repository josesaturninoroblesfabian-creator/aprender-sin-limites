extends Node2D

signal close_requested

const MAP_PATHS: Array[String] = [
	"res://assets/games/level4/ciudad-abandonada-verde.png",
	"res://assets/games/level4/ciudad-posapocaliptica-oscura.png",
	"res://assets/games/level4/ciudad-posapocaliptica-rio.png",
	"res://assets/games/level4/plaza-fuente-jardines.png",
	"res://assets/games/level4/parque-abandonado.png",
	"res://assets/games/level4/playa-complejo-costero.png",
	"res://assets/games/level4/playa-paradisiaca.png",
	"res://assets/games/level4/hospital-abandonado.png",
	"res://assets/games/level4/supermercado-abandonado.png"
]
const MUSIC_PATHS: Array[String] = [
	"res://assets/audio/level4/choque-16-bits-0.mp3",
	"res://assets/audio/level4/choque-16-bits-1.mp3",
	"res://assets/audio/level4/choque-16-bits-4.mp3",
	"res://assets/audio/level4/choque-16-bits-5.mp3"
]
const SHELTER_TEXTURE_PATH := "res://assets/games/level4/refugio-rustico.png"
const CONDOR_SPRITES_PATH := "res://assets/games/level4/condor-guerrero-sprites.png"
const CONDOR_AIM_POSES_PATH := "res://assets/games/level4/condor-guerrero-poses.png"
const ALLY_WALK_SPRITES_PATH := "res://assets/games/level4/condor-aliado-caminata-limpio.png"
const ALLY_AIM_POSES_PATH := "res://assets/games/level4/condor-aliado-poses.png"
const SHOTGUN_TEXTURE_PATH := "res://assets/games/level4/escopeta-condor.png"
const BULLET_BASE_PATH := "res://assets/games/level4/proyectil-condor-base.png"
const BULLET_UPGRADED_PATH := "res://assets/games/level4/proyectil-condor-mejorado.png"
const ALLY_BULLET_PATH := "res://assets/games/level4/proyectil-condor-aliado.png"
const SHOTGUN_SOUND_PATH := "res://assets/audio/level4/disparo-escopeta-condor.mp3"
const BOMB_ATLAS_PATH := "res://assets/games/level4/atlas-explosion-bombardeo.png"
const BOMB_SOUND_PATH := "res://assets/audio/level4/explosion-bombardeo.mp3"
const PLAYER_HURT_SOUND_PATH := "res://assets/audio/level4/dolor-condor-herido.mp3"
const ZOMBIE_CAT_PATH := "res://assets/games/level4/zombi-gato.png"
const ZOMBIE_CUY_PATH := "res://assets/games/level4/zombi-cuy.png"
const ZOMBIE_DOG_PATH := "res://assets/games/level4/zombi-perro-limpio.png"
const ZOMBIE_GROAN_PATHS: Array[String] = [
	"res://assets/audio/level4/gruñido-zombi.mp3",
	"res://assets/audio/level4/gruñido-zombi-ambiente.mp3"
]
const PLAYER_SPEED := 255.0
const FIRE_DELAY := 0.24
const WORLD_SIZE := Vector2(2400.0, 1600.0)
const SPANISH_LETTERS := "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ"
const BOSS_LETTERS := {"E": "Zorro gigante zombi", "J": "Cocodrilo gigante", "Ñ": "Llama gigante", "S": "Gorila gigante", "X": "Conejo artillero", "Z": "Jefes finales"}
const BOMB_EXPLOSION_FRAME_RECTS: Array[Rect2] = [
	Rect2(0, 318, 235, 191), Rect2(235, 318, 205, 191), Rect2(440, 318, 215, 191),
	Rect2(655, 318, 235, 191), Rect2(890, 318, 270, 191), Rect2(1160, 318, 512, 191),
	Rect2(0, 522, 400, 194), Rect2(400, 522, 375, 194), Rect2(775, 522, 340, 194),
	Rect2(1115, 522, 275, 194), Rect2(1390, 522, 282, 194),
	Rect2(0, 726, 255, 186), Rect2(255, 726, 255, 186), Rect2(510, 726, 235, 186),
	Rect2(745, 726, 255, 186), Rect2(1000, 726, 250, 186), Rect2(1250, 726, 200, 186),
	Rect2(1450, 726, 222, 186)
]

var map_textures: Array[Texture2D] = []
var camera: Camera2D
var current_map_index := -1
var current_map: Texture2D
var shelter_texture: Texture2D
var condor_sprites: Texture2D
var condor_aim_poses: Texture2D
var ally_walk_sprites: Texture2D
var ally_aim_poses: Texture2D
var shotgun_texture: Texture2D
var bullet_base_texture: Texture2D
var bullet_upgraded_texture: Texture2D
var ally_bullet_texture: Texture2D
var bomb_atlas: Texture2D
var zombie_cat_texture: Texture2D
var zombie_cuy_texture: Texture2D
var zombie_dog_texture: Texture2D
var music_player: AudioStreamPlayer
var shotgun_player: AudioStreamPlayer
var ally_shotgun_players: Array[AudioStreamPlayer] = []
var next_ally_sound_player := 0
var player_hurt_player: AudioStreamPlayer
var bomb_sound_players: Array[AudioStreamPlayer] = []
var next_bomb_sound_player := 0
var zombie_groan_player: AudioStreamPlayer2D
var zombie_groan_clock := 1.5
var last_zombie_groan_index := -1
var last_music_index := -1
var music_volume := 0.75
var effects_volume := 0.85
var settings_open := false
var player_position := Vector2(640.0, 430.0)
var aim_direction := Vector2.RIGHT
var player_health := 100.0
var score := 0
var zombies_defeated := 0
var letter_index := 0
var collected_letters := 0
var spawn_clock := 0.0
var fire_clock := 0.0
var hurt_clock := 0.0
var animation_clock := 0.0
var player_moving := false
var muzzle_flash := 0.0
var shoot_pose_clock := 0.0
var game_paused := false
var game_finished := false
var shelter_active := false
var upgrade_pending := false
var boss_active := false
var bomb_count := 1
var shotgun_upgrades := 0
var companion_count := 0
var next_companion_id := 1
var virtual_movement := Vector2.ZERO
var touch_fire_pressed := false
var enemies: Array[Dictionary] = []
var bullets: Array[Dictionary] = []
var hearts: Array[Dictionary] = []
var letter_pickups: Array[Dictionary] = []
var bosses: Array[Dictionary] = []
var hazards: Array[Dictionary] = []
var companions: Array[Dictionary] = []
var bomb_drops: Array[Dictionary] = []
var bomb_explosions: Array[Dictionary] = []
var bombardment_damage_applied := false
var shelter_position := Vector2.ZERO

var health_bar: ProgressBar
var health_text: Label
var wave_text: Label
var score_text: Label
var map_text: Label
var overlay: PanelContainer
var overlay_title: Label
var overlay_message: Label
var resume_button: Button
var stage_text: Label
var pickup_text: Label
var upgrade_panel: PanelContainer
var upgrade_title: Label
var upgrade_buttons: Array[Button] = []
var boss_status: PanelContainer
var boss_status_label: Label
var boss_health_bar: ProgressBar
var bomb_touch_button: Button
var radar_panel: Panel
var radar_field: Control
var radar_player_dot: ColorRect
var radar_letter_dots: Array[ColorRect] = []
var radar_enemy_dots: Array[ColorRect] = []
var radar_shelter_dot: ColorRect
var settings_overlay: Control
var music_volume_value: Label
var effects_volume_value: Label

func _ready() -> void:
	randomize()
	_load_audio_settings()
	shelter_texture = load(SHELTER_TEXTURE_PATH) as Texture2D
	condor_sprites = load(CONDOR_SPRITES_PATH) as Texture2D
	condor_aim_poses = load(CONDOR_AIM_POSES_PATH) as Texture2D
	ally_walk_sprites = load(ALLY_WALK_SPRITES_PATH) as Texture2D
	ally_aim_poses = load(ALLY_AIM_POSES_PATH) as Texture2D
	shotgun_texture = load(SHOTGUN_TEXTURE_PATH) as Texture2D
	bullet_base_texture = load(BULLET_BASE_PATH) as Texture2D
	bullet_upgraded_texture = load(BULLET_UPGRADED_PATH) as Texture2D
	ally_bullet_texture = load(ALLY_BULLET_PATH) as Texture2D
	bomb_atlas = load(BOMB_ATLAS_PATH) as Texture2D
	zombie_cat_texture = load(ZOMBIE_CAT_PATH) as Texture2D
	zombie_cuy_texture = load(ZOMBIE_CUY_PATH) as Texture2D
	zombie_dog_texture = load(ZOMBIE_DOG_PATH) as Texture2D
	shotgun_player = AudioStreamPlayer.new()
	shotgun_player.stream = load(SHOTGUN_SOUND_PATH) as AudioStream
	shotgun_player.volume_db = 3.0
	add_child(shotgun_player)
	for pool_index in range(4):
		var ally_shotgun_player := AudioStreamPlayer.new()
		ally_shotgun_player.stream = load(SHOTGUN_SOUND_PATH) as AudioStream
		ally_shotgun_player.volume_db = 3.0
		add_child(ally_shotgun_player)
		ally_shotgun_players.append(ally_shotgun_player)
	player_hurt_player = AudioStreamPlayer.new()
	player_hurt_player.stream = load(PLAYER_HURT_SOUND_PATH) as AudioStream
	player_hurt_player.volume_db = 9.0
	add_child(player_hurt_player)
	for sound_index in range(3):
		var bomb_sound_player := AudioStreamPlayer.new()
		bomb_sound_player.stream = load(BOMB_SOUND_PATH) as AudioStream
		bomb_sound_player.volume_db = 3.0
		add_child(bomb_sound_player)
		bomb_sound_players.append(bomb_sound_player)
	zombie_groan_player = AudioStreamPlayer2D.new()
	zombie_groan_player.stream = load(ZOMBIE_GROAN_PATHS[0]) as AudioStream
	zombie_groan_player.volume_db = 3.0
	zombie_groan_player.max_distance = 1000.0
	add_child(zombie_groan_player)
	for map_path in MAP_PATHS:
		var texture := load(map_path) as Texture2D
		if texture != null:
			map_textures.append(texture)
	_build_interface()
	_setup_camera()
	_reset_game()
	music_player = AudioStreamPlayer.new()
	music_player.volume_db = -2.0
	music_player.finished.connect(_play_random_music)
	add_child(music_player)
	_apply_audio_settings()
	_play_random_music()

func _process(delta: float) -> void:
	if game_paused or game_finished or settings_open:
		return
	animation_clock += delta
	muzzle_flash = maxf(0.0, muzzle_flash - delta)
	shoot_pose_clock = maxf(0.0, shoot_pose_clock - delta)
	if is_instance_valid(camera):
		camera.position = player_position
	fire_clock = maxf(0.0, fire_clock - delta)
	hurt_clock = maxf(0.0, hurt_clock - delta)
	_update_player(delta)
	_update_spawning(delta)
	_update_enemies(delta)
	_update_zombie_audio(delta)
	_update_bullets(delta)
	_update_hearts()
	_update_letter_pickups()
	_update_bosses(delta)
	_update_hazards(delta)
	_update_bombardment(delta)
	_update_companions(delta)
	_update_hud()
	_update_radar()
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE and settings_open:
			_close_sound_settings()
		elif event.keycode == KEY_ESCAPE or event.keycode == KEY_P:
			_toggle_pause()
		elif event.keycode == KEY_B and not game_paused and not game_finished:
			_use_bomb()
		elif event.keycode == KEY_SPACE and not game_paused and not game_finished:
			_fire_at_nearest_enemy()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if not game_paused and not game_finished and not settings_open:
			_fire_toward(get_global_mouse_position())

func _draw() -> void:
	var screen_size := WORLD_SIZE
	if current_map != null:
		draw_texture_rect(current_map, Rect2(Vector2.ZERO, WORLD_SIZE), false)
	else:
		draw_rect(Rect2(Vector2.ZERO, screen_size), Color("#263a31"))
	draw_rect(Rect2(Vector2.ZERO, screen_size), Color(0.02, 0.05, 0.08, 0.28))
	# Oculta los elementos de HUD incluidos en algunos mapas entregados.
	draw_rect(Rect2(0.0, 0.0, 250.0, 105.0), Color(0.035, 0.08, 0.13, 0.9))
	for heart in hearts:
		var heart_position: Vector2 = heart["position"]
		_draw_heart(heart_position)
	for bullet in bullets:
		_draw_bullet(bullet)
	for enemy in enemies:
		_draw_zombie(enemy)
	for pickup in letter_pickups:
		_draw_letter_pickup(pickup)
	if shelter_active:
		_draw_shelter()
	for boss in bosses:
		_draw_boss(boss)
	for hazard in hazards:
		_draw_hazard(hazard)
	for bomb_drop in bomb_drops:
		_draw_bomb_drop(bomb_drop)
	for explosion in bomb_explosions:
		_draw_bomb_explosion(explosion)
	for companion in companions:
		_draw_companion(companion)
	_draw_condor()

func _update_player(delta: float) -> void:
	var movement := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		movement.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		movement.x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		movement.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		movement.y += 1.0
	movement += virtual_movement
	player_moving = movement.length_squared() > 0.001
	if movement.length_squared() > 1.0:
		movement = movement.normalized()
	player_position += movement * PLAYER_SPEED * delta
	player_position.x = clampf(player_position.x, 34.0, WORLD_SIZE.x - 34.0)
	player_position.y = clampf(player_position.y, 112.0, WORLD_SIZE.y - 40.0)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_fire_toward(get_global_mouse_position())
	elif touch_fire_pressed:
		_fire_at_nearest_enemy()
	_check_shelter_entry()

func _update_spawning(delta: float) -> void:
	# Los animales zombis siguen apareciendo mientras el jugador busca las cinco letras.
	if upgrade_pending or boss_active or game_finished:
		return
	spawn_clock -= delta
	if spawn_clock <= 0.0 and enemies.size() < 42:
		_spawn_zombie()
		spawn_clock = maxf(0.42, 1.15 - float(letter_index) * 0.02)

func _update_enemies(delta: float) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var enemy: Dictionary = enemies[index]
		var position: Vector2 = enemy["position"]
		var target_position := player_position
		var target_companion_id := -1
		var distance_to_target := position.distance_to(player_position)
		for companion in companions:
			var companion_position: Vector2 = companion["position"]
			var companion_distance := position.distance_to(companion_position)
			if companion_distance < distance_to_target:
				distance_to_target = companion_distance
				target_position = companion_position
				target_companion_id = int(companion["id"])
		var to_player := target_position - position
		var distance := to_player.length()
		if distance > 0.001:
			position += to_player / distance * float(enemy["speed"]) * delta
		enemy["position"] = position
		enemy["facing_left"] = to_player.x < 0.0
		enemy["attack_clock"] = maxf(0.0, float(enemy.get("attack_clock", 0.0)) - delta)
		if distance < 33.0 and float(enemy["attack_clock"]) <= 0.0:
			enemy["attack_clock"] = 0.8
			if target_companion_id >= 0:
				_damage_companion(target_companion_id, 12.0)
			elif hurt_clock <= 0.0:
				_damage_player(12.0)
		enemies[index] = enemy

func _update_zombie_audio(delta: float) -> void:
	if not is_instance_valid(zombie_groan_player) or zombie_groan_player.stream == null:
		return
	zombie_groan_clock = maxf(0.0, zombie_groan_clock - delta)
	if enemies.is_empty() or zombie_groan_clock > 0.0:
		return
	var groan_index := randi_range(0, ZOMBIE_GROAN_PATHS.size() - 1)
	if ZOMBIE_GROAN_PATHS.size() > 1:
		while groan_index == last_zombie_groan_index:
			groan_index = randi_range(0, ZOMBIE_GROAN_PATHS.size() - 1)
	var groan_stream := load(ZOMBIE_GROAN_PATHS[groan_index]) as AudioStream
	if groan_stream == null:
		return
	zombie_groan_player.stream = groan_stream
	last_zombie_groan_index = groan_index
	var enemy: Dictionary = enemies[randi_range(0, enemies.size() - 1)]
	zombie_groan_player.global_position = enemy["position"]
	zombie_groan_player.pitch_scale = randf_range(0.92, 1.08)
	if zombie_groan_player.playing:
		zombie_groan_player.stop()
	zombie_groan_player.play()
	zombie_groan_clock = randf_range(2.5, 4.2)

func _update_bullets(delta: float) -> void:
	for bullet_index in range(bullets.size() - 1, -1, -1):
		var bullet: Dictionary = bullets[bullet_index]
		var position: Vector2 = bullet["position"]
		var direction: Vector2 = bullet["direction"]
		position += direction * float(bullet["speed"]) * delta
		bullet["position"] = position
		bullet["life"] = float(bullet["life"]) - delta
		bullet["age"] = float(bullet.get("age", 0.0)) + delta
		var remove_bullet := float(bullet["life"]) <= 0.0 or not Rect2(Vector2.ZERO, WORLD_SIZE).has_point(position)
		if not remove_bullet:
			for enemy_index in range(enemies.size() - 1, -1, -1):
				var enemy: Dictionary = enemies[enemy_index]
				var enemy_position: Vector2 = enemy["position"]
				if position.distance_to(enemy_position) <= 25.0:
					enemy["hp"] = int(enemy["hp"]) - int(bullet.get("damage", 1))
					enemies[enemy_index] = enemy
					remove_bullet = true
					if int(enemy["hp"]) <= 0:
						_defeat_zombie(enemy_position)
						enemies.remove_at(enemy_index)
					break
		if not remove_bullet and boss_active:
			for boss_index in range(bosses.size() - 1, -1, -1):
				var boss: Dictionary = bosses[boss_index]
				var boss_position: Vector2 = boss["position"]
				if position.distance_to(boss_position) <= 52.0:
					boss["hp"] = int(boss["hp"]) - int(bullet.get("damage", 1))
					if int(boss["hp"]) <= 0:
						score += 250
						bosses.remove_at(boss_index)
					else:
						bosses[boss_index] = boss
					remove_bullet = true
					break
		if remove_bullet:
			bullets.remove_at(bullet_index)
		else:
			bullets[bullet_index] = bullet
	if boss_active and bosses.is_empty():
		_finish_boss_fight()

func _update_hearts() -> void:
	for index in range(hearts.size() - 1, -1, -1):
		var heart_position: Vector2 = hearts[index]["position"]
		if heart_position.distance_to(player_position) < 29.0:
			player_health = minf(100.0, player_health + 20.0)
			hearts.remove_at(index)

func _spawn_zombie() -> void:
	var edge := randi_range(0, 3)
	var position := Vector2.ZERO
	var screen_size := WORLD_SIZE
	match edge:
		0: position = Vector2(randf_range(40.0, screen_size.x - 40.0), 116.0)
		1: position = Vector2(randf_range(40.0, screen_size.x - 40.0), screen_size.y - 30.0)
		2: position = Vector2(25.0, randf_range(130.0, screen_size.y - 35.0))
		_: position = Vector2(screen_size.x - 25.0, randf_range(130.0, screen_size.y - 35.0))
	var kind: String = ["gato", "perro", "cuy"][randi_range(0, 2)]
	enemies.append({
		"position": position,
		"speed": randf_range(48.0, 66.0) + float(letter_index) * 1.2,
		"hp": 2 + int(letter_index / 8) if kind != "cuy" else 1 + int(letter_index / 10),
		"kind": kind,
		"phase": randf_range(0.0, TAU),
		"flash": 0.0,
		"attack_clock": randf_range(0.0, 0.5)
	})

func _fire_toward(target: Vector2) -> void:
	if fire_clock > 0.0 or bullets.size() >= 16:
		return
	var direction := target - player_position
	if direction.length_squared() <= 0.001:
		return
	aim_direction = direction.normalized()
	var pellets := mini(1 + shotgun_upgrades * 2, 7)
	for pellet_index in range(pellets):
		var spread := float(pellet_index) - float(pellets - 1) * 0.5
		var pellet_direction := aim_direction.rotated(spread * 0.13)
		bullets.append({
			"position": player_position + pellet_direction * 43.0,
			"direction": pellet_direction,
			"speed": 600.0,
			"life": 1.15,
			"age": 0.0,
			"damage": 1 + shotgun_upgrades / 2,
			"upgraded": shotgun_upgrades > 0
		})
	fire_clock = FIRE_DELAY
	muzzle_flash = 0.12
	shoot_pose_clock = 0.32
	if is_instance_valid(shotgun_player) and shotgun_player.stream != null:
		if shotgun_player.playing:
			shotgun_player.stop()
		shotgun_player.play()

func _fire_at_nearest_enemy() -> void:
	if enemies.is_empty():
		_fire_toward(player_position + aim_direction * 250.0)
		return
	var nearest: Dictionary = enemies[0]
	var nearest_distance := player_position.distance_squared_to(nearest["position"])
	for enemy in enemies:
		var distance := player_position.distance_squared_to(enemy["position"])
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	_fire_toward(nearest["position"])

func _defeat_zombie(position: Vector2) -> void:
	score += 10
	zombies_defeated += 1
	if randf() < 0.14:
		hearts.append({"position": position})

func _use_bomb() -> void:
	if bomb_count <= 0 or not bomb_drops.is_empty():
		return
	bomb_count -= 1
	bombardment_damage_applied = false
	var targets: Array[Vector2] = []
	for enemy in enemies:
		targets.append(enemy["position"])
	for boss in bosses:
		targets.append(boss["position"])
	if targets.is_empty():
		targets.append((player_position + Vector2(randf_range(-150.0, 150.0), randf_range(-100.0, 100.0))).clamp(Vector2(40.0, 120.0), WORLD_SIZE - Vector2(40.0, 40.0)))
	else:
		targets.shuffle()
		if targets.size() > 12:
			var selected_targets: Array[Vector2] = []
			for target_index in range(12):
				selected_targets.append(targets[int(float(target_index) * float(targets.size()) / 12.0)])
			targets = selected_targets
	for index in range(targets.size()):
		var target: Vector2 = targets[index]
		bomb_drops.append({
			"position": Vector2(target.x + randf_range(-32.0, 32.0), target.y - 620.0),
			"target": target,
			"delay": float(index) * 0.13,
			"speed": randf_range(850.0, 1050.0)
		})
	_update_hud()

func _update_bombardment(delta: float) -> void:
	for index in range(bomb_drops.size() - 1, -1, -1):
		var bomb: Dictionary = bomb_drops[index]
		bomb["delay"] = float(bomb["delay"]) - delta
		if float(bomb["delay"]) > 0.0:
			bomb_drops[index] = bomb
			continue
		var position: Vector2 = bomb["position"]
		var target: Vector2 = bomb["target"]
		var offset := target - position
		var travel := float(bomb["speed"]) * delta
		if offset.length() <= travel:
			bomb_explosions.append({"position": target, "age": 0.0})
			_play_bomb_impact()
			bomb_drops.remove_at(index)
		else:
			bomb["position"] = position + offset.normalized() * travel
			bomb_drops[index] = bomb
	for index in range(bomb_explosions.size() - 1, -1, -1):
		var explosion: Dictionary = bomb_explosions[index]
		explosion["age"] = float(explosion["age"]) + delta
		if float(explosion["age"]) >= float(BOMB_EXPLOSION_FRAME_RECTS.size()) * 0.075:
			bomb_explosions.remove_at(index)
		else:
			bomb_explosions[index] = explosion
	if bomb_drops.is_empty() and not bomb_explosions.is_empty() and not bombardment_damage_applied:
		# Aplica el daño una sola vez, al concluir la salva visual de bombas.
		for enemy in enemies:
			score += 10
			zombies_defeated += 1
		enemies.clear()
		for index in range(bosses.size()):
			var boss: Dictionary = bosses[index]
			boss["hp"] = maxi(1, int(boss["hp"]) - 7)
			bosses[index] = boss
		bombardment_damage_applied = true
		_update_hud()

func _play_bomb_impact() -> void:
	if bomb_sound_players.is_empty():
		return
	var player := bomb_sound_players[next_bomb_sound_player]
	next_bomb_sound_player = (next_bomb_sound_player + 1) % bomb_sound_players.size()
	if player.stream == null:
		return
	if player.playing:
		player.stop()
	player.play()
	_apply_audio_settings()

func _update_companions(delta: float) -> void:
	for index in range(companions.size() - 1, -1, -1):
		var companion: Dictionary = companions[index]
		companion["attack_clock"] = maxf(0.0, float(companion["attack_clock"]) - delta)
		companion["hurt_clock"] = maxf(0.0, float(companion["hurt_clock"]) - delta)
		companion["shoot_clock"] = maxf(0.0, float(companion.get("shoot_clock", 0.0)) - delta)
		var position: Vector2 = companion["position"]
		var target := _nearest_enemy_position(position)
		var has_target := not enemies.is_empty() and position.distance_to(target) <= 500.0
		var move_target: Vector2
		if has_target:
			var to_enemy := target - position
			if to_enemy.length_squared() > 0.001:
				companion["aim_direction"] = to_enemy.normalized()
			companion["facing_left"] = to_enemy.x < 0.0
			move_target = position - to_enemy.normalized() * 150.0 if to_enemy.length() < 125.0 else target
			if float(companion["attack_clock"]) <= 0.0 and to_enemy.length() <= 450.0 and to_enemy.length_squared() > 0.001 and bullets.size() < 64:
				var shot_direction: Vector2 = companion["aim_direction"]
				bullets.append({"position": position + shot_direction * 34.0, "direction": shot_direction, "speed": 560.0, "life": 1.2, "damage": 1, "ally_bullet": true, "age": 0.0, "companion_id": int(companion["id"])})
				companion["attack_clock"] = 0.92
				companion["shoot_clock"] = 0.34
				_play_ally_shotgun()
		else:
			companion["wander_clock"] = maxf(0.0, float(companion["wander_clock"]) - delta)
			if float(companion["wander_clock"]) <= 0.0 or position.distance_to(companion["wander_target"]) < 24.0:
				companion["wander_target"] = Vector2(randf_range(90.0, WORLD_SIZE.x - 90.0), randf_range(120.0, WORLD_SIZE.y - 90.0))
				companion["wander_clock"] = randf_range(2.0, 4.2)
			move_target = companion["wander_target"]
		var travel := move_target - position
		if travel.length() > 5.0:
			position += travel.normalized() * 150.0 * delta
			companion["moving"] = true
			if not has_target:
				companion["facing_left"] = travel.x < 0.0
		else:
			companion["moving"] = false
		companion["position"] = position.clamp(Vector2(35.0, 120.0), WORLD_SIZE - Vector2(35.0, 35.0))
		companions[index] = companion

func _play_ally_shotgun() -> void:
	if ally_shotgun_players.is_empty():
		return
	var player := ally_shotgun_players[next_ally_sound_player]
	next_ally_sound_player = (next_ally_sound_player + 1) % ally_shotgun_players.size()
	if player.stream == null:
		return
	if player.playing:
		player.stop()
	player.play()

func _nearest_enemy_position(origin: Vector2 = Vector2.ZERO) -> Vector2:
	if enemies.is_empty():
		return origin
	if origin == Vector2.ZERO:
		origin = player_position
	var nearest: Vector2 = enemies[0]["position"]
	var best := origin.distance_squared_to(nearest)
	for enemy in enemies:
		var candidate: Vector2 = enemy["position"]
		var distance := origin.distance_squared_to(candidate)
		if distance < best:
			best = distance
			nearest = candidate
	return nearest

func _damage_companion(companion_id: int, amount: float) -> void:
	for index in range(companions.size()):
		var companion: Dictionary = companions[index]
		if int(companion["id"]) != companion_id or float(companion["hurt_clock"]) > 0.0:
			continue
		companion["health"] = maxf(0.0, float(companion["health"]) - amount)
		companion["hurt_clock"] = 0.65
		if float(companion["health"]) <= 0.0:
			companions.remove_at(index)
			companion_count = companions.size()
		else:
			companions[index] = companion
		return

func _finish_boss_fight() -> void:
	boss_active = false
	if letter_index == SPANISH_LETTERS.length() - 1:
		_finish_game(true)
	else:
		_advance_to_next_letter()

func _start_letter_stage() -> void:
	if letter_index >= SPANISH_LETTERS.length():
		_finish_game(true)
		return
	collected_letters = 0
	letter_pickups.clear()
	hazards.clear()
	hearts.clear()
	enemies.clear()
	bullets.clear()
	bosses.clear()
	shelter_active = false
	upgrade_pending = false
	boss_active = false
	game_paused = false
	var letter := SPANISH_LETTERS.substr(letter_index, 1)
	spawn_clock = 0.5
	_select_next_map()
	for index in range(5):
		letter_pickups.append({
			"position": Vector2(randf_range(130.0, WORLD_SIZE.x - 130.0), randf_range(150.0, WORLD_SIZE.y - 130.0)),
			"letter": letter,
			"phase": randf_range(0.0, TAU)
		})
	if stage_text != null:
		stage_text.text = "Letra %s  •  Nivel %d / 27" % [letter, letter_index + 1]
	_update_hud()
	queue_redraw()

func _update_letter_pickups() -> void:
	if shelter_active or boss_active or upgrade_pending:
		return
	for index in range(letter_pickups.size() - 1, -1, -1):
		var pickup_position: Vector2 = letter_pickups[index]["position"]
		if pickup_position.distance_to(player_position) <= 39.0:
			letter_pickups.remove_at(index)
			collected_letters += 1
			score += 25
			if collected_letters >= 5:
				_enter_shelter_phase()
			break

func _enter_shelter_phase() -> void:
	collected_letters = 5
	letter_pickups.clear()
	# Los enemigos siguen persiguiendo al jugador durante la carrera hacia la casa.
	shelter_active = true
	# El refugio aparece lejos del jugador para invitarlo a cruzar el mapa.
	shelter_position = Vector2(WORLD_SIZE.x - 170.0, WORLD_SIZE.y - 180.0)
	if player_position.x > WORLD_SIZE.x * 0.55:
		shelter_position.x = 170.0
	if player_position.y > WORLD_SIZE.y * 0.55:
		shelter_position.y = 170.0
	if stage_text != null:
		stage_text.text = "¡Encontraste las 5 letras! Busca el refugio 🏠"

func _check_shelter_entry() -> void:
	if shelter_active and not upgrade_pending and player_position.distance_to(shelter_position) <= 82.0:
		_open_upgrade_choice()

func _open_upgrade_choice() -> void:
	upgrade_pending = true
	game_paused = true
	upgrade_title.text = "¡Refugio! Elige una mejora"
	var companion_option := "Cóndor aliado  •  explora y dispara por su cuenta"
	if companion_count >= 3:
		companion_option = "Curación de aliados  •  recupera la vida de tus cóndores"
	var descriptions := [
		"Superdisparo  •  aumenta el daño y abre más perdigones",
		companion_option,
		"Bomba aérea  •  elimina zombis y daña a los jefes"
	]
	var shuffled_options: Array[int] = [0, 1, 2]
	shuffled_options.shuffle()
	for slot in range(upgrade_buttons.size()):
		var upgrade_id := shuffled_options[slot]
		upgrade_buttons[slot].text = descriptions[upgrade_id]
		upgrade_buttons[slot].set_meta("upgrade_id", upgrade_id)
		upgrade_buttons[slot].visible = true
	upgrade_panel.visible = true

func _choose_upgrade(index: int) -> void:
	if not upgrade_pending:
		return
	var upgrade_id := int(upgrade_buttons[index].get_meta("upgrade_id", index))
	match upgrade_id:
		0:
			shotgun_upgrades += 1
		1:
			if companion_count < 3:
				companions.append({
					"id": next_companion_id,
					"position": (player_position + Vector2(randf_range(-70.0, 70.0), randf_range(-70.0, 70.0))).clamp(Vector2(35.0, 120.0), WORLD_SIZE - Vector2(35.0, 35.0)),
					"health": 50.0,
					"max_health": 50.0,
					"attack_clock": randf_range(0.2, 0.8),
					"hurt_clock": 0.0,
					"shoot_clock": 0.0,
					"aim_direction": Vector2.RIGHT,
					"facing_left": false,
					"moving": false,
					"phase": randf_range(0.0, TAU),
					"wander_clock": 0.0,
					"wander_target": player_position
				})
				next_companion_id += 1
				companion_count = companions.size()
			else:
				for companion_index in range(companions.size()):
					var companion: Dictionary = companions[companion_index]
					companion["health"] = float(companion["max_health"])
					companions[companion_index] = companion
		2:
			bomb_count += 1
	upgrade_panel.visible = false
	upgrade_pending = false
	game_paused = false
	shelter_active = false
	var letter := SPANISH_LETTERS.substr(letter_index, 1)
	if BOSS_LETTERS.has(letter):
		_start_boss_fight(letter)
	else:
		_advance_to_next_letter()

func _advance_to_next_letter() -> void:
	letter_index += 1
	if letter_index >= SPANISH_LETTERS.length():
		_finish_game(true)
	else:
		_start_letter_stage()

func _start_boss_fight(letter: String) -> void:
	boss_active = true
	enemies.clear()
	bullets.clear()
	hazards.clear()
	spawn_clock = 1.0
	var boss_name: String = BOSS_LETTERS[letter]
	bosses.clear()
	var count := 3 if letter == "Z" else 1
	for index in range(count):
		bosses.append({
			"name": boss_name if count == 1 else ["Gorila gigante", "Llama gigante", "Conejo artillero"][index],
			"kind": "jefe_%d" % index if count > 1 else letter,
			"position": player_position + Vector2(310.0 + index * 72.0, -120.0 + index * 120.0),
			"hp": 26 if count == 1 else 17,
			"max_hp": 26 if count == 1 else 17,
			"final_battle": letter == "Z",
			"cooldown": 1.6 + randf(),
			"warning": 0.0,
			"target": Vector2.ZERO
		})
	stage_text.text = "¡JEFE!  %s" % boss_name
	_update_hud()

func _update_bosses(delta: float) -> void:
	if not boss_active:
		return
	for index in range(bosses.size() - 1, -1, -1):
		var boss: Dictionary = bosses[index]
		var position: Vector2 = boss["position"]
		var to_player := player_position - position
		if to_player.length() > 185.0:
			position += to_player.normalized() * (42.0 + letter_index * 0.4) * delta
		boss["position"] = position
		boss["cooldown"] = float(boss["cooldown"]) - delta
		if float(boss["cooldown"]) <= 0.0 and float(boss["warning"]) <= 0.0:
			boss["warning"] = 0.85
			boss["target"] = player_position
		elif float(boss["warning"]) > 0.0:
			boss["warning"] = float(boss["warning"]) - delta
			if float(boss["warning"]) <= 0.0:
				_spawn_boss_attack(boss)
				boss["cooldown"] = 2.5 if int(boss["hp"]) > int(boss["max_hp"]) / 2 else 1.7
		bosses[index] = boss

func _spawn_boss_attack(boss: Dictionary) -> void:
	var boss_name: String = boss["name"]
	var target: Vector2 = boss["target"]
	var origin: Vector2 = boss["position"]
	var damage := _boss_attack_damage(boss)
	if boss_name.contains("Zorro"):
		var acid_offsets: Array[Vector2] = [Vector2(-42, 0), Vector2(0, 0), Vector2(42, 0)]
		for offset in acid_offsets:
			_add_ground_hazard("acid", target + offset, 38.0, 0.35, 2.0, damage * 0.55)
	elif boss_name.contains("Cocodrilo"):
		_add_ground_hazard("rock", target, 56.0, 0.65, 0.3, damage)
	elif boss_name.contains("Llama"):
		hazards.append({"kind": "charge", "position": origin, "target": target, "radius": 34.0, "delay": 0.55, "life": 2.0, "speed": 500.0, "damage": damage})
	elif boss_name.contains("Gorila"):
		_add_ground_hazard("rock", target + Vector2(-62, 0), 49.0, 0.7, 0.3, damage * 0.75)
		_add_ground_hazard("rock", target + Vector2(62, 0), 49.0, 0.7, 0.3, damage * 0.75)
	elif boss_name.contains("Conejo"):
		var aim := (target - origin).normalized()
		for pellet_index in range(5):
			var spread := float(pellet_index - 2) * 0.13
			hazards.append({"kind": "carrot", "position": origin, "velocity": aim.rotated(spread) * 430.0, "radius": 15.0, "delay": 0.0, "life": 2.0, "damage": damage * 0.48})
	else:
		_add_ground_hazard("shockwave", target, _boss_attack_radius(boss), 0.55, 0.25, damage)

func _add_ground_hazard(kind: String, position: Vector2, radius: float, delay: float, life: float, damage: float) -> void:
	hazards.append({"kind": kind, "position": position, "radius": radius, "delay": delay, "life": life, "damage": damage, "hit": false})

func _update_hazards(delta: float) -> void:
	for index in range(hazards.size() - 1, -1, -1):
		var hazard: Dictionary = hazards[index]
		hazard["delay"] = maxf(0.0, float(hazard["delay"]) - delta)
		var kind: String = hazard["kind"]
		var position: Vector2 = hazard["position"]
		if float(hazard["delay"]) > 0.0:
			hazards[index] = hazard
			continue
		if kind == "charge":
			var target: Vector2 = hazard["target"]
			position = position.move_toward(target, float(hazard["speed"]) * delta)
			hazard["position"] = position
			if player_position.distance_to(position) <= float(hazard["radius"]):
				_damage_player(float(hazard["damage"]))
				hazards.remove_at(index)
				continue
			if position.distance_to(target) <= 18.0:
				hazards.remove_at(index)
				continue
		elif kind == "carrot":
			var velocity: Vector2 = hazard["velocity"]
			position += velocity * delta
			hazard["position"] = position
			hazard["life"] = float(hazard["life"]) - delta
			if player_position.distance_to(position) <= float(hazard["radius"]):
				_damage_player(float(hazard["damage"]))
				hazards.remove_at(index)
				continue
			if float(hazard["life"]) <= 0.0 or not Rect2(Vector2.ZERO, WORLD_SIZE).has_point(position):
				hazards.remove_at(index)
				continue
		elif kind == "acid":
			hazard["life"] = float(hazard["life"]) - delta
			if not bool(hazard["hit"]) and player_position.distance_to(position) <= float(hazard["radius"]):
				_damage_player(float(hazard["damage"]))
				hazard["hit"] = true
			if float(hazard["life"]) <= 0.0:
				hazards.remove_at(index)
				continue
		else:
			if not bool(hazard["hit"]) and player_position.distance_to(position) <= float(hazard["radius"]):
				_damage_player(float(hazard["damage"]))
				hazard["hit"] = true
			hazard["life"] = float(hazard["life"]) - delta
			if float(hazard["life"]) <= 0.0:
				hazards.remove_at(index)
				continue
		hazards[index] = hazard

func _damage_player(amount: float) -> void:
	if hurt_clock > 0.0 or game_finished:
		return
	player_health = maxf(0.0, player_health - amount)
	hurt_clock = 0.7
	if is_instance_valid(player_hurt_player) and player_hurt_player.stream != null:
		if player_hurt_player.playing:
			player_hurt_player.stop()
		player_hurt_player.play()
	if player_health <= 0.0:
		_finish_game(false)

func _boss_attack_radius(boss: Dictionary) -> float:
	var radius := 105.0 if int(boss["hp"]) > int(boss["max_hp"]) / 2 else 135.0
	if bool(boss.get("final_battle", false)):
		return 92.0 if int(boss["hp"]) > int(boss["max_hp"]) / 2 else 108.0
	var boss_name: String = boss["name"]
	if boss_name.contains("Gorila"):
		radius += 24.0
	elif boss_name.contains("Llama"):
		radius += 10.0
	elif boss_name.contains("Conejo"):
		radius -= 22.0
	return radius

func _boss_attack_damage(boss: Dictionary) -> float:
	var damage := 16.0 if int(boss["hp"]) > int(boss["max_hp"]) / 2 else 20.0
	if bool(boss.get("final_battle", false)):
		return 9.0 if int(boss["hp"]) > int(boss["max_hp"]) / 2 else 12.0
	var boss_name: String = boss["name"]
	if boss_name.contains("Conejo"):
		damage += 3.0
	return damage

func _set_virtual_movement(direction: Vector2, pressed: bool) -> void:
	if pressed:
		virtual_movement = direction
	elif virtual_movement == direction:
		virtual_movement = Vector2.ZERO

func _set_touch_fire(pressed: bool) -> void:
	touch_fire_pressed = pressed

func _select_next_map() -> void:
	if map_textures.is_empty():
		return
	var next_index := randi_range(0, map_textures.size() - 1)
	if map_textures.size() > 1:
		while next_index == current_map_index:
			next_index = randi_range(0, map_textures.size() - 1)
	current_map_index = next_index
	current_map = map_textures[current_map_index]
	if is_instance_valid(map_text):
		map_text.text = "Escenario %d / %d" % [current_map_index + 1, map_textures.size()]

func _play_random_music() -> void:
	if MUSIC_PATHS.is_empty() or not is_instance_valid(music_player):
		return
	var next_index := randi_range(0, MUSIC_PATHS.size() - 1)
	if MUSIC_PATHS.size() > 1:
		while next_index == last_music_index:
			next_index = randi_range(0, MUSIC_PATHS.size() - 1)
	last_music_index = next_index
	var stream := load(MUSIC_PATHS[next_index]) as AudioStream
	if stream != null:
		music_player.stream = stream
		music_player.play()
		_apply_audio_settings()

func _load_audio_settings() -> void:
	var config := ConfigFile.new()
	if config.load("user://level4_audio.cfg") == OK:
		music_volume = clampf(float(config.get_value("audio", "music", music_volume)), 0.0, 1.0)
		effects_volume = clampf(float(config.get_value("audio", "effects", effects_volume)), 0.0, 1.0)

func _save_audio_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "effects", effects_volume)
	config.save("user://level4_audio.cfg")

func _volume_adjustment(value: float) -> float:
	return -80.0 if value <= 0.001 else linear_to_db(value)

func _apply_audio_settings() -> void:
	if is_instance_valid(music_player):
		music_player.volume_db = -2.0 + _volume_adjustment(music_volume)
	if is_instance_valid(shotgun_player):
		shotgun_player.volume_db = 3.0 + _volume_adjustment(effects_volume)
	for ally_shotgun_player in ally_shotgun_players:
		if is_instance_valid(ally_shotgun_player):
			ally_shotgun_player.volume_db = 3.0 + _volume_adjustment(effects_volume)
	if is_instance_valid(player_hurt_player):
		# Destaca el quejido sobre los demás efectos; sigue obedeciendo el deslizador general.
		player_hurt_player.volume_db = 9.0 + _volume_adjustment(effects_volume)
	if is_instance_valid(zombie_groan_player):
		zombie_groan_player.volume_db = 3.0 + _volume_adjustment(effects_volume)
	for bomb_sound_player in bomb_sound_players:
		if is_instance_valid(bomb_sound_player):
			bomb_sound_player.volume_db = 3.0 + _volume_adjustment(effects_volume)

func _toggle_sound_settings() -> void:
	if game_finished or upgrade_pending:
		return
	settings_open = not settings_open
	settings_overlay.visible = settings_open

func _close_sound_settings() -> void:
	settings_open = false
	if is_instance_valid(settings_overlay):
		settings_overlay.visible = false

func _set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(music_volume_value):
		music_volume_value.text = "%d%%" % roundi(music_volume * 100.0)
	_apply_audio_settings()
	_save_audio_settings()

func _set_effects_volume(value: float) -> void:
	effects_volume = clampf(value, 0.0, 1.0)
	if is_instance_valid(effects_volume_value):
		effects_volume_value.text = "%d%%" % roundi(effects_volume * 100.0)
	_apply_audio_settings()
	_save_audio_settings()

func _build_sound_settings(ui: Control) -> void:
	settings_overlay = Control.new()
	settings_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_overlay.z_index = 20
	settings_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	settings_overlay.visible = false
	ui.add_child(settings_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.02, 0.06, 0.12, 0.65)
	settings_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = get_viewport_rect().size * 0.5 - Vector2(250.0, 175.0)
	panel.size = Vector2(500.0, 350.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#f6fbff"), Color("#ffc933"), 5, 26))
	settings_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var title := _new_label("Ajustes de sonido", 28, Color("#124677"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var music_row := HBoxContainer.new()
	box.add_child(music_row)
	music_row.add_child(_new_label("Música", 18, Color("#254c6e")))
	var music_slider := HSlider.new()
	music_slider.min_value = 0.0
	music_slider.max_value = 1.0
	music_slider.step = 0.01
	music_slider.value = music_volume
	music_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	music_slider.value_changed.connect(_set_music_volume)
	music_row.add_child(music_slider)
	music_volume_value = _new_label("%d%%" % roundi(music_volume * 100.0), 16, Color("#124677"))
	music_volume_value.custom_minimum_size.x = 48.0
	music_row.add_child(music_volume_value)
	var effects_row := HBoxContainer.new()
	box.add_child(effects_row)
	effects_row.add_child(_new_label("Efectos", 18, Color("#254c6e")))
	var effects_slider := HSlider.new()
	effects_slider.min_value = 0.0
	effects_slider.max_value = 1.0
	effects_slider.step = 0.01
	effects_slider.value = effects_volume
	effects_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_slider.value_changed.connect(_set_effects_volume)
	effects_row.add_child(effects_slider)
	effects_volume_value = _new_label("%d%%" % roundi(effects_volume * 100.0), 16, Color("#124677"))
	effects_volume_value.custom_minimum_size.x = 48.0
	effects_row.add_child(effects_volume_value)
	var hint := _new_label("Los cambios se guardan automáticamente.", 15, Color("#52718b"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)
	var close_button := _new_button("Listo", Color("#27b982"), 18)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.pressed.connect(_close_sound_settings)
	box.add_child(close_button)

func _finish_game(won: bool) -> void:
	if game_finished:
		return
	game_finished = true
	upgrade_panel.visible = false
	if is_instance_valid(music_player):
		music_player.stop()
	resume_button.visible = false
	overlay_title.text = "¡Cóndor victorioso!" if won else "¡Vamos otra vez!"
	overlay_message.text = "¡Salvaste la ciudad! Puntos: %d" % score if won else "El cóndor necesita descansar. Puntos: %d" % score
	overlay.visible = true

func _toggle_pause() -> void:
	if game_finished or upgrade_pending or settings_open:
		return
	game_paused = not game_paused
	if game_paused:
		music_player.stream_paused = true
		resume_button.visible = true
		overlay_title.text = "Pausa"
		overlay_message.text = "Respira un poco. Pulsa Continuar cuando quieras volver."
		overlay.visible = true
	else:
		music_player.stream_paused = false
		overlay.visible = false

func _reset_game() -> void:
	player_position = WORLD_SIZE * 0.5
	player_health = 100.0
	score = 0
	zombies_defeated = 0
	letter_index = 0
	collected_letters = 0
	spawn_clock = 0.0
	fire_clock = 0.0
	hurt_clock = 0.0
	bomb_count = 1
	shotgun_upgrades = 0
	companion_count = 0
	next_companion_id = 1
	virtual_movement = Vector2.ZERO
	touch_fire_pressed = false
	game_paused = false
	settings_open = false
	game_finished = false
	shelter_active = false
	upgrade_pending = false
	boss_active = false
	enemies.clear()
	bullets.clear()
	hearts.clear()
	letter_pickups.clear()
	hazards.clear()
	bosses.clear()
	companions.clear()
	bomb_drops.clear()
	bomb_explosions.clear()
	bombardment_damage_applied = false
	_start_letter_stage()
	if is_instance_valid(overlay):
		overlay.visible = false
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	if not is_instance_valid(health_bar):
		return
	health_bar.value = player_health
	health_text.text = "Energía %d / 100" % int(player_health)
	wave_text.text = "Letras: %d / 5   •   Zombis: %d   •   Bombas: %d" % [collected_letters, zombies_defeated, bomb_count]
	score_text.text = "Puntos: %d" % score
	if stage_text != null:
		if boss_active and not bosses.is_empty():
			stage_text.text = "JEFE  •  %s" % bosses[0]["name"]
		elif shelter_active:
			stage_text.text = "¡Busca el refugio para elegir tu mejora!"
		else:
			stage_text.text = "Busca 5 letras %s  •  Nivel %d / 27" % [SPANISH_LETTERS.substr(letter_index, 1), letter_index + 1]
	if pickup_text != null:
		pickup_text.text = "Letras: %d / 5   •   Zombis: %d   •   Bombas: %d" % [collected_letters, zombies_defeated, bomb_count]
	if is_instance_valid(boss_status):
		boss_status.visible = boss_active
		if boss_active and not bosses.is_empty():
			var total_health := 0.0
			var total_max_health := 0.0
			for boss in bosses:
				total_health += float(boss["hp"])
				total_max_health += float(boss["max_hp"])
			boss_status_label.text = "JEFE  •  %s" % bosses[0]["name"]
			boss_health_bar.max_value = maxf(1.0, total_max_health)
			boss_health_bar.value = total_health
	if is_instance_valid(bomb_touch_button):
		bomb_touch_button.text = "BOMBA  •  %d" % bomb_count

func _build_radar(ui: Control) -> void:
	radar_panel = Panel.new()
	radar_panel.position = Vector2(get_viewport_rect().size.x - 238.0, 78.0)
	radar_panel.size = Vector2(220.0, 150.0)
	radar_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.025, 0.08, 0.12, 0.92), Color("#75dfff"), 2, 14))
	ui.add_child(radar_panel)
	var radar_title := _new_label("RADAR  •  letras y refugio", 13, Color.WHITE)
	radar_title.position = Vector2(10.0, 7.0)
	radar_title.size = Vector2(200.0, 20.0)
	radar_panel.add_child(radar_title)
	radar_field = Control.new()
	radar_field.position = Vector2(10.0, 31.0)
	radar_field.size = Vector2(198.0, 108.0)
	radar_field.clip_contents = true
	radar_panel.add_child(radar_field)
	var field_background := ColorRect.new()
	field_background.color = Color("#253b37")
	field_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	field_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radar_field.add_child(field_background)
	var map_grid := ColorRect.new()
	map_grid.color = Color(0.55, 0.77, 0.63, 0.18)
	map_grid.position = Vector2(0.0, 53.0)
	map_grid.size = Vector2(198.0, 2.0)
	map_grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radar_field.add_child(map_grid)
	radar_player_dot = _create_radar_dot(Color("#57caff"), Vector2(11.0, 11.0))
	radar_shelter_dot = _create_radar_dot(Color("#66ff99"), Vector2(12.0, 12.0))
	radar_shelter_dot.visible = false
	for index in range(5):
		radar_letter_dots.append(_create_radar_dot(Color("#ffe45c"), Vector2(8.0, 8.0)))
	for index in range(42):
		radar_enemy_dots.append(_create_radar_dot(Color("#ff6974"), Vector2(5.0, 5.0)))

func _create_radar_dot(color: Color, dot_size: Vector2) -> ColorRect:
	var dot := ColorRect.new()
	dot.color = color
	dot.size = dot_size
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	radar_field.add_child(dot)
	return dot

func _update_radar() -> void:
	if not is_instance_valid(radar_field):
		return
	_radar_place(radar_player_dot, player_position)
	radar_shelter_dot.visible = shelter_active
	if shelter_active:
		_radar_place(radar_shelter_dot, shelter_position)
	for index in range(radar_letter_dots.size()):
		var dot := radar_letter_dots[index]
		dot.visible = index < letter_pickups.size()
		if dot.visible:
			_radar_place(dot, letter_pickups[index]["position"])
	for index in range(radar_enemy_dots.size()):
		var dot := radar_enemy_dots[index]
		dot.visible = index < enemies.size()
		if dot.visible:
			_radar_place(dot, enemies[index]["position"])

func _radar_place(dot: ColorRect, world_position: Vector2) -> void:
	var field_size := radar_field.size
	var map_position := Vector2(world_position.x / WORLD_SIZE.x * field_size.x, world_position.y / WORLD_SIZE.y * field_size.y)
	dot.position = map_position - dot.size * 0.5

func _setup_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.position = player_position
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	add_child(camera)

func _build_interface() -> void:
	var canvas := CanvasLayer.new()
	canvas.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(canvas)
	var ui := Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(ui)
	var hud := PanelContainer.new()
	hud.position = Vector2(18.0, 14.0)
	hud.size = Vector2(760.0, 116.0)
	hud.add_theme_stylebox_override("panel", _panel_style(Color(0.03, 0.09, 0.15, 0.9), Color("#78d7ff"), 3, 18))
	ui.add_child(hud)
	var hud_content := VBoxContainer.new()
	hud_content.add_theme_constant_override("separation", 0)
	hud.add_child(hud_content)
	stage_text = _new_label("Letra A  •  Nivel 1 / 27", 18, Color("#fff3a1"))
	hud_content.add_child(stage_text)
	health_text = _new_label("Energía 100 / 100", 18, Color.WHITE)
	hud_content.add_child(health_text)
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(0, 18)
	health_bar.max_value = 100.0
	health_bar.value = 100.0
	health_bar.show_percentage = false
	hud_content.add_child(health_bar)
	var stats := HBoxContainer.new()
	wave_text = _new_label("Letras: 0 / 5", 15, Color("#ddf5ff"))
	wave_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats.add_child(wave_text)
	pickup_text = wave_text
	score_text = _new_label("Puntos: 0", 16, Color.WHITE)
	stats.add_child(score_text)
	hud_content.add_child(stats)
	map_text = _new_label("Escenario", 13, Color("#ddf5ff"))
	map_text.position = Vector2(30.0, 136.0)
	ui.add_child(map_text)
	_build_radar(ui)
	boss_status = PanelContainer.new()
	boss_status.position = Vector2(get_viewport_rect().size.x * 0.5 - 220.0, 140.0)
	boss_status.size = Vector2(440.0, 76.0)
	boss_status.add_theme_stylebox_override("panel", _panel_style(Color(0.12, 0.06, 0.12, 0.92), Color("#ff7182"), 3, 18))
	ui.add_child(boss_status)
	var boss_box := VBoxContainer.new()
	boss_box.add_theme_constant_override("separation", 2)
	boss_status.add_child(boss_box)
	boss_status_label = _new_label("JEFE", 16, Color.WHITE)
	boss_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_box.add_child(boss_status_label)
	boss_health_bar = ProgressBar.new()
	boss_health_bar.custom_minimum_size = Vector2(0.0, 20.0)
	boss_health_bar.show_percentage = false
	boss_box.add_child(boss_health_bar)
	boss_status.visible = false
	var controls := _new_label("WASD/Flechas mover  •  Ratón apuntar y clic disparar  •  B bomba  •  Esc pausa", 16, Color.WHITE)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	controls.position = Vector2(150.0, get_viewport_rect().size.y - 42.0)
	controls.size = Vector2(980.0, 32.0)
	controls.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	controls.add_theme_constant_override("shadow_offset_x", 2)
	controls.add_theme_constant_override("shadow_offset_y", 2)
	ui.add_child(controls)
	var pause_button := _new_button("⏸  Pausa", Color("#167db2"), 17)
	pause_button.position = Vector2(get_viewport_rect().size.x - 156.0, 20.0)
	pause_button.size = Vector2(132.0, 48.0)
	pause_button.pressed.connect(_toggle_pause)
	ui.add_child(pause_button)
	var sound_button := _new_button("♫  Sonido", Color("#8053d6"), 16)
	sound_button.position = Vector2(get_viewport_rect().size.x - 310.0, 20.0)
	sound_button.size = Vector2(142.0, 48.0)
	sound_button.pressed.connect(_toggle_sound_settings)
	ui.add_child(sound_button)
	_build_sound_settings(ui)
	overlay = PanelContainer.new()
	overlay.z_index = 10
	overlay.position = get_viewport_rect().size * 0.5 - Vector2(245.0, 150.0)
	overlay.size = Vector2(490.0, 300.0)
	overlay.add_theme_stylebox_override("panel", _panel_style(Color("#f6fbff"), Color("#ffc933"), 5, 28))
	ui.add_child(overlay)
	var overlay_box := VBoxContainer.new()
	overlay_box.alignment = BoxContainer.ALIGNMENT_CENTER
	overlay_box.add_theme_constant_override("separation", 16)
	overlay.add_child(overlay_box)
	overlay_title = _new_label("Pausa", 30, Color("#124677"))
	overlay_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_box.add_child(overlay_title)
	overlay_message = _new_label("", 18, Color("#254c6e"))
	overlay_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	overlay_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overlay_box.add_child(overlay_message)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 10)
	overlay_box.add_child(actions)
	resume_button = _new_button("Continuar", Color("#27b982"), 17)
	resume_button.pressed.connect(_toggle_pause)
	actions.add_child(resume_button)
	var restart_button := _new_button("Jugar otra vez", Color("#ffbc28"), 17)
	restart_button.add_theme_color_override("font_color", Color("#44330a"))
	restart_button.pressed.connect(_restart_game)
	actions.add_child(restart_button)
	var return_button := _new_button("Volver a niveles", Color("#348be1"), 17)
	return_button.pressed.connect(func() -> void: close_requested.emit())
	actions.add_child(return_button)
	resume_button.visible = false
	overlay.visible = false
	upgrade_panel = PanelContainer.new()
	upgrade_panel.z_index = 10
	upgrade_panel.position = get_viewport_rect().size * 0.5 - Vector2(325.0, 190.0)
	upgrade_panel.size = Vector2(650.0, 380.0)
	upgrade_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f6fbff"), Color("#ffc933"), 5, 28))
	ui.add_child(upgrade_panel)
	var upgrade_box := VBoxContainer.new()
	upgrade_box.alignment = BoxContainer.ALIGNMENT_CENTER
	upgrade_box.add_theme_constant_override("separation", 12)
	upgrade_panel.add_child(upgrade_box)
	upgrade_title = _new_label("¡Refugio! Elige una mejora", 26, Color("#124677"))
	upgrade_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_box.add_child(upgrade_title)
	var upgrade_hint := _new_label("Tu decisión te ayudará en las próximas letras y jefes.", 16, Color("#254c6e"))
	upgrade_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgrade_box.add_child(upgrade_hint)
	var upgrade_colors: Array[Color] = [Color("#f7b928"), Color("#2dbb8a"), Color("#458ee7")]
	for index in range(3):
		var choice := _new_button("Mejora", upgrade_colors[index], 16)
		choice.custom_minimum_size = Vector2(580.0, 56.0)
		choice.pressed.connect(_choose_upgrade.bind(index))
		upgrade_box.add_child(choice)
		upgrade_buttons.append(choice)
	upgrade_panel.visible = false
	if DisplayServer.is_touchscreen_available():
		_build_touch_controls(ui)

func _build_touch_controls(ui: Control) -> void:
	var dpad := GridContainer.new()
	dpad.columns = 3
	dpad.position = Vector2(28.0, get_viewport_rect().size.y - 202.0)
	ui.add_child(dpad)
	var empty_left := Control.new()
	empty_left.custom_minimum_size = Vector2(66.0, 62.0)
	dpad.add_child(empty_left)
	_add_touch_direction_button(dpad, "▲", Vector2.UP)
	var empty_right := Control.new()
	empty_right.custom_minimum_size = Vector2(66.0, 62.0)
	dpad.add_child(empty_right)
	_add_touch_direction_button(dpad, "◀", Vector2.LEFT)
	var center := Control.new()
	center.custom_minimum_size = Vector2(66.0, 62.0)
	dpad.add_child(center)
	_add_touch_direction_button(dpad, "▶", Vector2.RIGHT)
	var empty_bottom := Control.new()
	empty_bottom.custom_minimum_size = Vector2(66.0, 62.0)
	dpad.add_child(empty_bottom)
	_add_touch_direction_button(dpad, "▼", Vector2.DOWN)
	var actions := VBoxContainer.new()
	actions.position = Vector2(get_viewport_rect().size.x - 178.0, get_viewport_rect().size.y - 170.0)
	ui.add_child(actions)
	var fire_button := _new_button("DISPARAR", Color("#e74f5c"), 17)
	fire_button.custom_minimum_size = Vector2(145.0, 62.0)
	fire_button.button_down.connect(_set_touch_fire.bind(true))
	fire_button.button_up.connect(_set_touch_fire.bind(false))
	actions.add_child(fire_button)
	bomb_touch_button = _new_button("BOMBA  •  %d" % bomb_count, Color("#a45fe1"), 15)
	bomb_touch_button.custom_minimum_size = Vector2(145.0, 54.0)
	bomb_touch_button.pressed.connect(_use_bomb)
	actions.add_child(bomb_touch_button)

func _add_touch_direction_button(parent: GridContainer, text: String, direction: Vector2) -> void:
	var button := _new_button(text, Color("#2179bf"), 24)
	button.custom_minimum_size = Vector2(66.0, 62.0)
	button.button_down.connect(_set_virtual_movement.bind(direction, true))
	button.button_up.connect(_set_virtual_movement.bind(direction, false))
	parent.add_child(button)

func _restart_game() -> void:
	game_paused = false
	_reset_game()
	if is_instance_valid(music_player):
		_play_random_music()

func _draw_condor() -> void:
	var use_aim_pose := condor_aim_poses != null and (not player_moving or shoot_pose_clock > 0.0)
	if use_aim_pose:
		# La hoja trae ocho posturas ya orientadas; se elige la más cercana sin rotar al personaje.
		var direction_angle := fposmod(aim_direction.angle(), TAU)
		var octant := int(round(direction_angle / (PI / 4.0))) % 8
		var pose_columns: Array[int] = [2, 3, 0, 1, 2, 3, 0, 1]
		var pose_rows: Array[int] = [0, 0, 1, 1, 1, 1, 0, 0]
		var cell_size := Vector2(float(condor_aim_poses.get_width()) / 4.0, float(condor_aim_poses.get_height()) / 2.0)
		var source := Rect2(Vector2(float(pose_columns[octant]) * cell_size.x, float(pose_rows[octant]) * cell_size.y), cell_size)
		draw_texture_rect_region(condor_aim_poses, Rect2(player_position - Vector2(58.0, 72.0), Vector2(116.0, 144.0)), source, Color.WHITE, false, true)
		if muzzle_flash > 0.0:
			var flash_strength := muzzle_flash / 0.12
			draw_circle(player_position + aim_direction * 63.0, 7.0 + flash_strength * 8.0, Color(1.0, 0.68, 0.18, flash_strength))
		return

	var frame_index := int(animation_clock * 10.0) % 12 if player_moving else 0
	var frame_size := Vector2(float(condor_sprites.get_width()) / 6.0, float(condor_sprites.get_height()) / 2.0) if condor_sprites != null else Vector2.ZERO
	# Al caminar conserva su animación. El arma gira hacia el apuntado; el cuerpo permanece erguido.
	if shotgun_texture != null:
		draw_set_transform(player_position, aim_direction.angle())
		var recoil := 7.0 if muzzle_flash > 0.0 else 0.0
		draw_texture_rect(shotgun_texture, Rect2(Vector2(8.0 - recoil, -23.0), Vector2(112.0, 37.0)), false)
		if muzzle_flash > 0.0:
			var flash_strength := muzzle_flash / 0.12
			draw_circle(Vector2(118.0, -4.0), 7.0 + flash_strength * 8.0, Color(1.0, 0.68, 0.18, flash_strength))
		draw_set_transform(Vector2.ZERO)
	if condor_sprites != null:
		var source := Rect2(Vector2(float(frame_index % 6) * frame_size.x, float(frame_index / 6) * frame_size.y), frame_size)
		var facing_scale := Vector2(-1.0, 1.0) if aim_direction.x < -0.05 else Vector2.ONE
		draw_set_transform(player_position, 0.0, facing_scale)
		draw_texture_rect_region(condor_sprites, Rect2(Vector2(-54.0, -65.0), Vector2(116.0, 130.0)), source, Color.WHITE, false, true)
		draw_set_transform(Vector2.ZERO)

func _draw_bullet(bullet: Dictionary) -> void:
	var upgraded := bool(bullet.get("upgraded", false)) and bullet_upgraded_texture != null
	var is_ally_bullet := bool(bullet.get("ally_bullet", false)) and ally_bullet_texture != null
	var texture: Texture2D = ally_bullet_texture if is_ally_bullet else bullet_upgraded_texture if upgraded else bullet_base_texture
	if texture == null:
		var position: Vector2 = bullet["position"]
		draw_circle(position, 7.0, Color("#ffe56b"))
		draw_circle(position, 3.5, Color("#fff9cd"))
		return
	var frame_count := 4 if upgraded else 8
	var frame_width := float(texture.get_width()) / float(frame_count)
	var frame_index := mini(int(float(bullet.get("age", 0.0)) * 16.0), frame_count - 1)
	var source := Rect2(float(frame_index) * frame_width, 0.0, frame_width, float(texture.get_height()))
	var destination_size := Vector2(70.0, 38.0) if upgraded else Vector2(48.0, 36.0)
	var bullet_position: Vector2 = bullet["position"]
	var bullet_direction: Vector2 = bullet["direction"]
	draw_set_transform(bullet_position, bullet_direction.angle())
	draw_texture_rect_region(texture, Rect2(-destination_size * 0.5, destination_size), source, Color.WHITE, false, true)
	draw_set_transform(Vector2.ZERO)

func _draw_zombie(enemy: Dictionary) -> void:
	var position: Vector2 = enemy["position"]
	var wobble := sin(animation_clock * 6.0 + float(enemy["phase"])) * 2.0
	var kind: String = enemy["kind"]
	var sprite: Texture2D = zombie_cat_texture
	match kind:
		"perro": sprite = zombie_dog_texture
		"cuy": sprite = zombie_cuy_texture
	if sprite != null:
		var frame_size := Vector2(float(sprite.get_width()) / 6.0, float(sprite.get_height()) / 2.0)
		var frame_index := int(animation_clock * 9.0 + float(enemy["phase"])) % 12
		var source := Rect2(Vector2(float(frame_index % 6) * frame_size.x, float(frame_index / 6) * frame_size.y), frame_size)
		var horizontal_scale := -1.0 if bool(enemy.get("facing_left", false)) else 1.0
		var sprite_rect := Rect2(Vector2(-49.0, -52.0), Vector2(98.0, 104.0))
		if kind == "perro":
			# El perro es más ancho que alto; conserva su proporción al dibujarlo.
			sprite_rect = Rect2(Vector2(-57.0, -46.0), Vector2(114.0, 92.0))
		draw_set_transform(position, wobble * 0.015, Vector2(horizontal_scale, 1.0))
		draw_texture_rect_region(sprite, sprite_rect, source, Color.WHITE, false, true)
		draw_set_transform(Vector2.ZERO)
		return
	var tint := Color("#81b94d") if kind == "gato" else Color("#8aab55") if kind == "perro" else Color("#68a95c")
	draw_set_transform(position, wobble * 0.02)
	# Cuerpo blandito, ojos grandes y orejas según el animal; aspecto de caricatura.
	draw_circle(Vector2(0.0, 8.0), 16.0, Color("#40584c"))
	if kind == "gato":
		draw_colored_polygon(PackedVector2Array([Vector2(-14, -6), Vector2(-13, -21), Vector2(-3, -12)]), tint)
		draw_colored_polygon(PackedVector2Array([Vector2(4, -12), Vector2(15, -22), Vector2(14, -4)]), tint)
	elif kind == "perro":
		draw_circle(Vector2(-13, -10), 6.0, Color("#596349"))
		draw_circle(Vector2(13, -10), 6.0, Color("#596349"))
	else:
		draw_ellipse_placeholder(position, 1.0)
	draw_circle(Vector2(0.0, -4.0), 14.0, tint)
	draw_circle(Vector2(-5.0, -7.0), 3.5, Color.WHITE)
	draw_circle(Vector2(5.0, -7.0), 3.5, Color.WHITE)
	draw_circle(Vector2(-4.5, -6.5), 1.5, Color("#d94156"))
	draw_circle(Vector2(5.5, -6.5), 1.5, Color("#d94156"))
	draw_line(Vector2(-4.0, 1.0), Vector2(4.0, 1.0), Color("#314035"), 2.0, true)
	if kind == "gato" or kind == "perro":
		draw_string(ThemeDB.fallback_font, Vector2(-11.0, 19.0), "GATO" if kind == "gato" else "PERRO", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color.WHITE)
	draw_set_transform(Vector2.ZERO)

func draw_ellipse_placeholder(_position: Vector2, _scale: float) -> void:
	# Orejas pequeñas del cuy zombi, dibujadas como manchas redondeadas.
	draw_circle(Vector2(-12.0, -12.0), 4.0, Color("#77a862"))
	draw_circle(Vector2(12.0, -12.0), 4.0, Color("#77a862"))

func _draw_heart(position: Vector2) -> void:
	draw_circle(position + Vector2(-5.0, -2.0), 7.0, Color("#ff7380"))
	draw_circle(position + Vector2(5.0, -2.0), 7.0, Color("#ff7380"))
	draw_colored_polygon(PackedVector2Array([position + Vector2(-12, 0), position + Vector2(12, 0), position + Vector2(0, 14)]), Color("#ff7380"))

func _draw_letter_pickup(pickup: Dictionary) -> void:
	var position: Vector2 = pickup["position"]
	var bob := sin(animation_clock * 3.0 + float(pickup["phase"])) * 5.0
	var bubble_position := position + Vector2(0.0, bob)
	draw_circle(bubble_position + Vector2(0.0, 5.0), 23.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(bubble_position, 24.0, Color("#ffdc4e"))
	draw_circle(bubble_position, 18.0, Color("#fff8cd"))
	draw_string(ThemeDB.fallback_font, bubble_position + Vector2(-8.0, 7.0), pickup["letter"], HORIZONTAL_ALIGNMENT_LEFT, -1.0, 22, Color("#145287"))

func _draw_shelter() -> void:
	var pulse := 1.0 + sin(animation_clock * 4.0) * 0.08
	draw_circle(shelter_position, 92.0 * pulse, Color(0.25, 1.0, 0.58, 0.18))
	draw_arc(shelter_position, 98.0 * pulse, 0.0, TAU, 40, Color("#65ffb8"), 5.0, true)
	if shelter_texture != null:
		draw_texture_rect(shelter_texture, Rect2(shelter_position - Vector2(128.0, 85.0), Vector2(256.0, 170.0)), false)
	else:
		draw_colored_polygon(PackedVector2Array([shelter_position + Vector2(-54, -12), shelter_position + Vector2(0, -64), shelter_position + Vector2(54, -12)]), Color("#e95e45"))
		draw_rect(Rect2(shelter_position + Vector2(-44, -12), Vector2(88, 72)), Color("#9a6038"))
		draw_rect(Rect2(shelter_position + Vector2(-12, 20), Vector2(24, 40)), Color("#80533d"))
	var direction := shelter_position - player_position
	if direction.length() > 1.0:
		var indicator := player_position + direction.normalized() * 86.0
		draw_circle(indicator, 15.0, Color("#29c982"))
		draw_line(indicator, indicator + direction.normalized() * 30.0, Color.WHITE, 5.0, true)

func _draw_boss(boss: Dictionary) -> void:
	var position: Vector2 = boss["position"]
	var boss_name: String = boss["name"]
	var color := Color("#b86a4a")
	if boss_name.contains("Cocodrilo"):
		color = Color("#55a873")
	elif boss_name.contains("Llama"):
		color = Color("#d98e65")
	elif boss_name.contains("Gorila"):
		color = Color("#695b78")
	elif boss_name.contains("Conejo"):
		color = Color("#d1c3a4")
	draw_circle(position, 52.0, Color(0.0, 0.0, 0.0, 0.25))
	draw_circle(position, 46.0, color)
	draw_circle(position + Vector2(-15, -8), 7.0, Color.WHITE)
	draw_circle(position + Vector2(15, -8), 7.0, Color.WHITE)
	draw_circle(position + Vector2(-14, -7), 3.0, Color("#d73751"))
	draw_circle(position + Vector2(16, -7), 3.0, Color("#d73751"))
	draw_line(position + Vector2(-11, 14), position + Vector2(11, 14), Color("#3f343c"), 4.0, true)
	var bar_rect := Rect2(position + Vector2(-45, 57), Vector2(90, 11))
	draw_rect(bar_rect, Color("#34303a"))
	var health_ratio := clampf(float(boss["hp"]) / float(boss["max_hp"]), 0.0, 1.0)
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * health_ratio, bar_rect.size.y)), Color("#ff5870"))
	if float(boss["warning"]) > 0.0:
		var target: Vector2 = boss["target"]
		var warning_ratio := clampf(float(boss["warning"]) / 0.85, 0.0, 1.0)
		var warning_radius := _boss_attack_radius(boss)
		draw_circle(target, warning_radius, Color(1.0, 0.16, 0.20, 0.13 + (1.0 - warning_ratio) * 0.17))
		draw_arc(target, warning_radius + 2.0, 0.0, TAU, 40, Color("#ff5966"), 3.0, true)

func _draw_companion(companion: Dictionary) -> void:
	var position: Vector2 = companion["position"]
	var aim_direction: Vector2 = companion.get("aim_direction", Vector2.RIGHT)
	var use_shoot_pose := ally_aim_poses != null and float(companion.get("shoot_clock", 0.0)) > 0.0
	if use_shoot_pose:
		var direction_angle := fposmod(aim_direction.angle(), TAU)
		var octant := int(round(direction_angle / (PI / 4.0))) % 8
		var pose_columns: Array[int] = [2, 3, 0, 1, 2, 3, 1, 1]
		var pose_rows: Array[int] = [0, 0, 1, 1, 1, 1, 0, 0]
		var cell_size := Vector2(float(ally_aim_poses.get_width()) / 4.0, float(ally_aim_poses.get_height()) / 2.0)
		var source := Rect2(Vector2(float(pose_columns[octant]) * cell_size.x, float(pose_rows[octant]) * cell_size.y), cell_size)
		draw_texture_rect_region(ally_aim_poses, Rect2(position - Vector2(42.0, 60.0), Vector2(84.0, 120.0)), source, Color.WHITE, false, true)
	elif ally_walk_sprites != null:
		var frame_size := Vector2(float(ally_walk_sprites.get_width()) / 6.0, float(ally_walk_sprites.get_height()) / 2.0)
		var frame_index := int((animation_clock + float(companion.get("phase", 0.0))) * 9.0) % 12 if bool(companion.get("moving", false)) else 0
		var source := Rect2(Vector2(float(frame_index % 6) * frame_size.x, float(frame_index / 6) * frame_size.y), frame_size)
		var horizontal_scale := -1.0 if bool(companion.get("facing_left", false)) else 1.0
		draw_set_transform(position, 0.0, Vector2(horizontal_scale, 1.0))
		draw_texture_rect_region(ally_walk_sprites, Rect2(Vector2(-48.0, -48.0), Vector2(96.0, 96.0)), source, Color.WHITE, false, true)
		draw_set_transform(Vector2.ZERO)
	var life_ratio := clampf(float(companion["health"]) / float(companion["max_health"]), 0.0, 1.0)
	var bar_rect := Rect2(position + Vector2(-26.0, -67.0), Vector2(52.0, 7.0))
	draw_rect(bar_rect, Color("#302d35"))
	draw_rect(Rect2(bar_rect.position, Vector2(bar_rect.size.x * life_ratio, bar_rect.size.y)), Color("#63e778" if life_ratio > 0.35 else "#ff5966"))

func _draw_bomb_drop(bomb: Dictionary) -> void:
	var position: Vector2 = bomb["position"]
	var target: Vector2 = bomb["target"]
	# El círculo marca el punto de impacto mientras la bomba cae desde arriba.
	draw_circle(target, 28.0, Color(1.0, 0.25, 0.12, 0.12))
	draw_arc(target, 30.0, 0.0, TAU, 24, Color(1.0, 0.72, 0.24, 0.78), 3.0, true)
	if bomb_atlas != null:
		draw_texture_rect_region(bomb_atlas, Rect2(position - Vector2(31.0, 60.0), Vector2(62.0, 120.0)), Rect2(20.0, 0.0, 145.0, 278.0), Color.WHITE, false, true)
	else:
		draw_circle(position, 13.0, Color("#282833"))
		draw_circle(position + Vector2(-3.0, -11.0), 5.0, Color("#ff8d24"))

func _draw_bomb_explosion(explosion: Dictionary) -> void:
	if bomb_atlas == null:
		var fallback_position: Vector2 = explosion["position"]
		draw_circle(fallback_position, 54.0, Color(1.0, 0.28, 0.05, 0.55))
		return
	var age := float(explosion["age"])
	var frame_index := mini(int(age / 0.075), BOMB_EXPLOSION_FRAME_RECTS.size() - 1)
	var source: Rect2 = BOMB_EXPLOSION_FRAME_RECTS[frame_index]
	var fade := clampf((float(BOMB_EXPLOSION_FRAME_RECTS.size()) * 0.075 - age) / 0.24, 0.0, 1.0)
	var destination_size := Vector2(300.0, 205.0)
	var position: Vector2 = explosion["position"]
	draw_texture_rect_region(bomb_atlas, Rect2(position - destination_size * 0.5, destination_size), source, Color(1.0, 1.0, 1.0, fade), false, true)

func _draw_hazard(hazard: Dictionary) -> void:
	var kind: String = hazard["kind"]
	var position: Vector2 = hazard["position"]
	if kind == "charge":
		var target: Vector2 = hazard["target"]
		draw_line(position, target, Color(1.0, 0.18, 0.24, 0.28), 44.0, true)
		draw_line(position, target, Color("#ff5367"), 5.0, true)
		draw_circle(position, 26.0, Color("#ffe177"))
		return
	if kind == "carrot":
		var velocity: Vector2 = hazard["velocity"]
		var direction := velocity.normalized()
		var side := direction.rotated(PI / 2.0) * 8.0
		draw_colored_polygon(PackedVector2Array([position + direction * 15.0, position - direction * 10.0 + side, position - direction * 10.0 - side]), Color("#ff9f37"))
		draw_circle(position, 5.0, Color("#ffdc62"))
		return
	var fill_color := Color("#74e65b") if kind == "acid" else Color("#ff6570")
	var radius := float(hazard["radius"])
	var alpha := 0.22 if float(hazard["delay"]) > 0.0 else 0.38
	draw_circle(position, radius, Color(fill_color.r, fill_color.g, fill_color.b, alpha))
	draw_arc(position, radius, 0.0, TAU, 36, fill_color, 4.0, true)
	if kind == "rock":
		draw_circle(position + Vector2(0.0, -5.0), radius * 0.42, Color("#8c8580"))
		draw_line(position + Vector2(-14, 7), position + Vector2(13, -8), Color("#d5c9b6"), 3.0, true)

func _new_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _new_button(text: String, color: Color, font_size: int) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(130.0, 48.0)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _panel_style(color, Color(1, 1, 1, 0.75), 2, 14))
	button.add_theme_stylebox_override("hover", _panel_style(color.lightened(0.15), Color.WHITE, 3, 14))
	button.add_theme_stylebox_override("pressed", _panel_style(color.darkened(0.12), Color.WHITE, 2, 14))
	return button

func _panel_style(fill: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style

func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
