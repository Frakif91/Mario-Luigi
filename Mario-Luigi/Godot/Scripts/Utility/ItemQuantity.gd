class_name Item_Quantity extends Resource

@export var item : UniqueItem;
@export var quantity : int;

func _init(_item : UniqueItem, _quantity : int = 0):
    self.item = _item
    self.quantity = _quantity