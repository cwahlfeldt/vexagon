extends Area3D

@export var coord: Vector3i
@export var walkable := true:
	set(value):
		walkable = value
		if is_node_ready() and has_node("MeshInstance3D"):
			$MeshInstance3D.visible = walkable

var highlighted := false
var base_material: Material
var highlight_material: StandardMaterial3D

func _ready():
	add_to_group("tiles")
	input_event.connect(_on_click)

	# Store base material
	base_material = $MeshInstance3D.material_override

	# Create highlight material
	highlight_material = StandardMaterial3D.new()
	highlight_material.albedo_color = Color.WHITE
	highlight_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

	# Set initial visibility based on walkable state
	$MeshInstance3D.visible = walkable

func _on_click(_cam, event, _pos, _normal, _idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Game.is_player_turn:
			Game.player.try_move_to(coord)
			print("Clicked on %s" % self)

func set_highlight(on: bool, color := Color.WHITE):
	highlighted = on
	if on:
		highlight_material.albedo_color = color
		$MeshInstance3D.material_override = highlight_material
	else:
		$MeshInstance3D.material_override = base_material
