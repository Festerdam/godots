extends VBoxContainer

func _ready():
	$ScrollContainer.add_theme_stylebox_override("panel",
			get_theme_stylebox("search_panel", "ProjectManager"))
