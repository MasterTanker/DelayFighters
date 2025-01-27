extends Control


func _ready():
	get_tree().call_group("spikes", "queue_free")
	get_tree().call_group("moving_platforms", "queue_free")
	get_tree().call_group("instanced", "queue_free")
	SettingsManager.initialize()
	switch_to_main()
	
	$Settings/AccountName.text = SettingsManager.account_name
	$Settings/ChannelName.text = SettingsManager.channel_name
	$Settings/OauthToken.text = SettingsManager.oauth_token
	$Settings/MaxPlayers.text = str(SettingsManager.max_players)
	$Settings/RejoinTimer.text = str(SettingsManager.rejoin_timer)
	
	for i in range(SettingsManager.premade_levels.size()):
		var new_button = Button.new()
		new_button.text = str(i + 1)
		new_button.connect("button_up", SettingsManager, "load_premade_level", [i])
		$PremadeLevels/GridContainer.add_child(new_button)
	
	$Main/VBoxContainer/PlayPremadeLevels.connect("button_up", self, "switch_to_premade_levels")
	$Main/VBoxContainer/LevelEditor.connect("button_up", self, "open_level_editor")
	$Main/VBoxContainer/Settings.connect("button_up", self, "switch_to_settings")
	$Main/VBoxContainer/Credits.connect("button_up", self, "switch_to_credits")
	$Main/VBoxContainer/Exit.connect("button_up", self, "exit")
	
	$Settings/Save.connect("button_up", self, "save_settings")
	$PremadeLevels/Back.connect("button_up", self, "switch_to_main")
	$Credits/Back.connect("button_up", self, "switch_to_main")

func hide_all():
	for child in get_children():
		if child.name == "Misc":
			continue
		child.hide()

func open_level_editor():
	get_tree().change_scene("res://level_editor/LevelEditor.tscn")

func switch_to_main():
	hide_all()
	$Main.show()

func switch_to_settings():
	hide_all()
	$Settings.show()

func switch_to_premade_levels():
	hide_all()
	$PremadeLevels.show()

func switch_to_credits():
	hide_all()
	$Credits.show()

func save_settings():
	SettingsManager.account_name = $Settings/AccountName.text
	SettingsManager.channel_name = $Settings/ChannelName.text
	SettingsManager.oauth_token = $Settings/OauthToken.text
	var max_players_s = $Settings/MaxPlayers.text
	if max_players_s.is_valid_integer():
		SettingsManager.max_players = int(max_players_s)
	var rejoin_timer_s = $Settings/RejoinTimer.text
	if rejoin_timer_s.is_valid_integer():
		SettingsManager.rejoin_timer = int(rejoin_timer_s)
	SettingsManager.save_settings()
	switch_to_main()

func exit():
	get_tree().quit()

func load_oauth_token_page_in_browser():
	OS.shell_open("https://twitchapps.com/tmi/")

func open_twitch():
	OS.shell_open("https://www.twitch.tv/miziziziz")
func open_twitter():
	OS.shell_open("https://twitter.com/miziziziz")
func open_youtube():
	OS.shell_open("https://www.youtube.com/user/miziziziz")
