extends ConfirmationDialog


const _ASSET_URL_PREFIX = "https://godotengine.org/asset-library/api/asset/"
const _ASSET_LISTING_SCENE = preload("res://src/components/assetlib_projects/asset_listing.tscn")
const _DESCRIPTION_FORMAT_STRING = """Version: {0}
Content: [url={1}]View Files[/url]
Description:

{2}"""

var _id: int
var _asset_listing: AssetListing

@onready var _description_label: RichTextLabel = %DescriptionLabel


func _ready():
	var listing_parent = $HBoxContainer/VBoxContainer
	listing_parent.add_child(_asset_listing)
	listing_parent.move_child(_asset_listing, 0)


@warning_ignore("shadowed_variable_base_class")
func init(id: int, title: String, category: String, author: String,
		license: String):
	_id = id
	self.title = title
	_asset_listing = _ASSET_LISTING_SCENE.instantiate().init_asset_listing(
			title, category, author, license
	)
	return self


## Returns the asset's url in the asset library.
func _get_assetlib_url() -> String:
	return _ASSET_URL_PREFIX.path_join(str(_id))


func _on_about_to_popup():
	_description_label.text = _DESCRIPTION_FORMAT_STRING.format(
			["1.0.1", "https://example.com", "An example plugin."]
	)


func _on_rich_text_label_meta_clicked(meta):
	OS.shell_open(str(meta))
