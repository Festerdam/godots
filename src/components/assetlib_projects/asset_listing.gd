extends HBoxContainer


const _ASSET_URL_PREFIX = "https://godotengine.org/asset-library/api/asset/"

var _id: int
var _title: String
var _category: String
var _author: String
var _license: String

@onready var _title_node: Label = %Title
@onready var _category_node: Label = %Category
@onready var _author_node: Label = %Author
@onready var _license_node: Label = %License


func _ready():
	_title_node.text = _title
	_category_node.text = _category
	_author_node.text = _author
	_license_node.text = _license


func init(id: int, title: String, category: String, author: String,
		license: String):
	_id = id
	_title = title
	_category = category
	_author = author
	_license = license
	return self


## Returns the asset's url in the asset library.
func get_assetlib_url() -> String:
	return _ASSET_URL_PREFIX.path_join(str(_id))
