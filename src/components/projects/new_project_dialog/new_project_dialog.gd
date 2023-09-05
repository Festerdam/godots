extends "res://src/components/projects/install_project_dialog/install_project_dialog.gd"

signal created(path)


func _ready():
	super._ready()
	
	min_size = Vector2(640, 215) * Config.EDSCALE
	
	if not handle_creation:
		return
	confirmed.connect(func():
		var dir = _project_path_line_edit.text.strip_edges()
		var project_file_path = dir.path_join("project.godot")

		var initial_settings = ConfigFile.new()
		initial_settings.set_value("application", "config/name", _project_name_edit.text.strip_edges())
		initial_settings.set_value("application", "config/icon", "res://icon.png")
		var err = initial_settings.save(project_file_path)
		if err:
			_error("%s %s: %s." % [
				tr("Couldn't create project.godot in project path."), tr("Code"), err
			])
			return
		else:
			var img: Texture2D = preload("res://assets/default_project_icon.svg")
			img.get_image().save_png(dir.path_join("icon.png"))
			created.emit(project_file_path)
	)


func raise():
	_project_name_edit.text = "New Game Project"
	_project_path_line_edit.text = Config.DEFAULT_PROJECTS_PATH.ret()
	popup_centered()
	
	_validate()


func _validate():
	var path = _project_path_line_edit.text.strip_edges()
	var dir = DirAccess.open(path)
	
	if not dir:
		_error(tr("The path specified doesn't exist."))
		return
	
	if path.simplify_path() in [OS.get_environment("HOME"), OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS), OS.get_executable_path().get_base_dir()].filter(func(x): return x.simplify_path()):
		_error(tr(
			"You cannot save a project in the selected path. Please make a new folder or choose a new path."
		))
		return

	# Check if the specified folder is empty, even though this is not an error, it is good to check here.
	var dir_is_empty = true
	dir.list_dir_begin()
	var n = dir.get_next()
	while not n.is_empty():
		if not n.begins_with("."):
			# Allow `.`, `..` (reserved current/parent folder names)
			# and hidden files/folders to be present.
			# For instance, this lets users initialize a Git repository
			# and still be able to create a project in the directory afterwards.
			dir_is_empty = false
			break;
		n = dir.get_next()
	dir.list_dir_end()

	if not dir_is_empty:
		_warning(tr(
			"The selected path is not empty. Choosing an empty folder is highly recommended."
		))
		return
	
	_success("")


func _error(text):
	_set_message(text, "error")
	get_ok_button().disabled = true


func _warning(text):
	_set_message(text, "warning")
	get_ok_button().disabled = false


func _success(text):
	_set_message(text, "success")
	get_ok_button().disabled = false


func _set_message(text, type):
	var new_icon = null
	if type == "error":
		_message_label.add_theme_color_override("font_color", get_theme_color("error_color", "Editor"))
		_message_label.modulate = Color(1, 1, 1, 1)
		new_icon = get_theme_icon("StatusError", "EditorIcons")
	elif type == "success":
		_message_label.remove_theme_color_override("font_color")
		_message_label.modulate = Color(1, 1, 1, 0)
		new_icon = get_theme_icon("StatusSuccess", "EditorIcons")
	elif type == "warning":
		_message_label.add_theme_color_override("font_color", get_theme_color("warning_color", "Editor"))
		_message_label.modulate = Color(1, 1, 1, 1)
		new_icon = get_theme_icon("StatusWarning", "EditorIcons")
	_message_label.text = text
	_status_rect.texture = new_icon
	
	var window_size = size
	var contents_min_size = get_contents_minimum_size()
	if window_size.x < contents_min_size.x or window_size.y < contents_min_size.y:
		size = Vector2(
			max(window_size.x, contents_min_size.x), 
			max(window_size.y, contents_min_size.y)
		)
