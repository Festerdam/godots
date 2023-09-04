extends ConfirmationDialog
## Dialogue describing an asset, with all information pertaining to it
## and the option to download it.


const _ASSET_URL_PREFIX = "https://godotengine.org/asset-library/api/asset/"
const _ASSET_LISTING_SCENE = preload("res://src/components/assetlib_projects/asset_listing.tscn")

var _description_format_string = tr("""Version: {version_string}
Content: [url={browse_url}]View Files[/url]
Description:

{description}""")
var _id: int
var _asset_listing: AssetListing
var _download_url: String

@onready var _description_label: RichTextLabel = %DescriptionLabel
@onready var _asset_info_downloader: HTTPRequest = $AssetInfoDownloader


func _ready():
	get_ok_button().disabled = true
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
	_asset_info_downloader.request(_get_assetlib_url())


func _on_asset_info_downloader_request_completed(result: int,
		response_code: int, _headers: PackedStringArray,
		byte_body: PackedByteArray):
	var error_message = tr("Error!")
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_description_label.text = error_message
		return
	
	# TODO could it contain unicode?
	var body = byte_body.get_string_from_ascii()
	var json = JSON.new()
	if json.parse(body) != OK or not json.data is Dictionary:
		_description_label.text = error_message
		return
	
	_download_url = json.data.download_url
	_description_label.text = _description_format_string.format(json.data)
	get_ok_button().disabled = false


func _on_rich_text_label_meta_clicked(meta):
	OS.shell_open(str(meta))
