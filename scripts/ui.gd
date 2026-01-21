extends CanvasLayer

@onready var health_label = $HealthLabel
@onready var dash_btn = $DashButton
@onready var block_btn = $BlockButton
@onready var rewind_btn = $RewindButton
@onready var level_label = $LevelLabel
@onready var game_over_panel = $GameOverPanel
@onready var game_over_label = $GameOverPanel/GameOverLabel
@onready var next_level_btn = $GameOverPanel/NextLevelButton
@onready var restart_btn = $GameOverPanel/RestartButton
@onready var rewind_from_defeat_btn = $GameOverPanel/RewindButton

func _ready():
	Game.turn_started.connect(_on_turn)
	Game.game_won.connect(_on_victory)
	Game.game_lost.connect(_on_defeat)

	dash_btn.pressed.connect(func():
		if Game.player:
			Game.player.toggle_dash()
	)
	block_btn.pressed.connect(func():
		if Game.player:
			Game.player.toggle_block()
	)
	rewind_btn.pressed.connect(func(): Game.rewind())

	# Game over panel buttons
	if next_level_btn:
		next_level_btn.pressed.connect(_on_next_level)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart)
	if rewind_from_defeat_btn:
		rewind_from_defeat_btn.pressed.connect(_on_rewind_from_defeat)

	# Hide game over panel initially
	if game_over_panel:
		game_over_panel.visible = false

	# Update level label
	_update_level_label()

func _process(_delta):
	var p = Game.player
	if not p:
		return

	health_label.text = "HP: %d/%d" % [p.hp, p.max_hp]

	# Dash button
	dash_btn.text = "DASH" if p.dash_cooldown == 0 else "DASH (%d)" % p.dash_cooldown
	dash_btn.disabled = p.dash_cooldown > 0 or Game.game_over

	# Block button
	var block_text = "BLOCK"
	if p.block_active:
		block_text = "BLOCK (ON)"
	elif p.block_cooldown > 0:
		block_text = "BLOCK (%d)" % p.block_cooldown
	block_btn.text = block_text
	block_btn.disabled = Game.game_over

	# Rewind button
	var can_rewind = Game.can_rewind()
	rewind_btn.text = "REWIND (R)"
	rewind_btn.disabled = not can_rewind or Game.game_over

func _on_turn(_unit):
	pass  # Update UI state if needed

func _on_victory():
	if game_over_panel:
		game_over_label.text = "VICTORY!"
		game_over_panel.visible = true
		if rewind_from_defeat_btn:
			rewind_from_defeat_btn.visible = false
		# Show next level button if more levels exist
		if next_level_btn:
			var lm = get_node_or_null("/root/LevelManager")
			if lm:
				var has_more = lm.current_level_index < lm.get_level_count() - 1
				next_level_btn.visible = has_more
			else:
				next_level_btn.visible = false

func _on_defeat():
	if game_over_panel:
		game_over_label.text = "DEFEATED"
		game_over_panel.visible = true
		if rewind_from_defeat_btn:
			rewind_from_defeat_btn.visible = Game.can_rewind()
		if next_level_btn:
			next_level_btn.visible = false

func _on_restart():
	get_tree().reload_current_scene()

func _on_next_level():
	if game_over_panel:
		game_over_panel.visible = false
	var main = get_tree().current_scene
	if main.has_method("advance_to_next_level"):
		main.advance_to_next_level()
	_update_level_label()

func _on_rewind_from_defeat():
	if game_over_panel:
		game_over_panel.visible = false
	Game.rewind()

func _update_level_label():
	if not level_label:
		return
	var lm = get_node_or_null("/root/LevelManager")
	if lm:
		var config = lm.get_current_level()
		if config:
			var level_num = lm.current_level_index + 1
			level_label.text = "Level %d: %s" % [level_num, config.level_name]
		else:
			level_label.text = "Level 1"
	else:
		level_label.text = "Level 1"
