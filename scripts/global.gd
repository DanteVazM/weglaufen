extends Node
## Autoload "GameState": datos que sobreviven a los cambios de escena.
## Guarda el nombre del jugador (save.cfg) y la lista de puntajes (puntajes.json).

const CONFIG_PATH := "user://save.cfg"
const SCORES_PATH := "user://puntajes.json"
const MAX_SCORES := 200

var player_name: String = ""
var final_score: int = 0
var score_saved: bool = false   # ¿ya se guardó el puntaje de esta partida?
var last_id: int = -1           # id de la última entrada agregada (para resaltarla)
var best_score: int = 0
var best_name: String = ""
var scores: Array = []          # [{id, nombre, puntaje, fecha}], de mayor a menor

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) == OK:
		player_name = str(cfg.get_value("player", "name", ""))
	_load_scores()

# Llamar al empezar cada partida (lo hace el mundo en su _ready)
func new_run() -> void:
	final_score = 0
	score_saved = false

# Guarda el nombre del jugador
func save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", player_name)
	cfg.save(CONFIG_PATH)

# ---------- Puntajes ----------

func add_score(nombre: String, puntaje: int) -> void:
	var entry := {
		"id": int(Time.get_unix_time_from_system() * 1000.0),
		"nombre": nombre,
		"puntaje": puntaje,
		"fecha": Time.get_datetime_string_from_system(false, true),
	}
	scores.append(entry)
	last_id = entry["id"]
	_sort_scores()
	if scores.size() > MAX_SCORES:
		scores.resize(MAX_SCORES)
	_refresh_best()
	save_scores()
	score_saved = true

func clear_scores() -> void:
	scores.clear()
	last_id = -1
	_refresh_best()
	save_scores()

func save_scores() -> void:
	var f := FileAccess.open(SCORES_PATH, FileAccess.WRITE)
	if f == null:
		push_error("No pude guardar los puntajes (error %d)" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify(scores, "\t"))
	f.close()

func _load_scores() -> void:
	scores = []
	if FileAccess.file_exists(SCORES_PATH):
		var f := FileAccess.open(SCORES_PATH, FileAccess.READ)
		if f != null:
			var data = JSON.parse_string(f.get_as_text())
			if data is Array:
				for e in data:
					if e is Dictionary and e.has("nombre") and e.has("puntaje"):
						scores.append({
							"id": int(e.get("id", 0)),
							"nombre": str(e["nombre"]),
							"puntaje": int(e["puntaje"]),
							"fecha": str(e.get("fecha", "")),
						})
	_sort_scores()
	_refresh_best()

func _sort_scores() -> void:
	scores.sort_custom(_by_score)

func _by_score(a: Dictionary, b: Dictionary) -> bool:
	if a["puntaje"] == b["puntaje"]:
		return a["id"] < b["id"]
	return a["puntaje"] > b["puntaje"]

func _refresh_best() -> void:
	if scores.is_empty():
		best_score = 0
		best_name = ""
	else:
		best_score = int(scores[0]["puntaje"])
		best_name = str(scores[0]["nombre"])
