extends Control

@onready var item_category = $"Background/HContainer/ShopCategoryConainter/ItemTypeList"
var selected_item_category

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in item_category.get_child_count():
		var child : Control = item_category.get_child(i)
		if child.is_in_group(&"ShopCategoryButton"):
			child.mouse_entered.connect(_item_category_select.bind(i))
			child.mouse_exited.connect(_item_category_unselect.bind(i))

func _item_category_select(idx : int):
	var child = item_category.get_child(idx)
	selected_item_category = child
	#child.size_flags_stretch_ratio = 1.4
	child.create_tween().tween_property(child,^"size_flags_stretch_ratio",1.4,0.2)
	child.create_tween().tween_property(child,^"self_modulate",Color(1,1,1,1),0.2)
	child.create_tween().tween_property(child,^"custom_minimum_size",Vector2(170,0),0.2)
func _item_category_unselect(idx : int):
	var child : Control = item_category.get_child(idx)
	selected_item_category = child
	#child.size_flags_stretch_ratio = 1
	child.create_tween().tween_property(child,^"size_flags_stretch_ratio",1.,0.2)
	child.create_tween().tween_property(child,^"self_modulate",Color(0.8,0.8,0.8,0.8),0.2)
	child.create_tween().tween_property(child,^"custom_minimum_size",Vector2(160,0),0.2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
