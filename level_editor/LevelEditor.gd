extends Node2D

const SAVE_FILES_DIRECTORY = "user://saved_levels/"

onready var player_ui = $World/CanvasLayer
onready var editor_ui = $EditorUI
onready var game_manager = $World
onready var command_input = $EditorUI/CommandInput
onready var ground_tile_button = $EditorUI/TilePalette/GridContainer/GroundTile
onready var spikes_tile_button = $EditorUI/TilePalette/GridContainer/SpikesTile
onready var tilemap = $TileMap
onready var saved_levels_container = $EditorUI/LoadLevels/Panel/ScrollContainer/VBoxContainer
onready var save_level_button = $EditorUI/SaveButton
onready var save_level_name_input = $EditorUI/SaveButton/SaveFileInput
onready var confirm_save_level_dialog = $EditorUI/SaveButton/ConfirmOverwrite
onready var save_anim_player = $EditorUI/SaveButton/SaveSuccessfuly/AnimationPlayer

var in_edit_mode = true

var top_left_pos = Vector2()
var bot_right_pos = Vector2()

func _ready():
	set_edit_mode()
	command_input.connect("text_entered", self, "enter_input_command")
	ground_tile_button.connect("button_up", self, "select_ground_tile")
	spikes_tile_button.connect("button_up", self, "select_spikes_tile")
	
	top_left_pos = tilemap.world_to_map($TileMap/TopLeft.global_position)
	bot_right_pos = tilemap.world_to_map($TileMap/BotRight.global_position)
	
	var d = Directory.new()
	if not d.dir_exists(SAVE_FILES_DIRECTORY):
		d.make_dir(SAVE_FILES_DIRECTORY)
	update_saved_levels_list()

func set_play_mode():
	for child in editor_ui.get_children():
		child.hide()
	game_manager.enable()
	in_edit_mode = false
	cur_tile = TILES.NONE
	selected_sprite_display.hide()

func set_edit_mode():
	for child in editor_ui.get_children():
		child.show()
	game_manager.disable()
	in_edit_mode = true
	selected_sprite_display.show()
	selected_sprite_display.texture = null

func enter_input_command(command_text: String):
	game_manager.parse_chat_input(SettingsManager.channel_name, command_text, true)
	command_input.text = ""

enum TILES {NONE, GROUND, SPIKES}
var cur_tile = TILES.NONE
onready var selected_sprite_display = $SelectedSpriteDisplay
const GROUND_TILE_ID = 1
var spike_obj = preload("res://Environment/Spikes.tscn")
var all_spikes_placed = {}
var last_x = 9999
var last_y = 9999
func select_spikes_tile():
	cur_tile = TILES.SPIKES
	selected_sprite_display.texture = spikes_tile_button.icon

func select_ground_tile():
	cur_tile = TILES.GROUND
	selected_sprite_display.texture = ground_tile_button.icon

func _process(delta):
	var tilepos_hovering_over = tilemap.world_to_map(get_global_mouse_position())
	selected_sprite_display.global_position = tilemap.map_to_world(tilepos_hovering_over) + Vector2(8, 8)
	var x := int(round(tilepos_hovering_over.x))
	var y := int(round(tilepos_hovering_over.y))
	if x >= top_left_pos.x and x <= bot_right_pos.x and y >= top_left_pos.y and y <= bot_right_pos.y:
		if y != last_y or x != last_x:
			if Input.is_action_pressed("place_tile"):
				place_tile(x, y)
		if Input.is_action_pressed("delete_tile"):
			delete_tile(x, y)

func place_tile(x: int, y: int):
	if cur_tile != TILES.NONE:
		delete_tile(x, y)
	if cur_tile == TILES.SPIKES:
		place_spike(x, y)
	elif cur_tile == TILES.GROUND:
		place_ground_tile(x, y)
	last_x = x
	last_y = y

func place_spike(x: int, y: int):
	var spike_inst = spike_obj.instance()
	all_spikes_placed[get_id_from_coords(x, y)] = spike_inst
	get_tree().get_root().add_child(spike_inst)
	spike_inst.global_position = tilemap.map_to_world(Vector2(x, y)) + Vector2(8,8)
	
	var left_tile_taken = tilemap.get_cell(x - 1, y) >= 0
	var right_tile_taken = tilemap.get_cell(x + 1, y) >= 0
	var top_tile_taken = tilemap.get_cell(x, y - 1) >= 0
	var bot_tile_taken = tilemap.get_cell(x, y + 1) >= 0

	update()
	if !bot_tile_taken: # default rotation
		if left_tile_taken:
			spike_inst.global_rotation = deg2rad(90)
		elif right_tile_taken:
			spike_inst.global_rotation = deg2rad(-90)
		elif top_tile_taken:
			spike_inst.global_rotation = deg2rad(180)

func place_ground_tile(x: int, y: int):
	tilemap.set_cell(x, y, GROUND_TILE_ID)
	tilemap.update_bitmask_area(Vector2(x, y))

func delete_tile(x: int, y: int):
	tilemap.set_cell(x, y, -1)
	var spike_id = get_id_from_coords(x, y)
	if spike_id in all_spikes_placed:
		all_spikes_placed[spike_id].queue_free()
		all_spikes_placed.erase(spike_id)

func get_id_from_coords(x: int, y: int):
	return str(x) + "," + str(y)

func clear_map():
	var start_x = int(round(top_left_pos.x))
	var end_x = int(round(bot_right_pos.x))
	var start_y = int(round(top_left_pos.y))
	var end_y = int(round(bot_right_pos.y))
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
			delete_tile(x, y)
	for spike_id in all_spikes_placed:
		all_spikes_placed[spike_id].queue_free()

func update_saved_levels_list():
	for child in saved_levels_container.get_children():
		child.queue_free()
	for save_file_name in get_list_of_save_file_names():
		var new_button = Button.new()
		new_button.rect_min_size.y = 20
		new_button.text = save_file_name
		new_button.connect("button_up", self, "load_level", [save_file_name])
		saved_levels_container.add_child(new_button)

var last_save_file_attempted_loading = ""
func force_save():
	save_level(last_save_file_attempted_loading)

func attempt_save():
	var save_file_name = save_level_name_input.text
	if save_file_name == "":
		return
	var save_file_path = save_file_name_to_path(save_file_name)
	var saved_level = File.new()
	if saved_level.file_exists(save_file_path):
		last_save_file_attempted_loading = save_file_name
		confirm_save_level_dialog.show()
	else:
		save_level(save_file_name)

func save_level(save_file_name: String):
	var ground_tiles_data = []
	var start_x = int(round(top_left_pos.x))
	var end_x = int(round(bot_right_pos.x))
	var start_y = int(round(top_left_pos.y))
	var end_y = int(round(bot_right_pos.y))
	for y in range(start_y, end_y):
		for x in range(start_x, end_x):
				if tilemap.get_cell(x, y) >= 0:
					ground_tiles_data.append({"x" : x, "y" : y})
	
	var spikes_data = []
	for spike in all_spikes_placed:
		var data = {}
		var spike_obj = all_spikes_placed[spike]
		data.x = to_int(spike_obj.global_position.x)
		data.y = to_int(spike_obj.global_position.y)
		spikes_data.append(data)
	
	var save_data = {
		"ground_tiles_data" : ground_tiles_data,
		"spikes_data" : spikes_data,
	}
	
	var save_file_path = save_file_name_to_path(save_file_name)
	var save_game = File.new()
	save_game.open(save_file_path, File.WRITE)
	save_game.store_line(to_json(save_data))
	save_game.close()
	save_anim_player.play("fade_out")
	update_saved_levels_list()

func load_level(save_file_name: String):
	clear_map()
	var save_file_path = save_file_name_to_path(save_file_name)
	var saved_level = File.new()
	var loaded_data = {}
	if saved_level.file_exists(save_file_path):
		saved_level.open(save_file_path, File.READ)
		loaded_data = parse_json(saved_level.get_line())
	else:
		saved_level.close()
		return
	saved_level.close()
	
	clear_map()
	for ground_tile_data in loaded_data.ground_tiles_data:
		place_ground_tile(ground_tile_data.x, ground_tile_data.y)
	for spike_data in loaded_data.spikes_data:
		place_spike(spike_data.x, spike_data.y)
	
	save_level_name_input.text = save_file_name

func save_file_name_to_path(save_file_name: String):
	return SAVE_FILES_DIRECTORY + save_file_name + ".level"

func to_int(val: float):
	return int(round(val))

func get_list_of_save_files() -> Array:
	var save_files = []
	var dir = Directory.new()
	if dir.open(SAVE_FILES_DIRECTORY) == OK:
		dir.list_dir_begin()
		var save_file_name = dir.get_next()
		while save_file_name != "":
			if !dir.current_is_dir():
				save_files.append(SAVE_FILES_DIRECTORY + save_file_name)
			save_file_name = dir.get_next()
	
	save_files.sort_custom(self, "compare_dates_modified")
	return save_files

func get_list_of_save_file_names() -> Array:
	var save_file_names = []
	for save_file in get_list_of_save_files():
		save_file_names.append(get_file_name_from_save_file_path(save_file))
	return save_file_names

func compare_dates_modified(file_path_a: String, file_path_b: String):
	return File.new().get_modified_time(file_path_a) > File.new().get_modified_time(file_path_b)

func get_file_name_from_save_file_path(file_path: String):
	return file_path.get_file().trim_suffix("."+file_path.get_extension())