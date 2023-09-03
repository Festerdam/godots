class_name AssetListing
extends HBoxContainer


const _ASSET_DIALOG_SCENE = preload("res://src/components/assetlib_projects/asset_dialog.tscn")

var _id: int
var _title: String
var _category: String
var _author: String
var _license: String
var _interactible: bool = true
var _asset_dialog: ConfirmationDialog

@onready var _title_node: LinkButton = %Title
@onready var _category_node: Label = %Category
@onready var _author_node: Label = %Author
@onready var _license_node: Label = %License


func _ready():
	_title_node.text = _title
	_category_node.text = _category
	_author_node.text = _author
	_license_node.text = _license
	
	if _interactible:
		_asset_dialog = _ASSET_DIALOG_SCENE.instantiate().init(
				_id, _title, _category, _author, _license
		)
		add_child(_asset_dialog)


func init(id: int, title: String, category: String, author: String,
		license: String, interactible: bool = true):
	_id = id
	_title = title
	_category = category
	_author = author
	_license = license
	_interactible = interactible
	return self


func _on_title_pressed():
	if _interactible:
		_asset_dialog.popup_centered()
