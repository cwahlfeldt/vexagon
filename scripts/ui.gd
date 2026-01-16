extends CanvasLayer

@onready var health_label = $HealthLabel
@onready var dash_btn = $DashButton
@onready var block_btn = $BlockButton
@onready var rewind_btn = $RewindButton

func _ready():
	Game.turn_started.connect(_on_turn)
	dash_btn.pressed.connect(func():
		if Game.player:
			Game.player.toggle_dash()
	)
	block_btn.pressed.connect(func():
		if Game.player:
			Game.player.toggle_block()
	)
	rewind_btn.pressed.connect(func(): Game.rewind())

func _process(_delta):
	var p = Game.player
	if not p:
		return

	health_label.text = "HP: %d/%d" % [p.hp, p.max_hp]

	dash_btn.text = "DASH" if p.dash_cooldown == 0 else "DASH (%d)" % p.dash_cooldown
	dash_btn.disabled = p.dash_cooldown > 0

	var block_text = "BLOCK"
	if p.block_active:
		block_text = "BLOCK (ON)"
	elif p.block_cooldown > 0:
		block_text = "BLOCK (%d)" % p.block_cooldown
	block_btn.text = block_text

func _on_turn(unit):
	pass  # Update UI state if needed
