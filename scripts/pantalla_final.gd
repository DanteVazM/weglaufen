extends Control
## Pantalla de Game Over. Los nodos (labels, campo de nombre y botones)
## están en la escena pantalla_final.tscn; este script solo los conecta.

@export_file("*.tscn") var game_scene: String = ""     # escena del juego ("Jugar de nuevo")
@export_file("*.tscn") var scores_scene: String = ""   # escena de puntajes ("Ver puntajes")
@export_file("*.tscn") var menu_scene: String = ""     # opcional: escena del menú principal

const SHOT_PATH := "res://screenshots/muerte.png"

@onready var captura: TextureRect = %Captura
@onready var puntaje_label: Label = %PuntajeLabel
@onready var record_label: Label = %RecordLabel
@onready var name_input: LineEdit = %NombreInput
@onready var btn_jugar: Button = %BotonJugar
@onready var btn_puntajes: Button = %BotonPuntajes
@onready var btn_menu: Button = %BotonMenu
@onready var btn_salir: Button = %BotonSalir

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	# Captura del choque como fondo, si existe
	if FileAccess.file_exists(SHOT_PATH):
		var img := Image.load_from_file(SHOT_PATH)
		if img != null:
			captura.texture = ImageTexture.create_from_image(img)

	# Puntaje y récord
	puntaje_label.text = "Puntaje: %d" % global.final_score
	if not global.score_saved and global.final_score > global.best_score:
		record_label.text = "¡Nuevo récord!"
	elif global.best_score > 0:
		record_label.text = "Récord: %s — %d" % [global.best_name, global.best_score]
	else:
		record_label.text = ""

	# Nombre y botones
	name_input.text = global.player_name
	name_input.editable = not global.score_saved   # si ya se guardó, no se cambia
	name_input.text_submitted.connect(_on_play)       # Enter = jugar de nuevo
	btn_jugar.pressed.connect(_on_play)
	btn_puntajes.pressed.connect(_on_scores)
	btn_menu.pressed.connect(_on_menu)
	btn_salir.pressed.connect(_on_quit)
	btn_puntajes.visible = scores_scene != ""
	btn_menu.visible = menu_scene != ""
	name_input.grab_focus()

# Guarda el nombre y agrega el puntaje a la lista (una sola vez por partida)
func _commit() -> void:
	var n := name_input.text.strip_edges()
	if n.is_empty():
		n = "Jugador"
	global.player_name = n
	global.save()
	if not global.score_saved:
		global.add_score(n, global.final_score)

func _on_play(_text: String = "") -> void:
	if game_scene == "":
		push_error("Asigná 'Game Scene' en el Inspector del nodo raíz.")
		return
	_commit()
	get_tree().change_scene_to_file(game_scene)

func _on_scores() -> void:
	_commit()
	get_tree().change_scene_to_file(scores_scene)

func _on_menu() -> void:
	_commit()
	get_tree().change_scene_to_file(menu_scene)

func _on_quit() -> void:
	_commit()
	get_tree().quit()
