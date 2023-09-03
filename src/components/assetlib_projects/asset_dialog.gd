extends ConfirmationDialog


const _ASSET_LISTING_SCENE = preload("res://src/components/assetlib_projects/asset_listing.tscn")

var _id: int
var _asset_listing: AssetListing


func _ready():
	var listing_parent = $HBoxContainer/VBoxContainer
	listing_parent.add_child(_asset_listing)
	listing_parent.move_child(_asset_listing, 0)


@warning_ignore("shadowed_variable_base_class")
func init(id: int, title: String, category: String, author: String,
		license: String):
	_id = id
	self.title = title
	_asset_listing = _ASSET_LISTING_SCENE.instantiate().init(
			id, title, category, author, license, false
	)
	return self


func _on_about_to_popup():
	pass
