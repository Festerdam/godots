extends VBoxContainer
## Menu responsible for searching and installing asset library project
## (ie. projects available in the asset library).


@export var asset_download_scene: PackedScene

## The projects menu, to update the project list, when needed.
var projects: Control

const _ASSET_QUERY_PREFIX = "https://godotengine.org/asset-library/api/asset?"
const _ASSETS_PER_PAGE = 40
const _MAX_PAGE_BUTTONS = 10
const _TUXFAMILY_VERSION_LISTING = "https://downloads.tuxfamily.org/godotengine/"
const _EXML = preload("res://src/extensions/xml.gd")
const _ASSET_LISTING = preload("res://src/components/assetlib_projects/asset_listing_iteractable.tscn")

var _downloads_container
var _current_page: int = 0:
	get:
		return _internal_current_page
	set(value):
		_internal_current_page = value
		_fetch_assets(null, false)
var _internal_current_page: int = 0:
	set(value):
		_internal_current_page = value
		_pb[0].current_page = value
		_pb[1].current_page = value
var _current_assets: Dictionary: set = _display_assets
var _last_text_edit: int = 0
var _fetched_versions: bool = false:
	set(value):
		_fetched_versions = value
		if not value:
			_search_field.editable = false
			_version_option.disabled = true
			_sort_option.disabled = true
			_category_option.disabled = true
			_site_option.disabled = true
		else:
			_search_field.editable = true
			_version_option.disabled = false
			_sort_option.disabled = false
			_category_option.disabled = false
			_site_option.disabled = false

@onready var _search_field: LineEdit = %SearchField
@onready var _version_option: OptionButton = %VersionOption
@onready var _sort_option: OptionButton = %SortOption
@onready var _category_option: OptionButton = %CategoryOption
@onready var _site_option: OptionButton = %SiteOption
@onready var _support_options: MenuButton = %SupportOptions
@onready var _asset_querier: HTTPRequest = $AssetQuerier
@onready var _scroll_container: ScrollContainer = %ScrollContainer
@onready var _asset_list: HFlowContainer = %AssetList
# TODO rename
# First element is top navigation buttons, second is bottom navigation
# buttons.
@onready var _pb: Array[HBoxContainer] = [
	%NavigationButtons,
	%NavigationButtons2,
]
#@onready var _navigation_buttons: HBoxContainer = %NavigationButtons
@onready var _status_label: Label = %StatusLabel
@onready var _refresh_button: Button = %RefreshButton
@onready var _overlay_contents: CenterContainer = %OverlayContents


func init(downloads_container):
	_downloads_container = downloads_container


func _ready():
	$MarginContainer/ScrollContainer.add_theme_stylebox_override("panel",
			get_theme_stylebox("search_panel", "ProjectManager"))
	
	_fetched_versions = false
	
	_support_options.get_popup().id_pressed.connect(_fetch_assets)
	
	var on_page_selected = func(page_num):
			_current_page = page_num
			_pb[0].current_page = page_num
			_pb[1].current_page = page_num
	
	_pb[0].page_selected.connect(on_page_selected)
	_pb[1].page_selected.connect(on_page_selected)
	
	await _setup_version_button()
	
	_fetch_assets()


func _setup_version_button():
	var versions = await _fetch_versions()
	versions.reverse()
	if versions == []:
		_version_option.disabled = true
		return
	
	for version in versions:
		_version_option.add_item(version)


func _on_search_field_text_changed(_new_text: String):
	_last_text_edit = Time.get_ticks_msec()
	await get_tree().create_timer(1).timeout
	if Time.get_ticks_msec() - _last_text_edit >= 1000:
		_fetch_assets()


func _fetch_assets(_trash = null, reset_page_number: bool = true):
	if not _fetched_versions:
		return
	if reset_page_number:
		_internal_current_page = 0
	var query = _generate_query(_generate_query_dictionary())
	_asset_querier.cancel_request()
	_asset_querier.request(query)
	_message(false, tr("Fetching assets…"))


func _on_asset_querier_request_completed(result: int, response_code: int,
		_headers: PackedStringArray, byte_body: PackedByteArray):
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		_message(true, tr("Fetching assets failed."))
		_current_assets = {}
		return
	
	var body = byte_body.get_string_from_ascii()
	var json = JSON.new()
	if json.parse(body) != OK or not json.data is Dictionary:
		_message(true, tr("Received unexpected data."))
		_current_assets = {}
		return
	_current_assets = json.data
	_clear_message()


func _display_assets(current_assets: Dictionary):
	_current_assets = current_assets
	_clear_asset_display()
	if current_assets == {} or current_assets.total_items == 0:
		return
	
	_pb[0].max_pages = current_assets.pages
	_pb[1].max_pages = current_assets.pages
	_pb[0].display_navigation()
	_pb[1].display_navigation()
	
	var assets = current_assets.result
	for asset_data in assets:
		var asset = _ASSET_LISTING.instantiate().init_asset_listing_interactible(
				int(asset_data.asset_id),
				asset_data.title,
				asset_data.category,
				asset_data.author,
				asset_data.cost,
				projects,
				asset_download_scene,
				_downloads_container
		)
		
		_asset_list.add_child(asset)


## Clears all assets being displayed.
func _clear_asset_display():
	_pb[0].hide()
	_pb[1].hide()
	for child in _asset_list.get_children():
		child.queue_free()


## Fetches all versions (strings in the MAJOR.MINOR.PATCH format) listed
## on TuxFamily.  Returns [code][][/code] on failure.
func _fetch_versions() -> Array[String]:
	var request = HTTPRequest.new()
	request.timeout = 8
	add_child(request)
	request.request(_TUXFAMILY_VERSION_LISTING)
	_message(false, tr("Fetching version info…"))
	var resp = await request.request_completed
	request.queue_free()
	if resp[0] != HTTPRequest.RESULT_SUCCESS or resp[1] != 200:
		_message(true, tr("Version info fetching failed."))
		return []
	
	var body = resp[3].get_string_from_ascii()
	var regex = RegEx.new()
	regex.compile("(?<=td class=\\\"n\\\"><a href=\\\")\\d\\.\\d(\\.\\d)?")
	var result: Array[String] = []
	result.assign(
			regex.search_all(body).map(func (x): return x.get_string())
	)
	_fetched_versions = true
	return result


## Generates a query to the asset library, using the keys and values of
## a given dictionary.[br]
##
## Example [param pairs]:[br]
## [code]{"filter": "cheese", page: 2}[/code][br]
## Example output, based on the given example [param pairs]:[br]
## "https://godotengine.org/asset-library/api/asset?filter=cheese&page=2"
func _generate_query(pairs: Dictionary) -> String:
	var result_url = _ASSET_QUERY_PREFIX
	for key in pairs:
		if not pairs[key]:
			continue
		if pairs[key] is String or pairs[key] is int:
			result_url += key + "=" + str(pairs[key]).uri_encode() + "&"
		elif pairs[key] is bool:
			result_url += key + "&"
		elif pairs[key] is Array:
			result_url += key + "="
			var list = ""
			for element in pairs[key]:
				list += str(element).uri_encode() + "+"
			result_url += list.trim_suffix("+") + "&"
	
	return result_url.trim_suffix("&")


## Generates a dictonary for the query to be generated by using the
## options chosen by the user through the UI.  It uses the keys listed
## here: [url]https://github.com/godotengine/godot-asset-library/blob/master/API.md#assets-api[/url]
func _generate_query_dictionary() -> Dictionary:
	var result = {}
	result.type = "project"
	
	if not _category_option.get_selected_id() == 0:
		result.category = _category_option.get_selected_id()
	
	result.support = []
	var popup = _support_options.get_popup()
	if popup.is_item_checked(0):
		result.support.append("official")
	if popup.is_item_checked(1):
		result.support.append("community")
	if popup.is_item_checked(2):
		result.support.append("testing")
	
	if _search_field.text.strip_edges() != "":
		result.filter = _search_field.text.strip_edges()
	
	# If disabled will list godot 2 assets, due to the way the API works.
	if _version_option.get_selected_id() != -1:
		result.godot_version = _version_option.get_item_text(
				_version_option.get_item_index(
						_version_option.get_selected_id()
				)
		)
	
	result.max_results = _ASSETS_PER_PAGE
	
	result.page = _current_page
	
	match _sort_option.get_selected_id():
		0:
			result.sort = "updated"
			result.reverse = false
		1:
			result.sort = "updated"
			result.reverse = true
		2:
			result.sort = "name"
			result.reverse = false
		3:
			result.sort = "name"
			result.reverse = false
		4:
			result.sort = "cost"
			result.reverse = false
		5:
			result.sort = "cost"
			result.reverse = true
	
	return result


## Displays the overlay screen with the message [param message].  If
## [param failute] is set to true also displays a button to retry the
## query.
func _message(failure: bool, message: String):
	_overlay_contents.show()
	_status_label.text = message
	_scroll_container.modulate = Color(1, 1, 1, 0.5)
	if failure:
		_refresh_button.show()
	else:
		_refresh_button.hide()


## Hides the loading/message overlay.
func _clear_message():
	_scroll_container.modulate = Color(1, 1, 1, 1)
	_overlay_contents.hide()


func _on_refresh_button_pressed():
	if _fetched_versions:
		_fetch_assets()
	else:
		await _setup_version_button()
		_fetch_assets()
