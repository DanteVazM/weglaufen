extends Node

const SAVEFILE = "res://saved_data"

var highest_record = 0

func save_score():
	var file = FileAccess.open(SAVEFILE, FileAccess.WRITE_READ)
	file.store_32(highest_record)
	file=null

func load_score():
	var file = FileAccess.open(SAVEFILE, FileAccess.READ)
	if FileAccess.file_exists(SAVEFILE):
		highest_record = file.get_32()	
