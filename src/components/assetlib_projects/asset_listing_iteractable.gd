extends AssetListing
## Interactible AssetListing.
##
## Exists as a separate file, because, although it would run at first,
## Godot's resource loader on startup would think that there is a
## problematic dependency cycle.  This is due to the fact that both
## AssetListItem and AssetDialogue would be referencing each other.


const _ASSET_DIALOG_SCENE = preload("res://src/components/assetlib_projects/asset_dialog.tscn")

var _id: int
var _asset_dialog: ConfirmationDialog


func _ready():
	super._ready()
	
	_asset_dialog = _ASSET_DIALOG_SCENE.instantiate().init(
			_id, _title, _category, _author, _license
	)
	add_child(_asset_dialog)


func init_asset_listing_interactible(id: int, title: String,
		category: String, author: String, license: String):
	init_asset_listing(title, category, author, license)
	_id = id
	return self


func _open_popup():
	_asset_dialog.popup_centered()
