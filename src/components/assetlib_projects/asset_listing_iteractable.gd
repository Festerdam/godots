extends AssetListing


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


func _on_title_pressed():
	_asset_dialog.popup_centered()
