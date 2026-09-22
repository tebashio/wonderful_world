@tool
extends EditorScript

# 生成するフォルダ一覧
const FOLDERS: Array[String] = [
	"res://assets/models/environments",
	"res://assets/models/characters",
	"res://assets/models/props",
	"res://assets/textures/palettes",
	"res://assets/textures/ui",
	"res://assets/audio/bgm",
	"res://assets/audio/sfx",
	"res://assets/fonts",
	"res://shaders",
	"res://materials/environments",
	"res://materials/characters",
	"res://scenes/environments",
	"res://scenes/characters",
	"res://scenes/smart_objects",
	"res://scenes/ui",
	"res://scripts/autoload",
	"res://scripts/npc",
	"res://scripts/smart_objects",
	"res://scripts/utils"
]

func _run() -> void:
	print("========================================")
	print("  Starting Project Folder Generation... ")
	print("========================================")
	
	for folder in FOLDERS:
		if not DirAccess.dir_exists_absolute(folder):
			var error := DirAccess.make_dir_recursive_absolute(folder)
			if error == OK:
				print("[CREATED] ", folder)
			else:
				printerr("[FAILED]  ", folder, " (Error: ", error, ")")
		else:
			print("[EXISTS]  ", folder)
			
	# GodotのFileSystem Dockを即座に再スキャンして画面に反映
	EditorInterface.get_resource_filesystem().scan()
	
	print("========================================")
	print("  Folder Structure Initialized Cleanly! ")
	print("========================================")
