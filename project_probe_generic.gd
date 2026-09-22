@tool
extends EditorScript

# ==========================================================
# GODOT 4 UNIVERSAL PROJECT PROBE (EditorScript)
# あらゆるGodot 4プロジェクトの完全ダンプ・解析プローブ
# [Ctrl + Shift + X] で実行 ➜ 自動でクリップボードに全コピー
# ==========================================================

const OUTPUT_FILE = "res://PROJECT_PROBE_DUMP.txt"

# スキャン対象の拡張子（必要に応じて "tres", "gdshader" 等も追加可能）
const TARGET_EXTENSIONS = ["gd", "json", "cfg", "tscn", "gdshader"]
# スキャンから除外するディレクトリ
const EXCLUDE_DIRS = [".godot", ".import"]

var _report: String = ""

func _run() -> void:
	print_rich("[color=cyan]==================================================[/color]")
	print_rich("[color=cyan]  [PROJECT PROBE] プロジェクト全景解析を開始します...[/color]")
	print_rich("[color=cyan]==================================================[/color]")
	
	_report = "========================================\n"
	_report += "# PROJECT PROBE ADVANCED REPORT (EditorScript)\n"
	_report += "# Generated: %s\n" % Time.get_datetime_string_from_system()
	_report += "# Godot Version: %s\n" % Engine.get_version_info().string
	_report += "# OS: %s\n" % OS.get_name()
	_report += "========================================\n\n"

	# 1. オートロード (Singletons)
	_report += "## 1. AUTOLOADS (SINGLETONS)\n"
	_report += _get_autoloads_info() + "\n\n"

	# 2. project.godot 設定
	_report += "## 2. PROJECT CONFIGURATION (project.godot)\n"
	_report += "```ini\n"
	_report += _read_file_text("res://project.godot") + "\n"
	_report += "```\n\n"

	# 3. エディタ上のアクティブシーン構造
	_report += "## 3. ACTIVE SCENE HIERARCHY (Editor Open Scene)\n"
	_report += "```text\n"
	var edited_root = get_editor_interface().get_edited_scene_root()
	if edited_root:
		_report += _scan_scene_tree(edited_root, 0)
	else:
		_report += "(No scene currently opened in editor)\n"
	_report += "```\n\n"

	# 4. 全ソースコード＆シーン構造
	_report += "## 4. LOCAL FILE SYSTEM & CODES\n"
	_report += _scan_local_files("res://") + "\n"

	# クリップボード＆ファイル保存
	_finish_and_copy_to_clipboard()

func _get_autoloads_info() -> String:
	var out = ""
	for prop in ProjectSettings.get_property_list():
		if prop.name.begins_with("autoload/"):
			var name = prop.name.get_slice("/", 1)
			var path = ProjectSettings.get_setting(prop.name)
			out += "- %s: %s\n" % [name, path]
	return out if out != "" else "No Autoloads registered.\n"

func _scan_scene_tree(node: Node, level: int) -> String:
	var indent = "  ".repeat(level)
	var script_name = node.get_script().get_path().get_file() if node.get_script() else "No Script"
	var unique = "[%]" if node.unique_name_in_owner else "   "
	var out = "%s%s- %s (%s) [Script: %s]\n" % [indent, unique, node.name, node.get_class(), script_name]
	
	if node is Line2D:
		out += "%s       [Line2D] Points: %d, Width: %.1f, Color: %s\n" % [indent, node.points.size(), node.width, str(node.default_color)]
	elif node is Label:
		out += "%s       [Label] Text: \"%s\"\n" % [indent, node.text.left(30).replace("\n", " ")]
	elif node is Control:
		out += "%s       [Control] Size: %s, Position: %s, Anchor: (%d,%d,%d,%d)\n" % [indent, str(node.size), str(node.position), node.anchor_left, node.anchor_top, node.anchor_right, node.anchor_bottom]

	for child in node.get_children():
		out += _scan_scene_tree(child, level + 1)
	return out

func _scan_local_files(path: String) -> String:
	var out = ""
	var dir = DirAccess.open(path)
	if not dir:
		return out
	
	dir.list_dir_begin()
	var item = dir.get_next()
	while item != "":
		if item.begins_with("."):
			item = dir.get_next()
			continue
			
		var full_path = path + item
		if dir.current_is_dir():
			if not item in EXCLUDE_DIRS:
				out += "\n[DIR] " + full_path + "/\n"
				out += _scan_local_files(full_path + "/")
		else:
			var ext = item.get_extension()
			if ext in TARGET_EXTENSIONS:
				out += "  [File] " + item
				if ext in TARGET_EXTENSIONS:
					if item != "project_probe.gd":
						var content = _read_file_text(full_path)
						# 大容量JSONはサイズのみ出力してコンテキスト圧迫を防止
						if ext == "json" and content.length() > 50000:
							out += " (%d bytes - Large JSON Snippet)\n" % content.length()
							out += "  |-- (Large JSON data omitted for token optimization) --\n"
						else:
							out += " (%d bytes)\n" % content.length()
							out += "  |-- CONTENT START: " + full_path + " --\n"
							out += content.strip_edges() + "\n"
							out += "  |-- CONTENT END --------------------\n"
					else:
						out += " (Skipped self code)\n"
				else:
					out += "\n"
		item = dir.get_next()
	return out

func _read_file_text(path: String) -> String:
	if not FileAccess.file_exists(path): return "(File not found: %s)" % path
	var f = FileAccess.open(path, FileAccess.READ)
	var text = f.get_as_text()
	f.close()
	return text

func _finish_and_copy_to_clipboard() -> void:
	_report += "========================================\n"
	_report += "# END OF PROBE REPORT\n"
	_report += "========================================\n"
	
	DisplayServer.clipboard_set(_report)
	var file = FileAccess.open(OUTPUT_FILE, FileAccess.WRITE)
	if file:
		file.store_string(_report)
		file.close()
	
	print_rich("[color=green]==================================================[/color]")
	print_rich("[color=green]  ★ プロジェクト全ソースコード完全スキャン完了！[/color]")
	print_rich("[color=yellow]  [OK] クリップボードに全コピー完了！ (そのまま AI へ Ctrl+V できます)[/color]")
	print_rich("[color=green]==================================================[/color]")
