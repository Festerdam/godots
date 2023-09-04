class_name AssetListing
extends HBoxContainer
## Class for the listing of an asset.
##
## This class does not handle interaction see asset_listing_interactible.gd
## instead.


var _title: String
var _category: String
var _author: String
var _license: String

@onready var _title_node: LinkButton = %Title
@onready var _category_node: Label = %Category
@onready var _author_node: Label = %Author
@onready var _license_node: Label = %License


func _ready():
	_title_node.text = _title
	_category_node.text = _category
	_author_node.text = _author
	_license_node.text = _license


func init_asset_listing(title: String, category: String, author: String,
		license: String):
	_title = title
	_category = category
	_author = author
	_license = license
	return self
