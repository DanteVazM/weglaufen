extends Control
## Lista de puntajes de todos los jugadores (leída de GameState / puntajes.json).
## Los nodos fijos están en puntajes.tscn; las filas se crean por código.

@export_file("*.tscn") var back_scene: String = ""   # a dónde vuelve el botón "Volver"
@export var font_size: int = 26
@export var max_rows: int = 100

@onready var lista: VBoxContainer = %ListaVBox
@onready var vacio_label: Label = %VacioLabel
@onready var btn_volver: Button = %BotonVolver
@onready var btn_borrar: Button = %BotonBorrar

var _confirm_clear := false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	btn_volver.pressed.connect(_on_back)
	btn_borrar.pressed.connect(_on_clear)
	btn_volver.grab_focus()
	_fill()

func _fill() -> void:
	for c in lista.get_children():
		lista.remove_child(c)
		c.queue_free()

	var scores: Array = GameState.scores
	vacio_label.visible = scores.is_empty()
	if scores.is_empty():
		return

	lista.add_child(_make_row("#", "Nombre", "Puntaje", "Fecha", Color(0.7, 0.7, 0.7)))
	for i in mini(scores.size(), max_rows):
		var e: Dictionary = scores[i]
		var color := Color.WHITE
		if int(e["id"]) == GameState.last_id:
			color = Color.GOLD   # tu última partida, resaltada
		lista.add_child(_make_row(str(i + 1), str(e["nombre"]), str(e["puntaje"]), str(e["fecha"]), color))

func _make_row(rank: String, nombre: String, puntaje: String, fecha: String, color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	row.add_child(_cell(rank, 70, false, color))
	row.add_child(_cell(nombre, 0, true, color))
	row.add_child(_cell(puntaje, 130, false, color, HORIZONTAL_ALIGNMENT_RIGHT))
	row.add_child(_cell(fecha, 260, false, color, HORIZONTAL_ALIGNMENT_RIGHT))
	return row

func _cell(text: String, min_w: float, expand: bool, color: Color, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(min_w, 0)
	l.horizontal_alignment = align
	l.clip_text = true
	l.add_theme_color_override("font_color", color)
	l.add_theme_font_size_override("font_size", font_size)
	if expand:
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l

func _on_back() -> void:
	if back_scene == "":
		push_error("Asigná 'Back Scene' en el Inspector del nodo raíz.")
		return
	get_tree().change_scene_to_file(back_scene)

# Dos toques para borrar, así no se borra por accidente
func _on_clear() -> void:
	if not _confirm_clear:
		_confirm_clear = true
		btn_borrar.text = "¿Seguro? Tocá de nuevo"
		return
	GameState.clear_scores()
	_confirm_clear = false
	btn_borrar.text = "Borrar puntajes"
	_fill()
