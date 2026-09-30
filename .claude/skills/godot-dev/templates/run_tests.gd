## Executor de testes unitarios (skill godot-dev). Rodar: python3 .claude/skills/godot-dev/scripts/gdtool.py test
## Descobre res://tests/unit/**/test_*.gd; cada arquivo estende TestCase; executa os metodos test_*.
extends SceneTree


func _init() -> void:
	var total := 0
	var failed := 0
	for path in _find_tests("res://tests/unit"):
		var script: GDScript = load(path)
		if script == null:
			print("FALHOU ao carregar ", path)
			failed += 1
			continue
		var case: TestCase = script.new()
		case.tree = self
		for m in script.get_script_method_list():
			var method: String = m["name"]
			if not method.begins_with("test_"):
				continue
			total += 1
			case.begin(method)
			if case.has_method("before_each"):
				case.call("before_each")
			case.call(method)
			if case.has_method("after_each"):
				case.call("after_each")
			if case.current_failed():
				failed += 1
				print("FALHOU %s::%s\n    %s" % [path.get_file(), method, "\n    ".join(case.messages())])
			else:
				print("ok     %s::%s" % [path.get_file(), method])
	print("\n%d testes, %d falharam" % [total, failed])
	quit(1 if failed > 0 else 0)


func _find_tests(dir_path: String) -> Array[String]:
	var found: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return found
	for sub in dir.get_directories():
		found.append_array(_find_tests(dir_path.path_join(sub)))
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd"):
			found.append(dir_path.path_join(f))
	found.sort()
	return found
