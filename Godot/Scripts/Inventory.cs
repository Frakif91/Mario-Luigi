using Godot;
using Godot.NativeInterop;
using System;
using System.Collections.Generic;
using System.Reflection.Metadata;
using System.Runtime.CompilerServices;
//using Item_Quantity = System.Collections.Generic.KeyValuePair<UniqueItem,uint>;

public partial class Inventory : Node
{
	// Called when the node enters the scene tree for the first time.
	public override void _Ready()
	{
	}

	// Called every frame. 'delta' is the elapsed time since the previous frame.
	public override void _Process(double delta)
	{
	}
}

public struct Item_Quantity {
	public UniqueItem item;
	public uint quantity;

	public Item_Quantity(UniqueItem _item, uint _quantity){
		item = _item;
		quantity = _quantity;
	}
}

public class UniqueItem {

	private Texture2D texture;
	private string name;
	private string description;

	#nullable enable
    public UniqueItem(Texture2D? _texture, string? _name, string? _description){
		if (_texture is null){
			_texture = GD.Load<Texture2D>("res://Godot/Assets/shroom_default.tres");
		}
		if (_name is null){
			_name = "Default Shroom";
		}
		if (_description is null){
			_description = "An normal mushroom with the texture of a golden one, gain 30 HP on use.";
		}
		
		texture = _texture;
		name = _name;
		description = _description;
	}

	public UniqueItem CreateEmptyItem(){
		return new UniqueItem(new Godot.PlaceholderTexture2D(), "No Item", "This item is empty");
	}
}



public class ItemInventory {

	Item_Quantity FindItemQuantity(UniqueItem unique_item){
		Item_Quantity kvp;
		for(int i = 0; i < items.Count; i++){
			kvp = items[i];

			if (kvp.item == unique_item){
				return kvp;
			}
		}
		return new Item_Quantity();
	}

	public List<Item_Quantity> items = new List<Item_Quantity>();
	public void AddItem(UniqueItem _item, uint _quantity){
		int i = 0;
		Item_Quantity kvp;

		for(i = 0; i < items.Count; i++){
			kvp = items[i];

			// Second Try = working
			if (kvp.item == _item){
				kvp = new Item_Quantity()
				{
					item = _item,
					quantity = kvp.quantity + _quantity};
				return; //Stop here, job's done
			}
		}
		//If no existing item was found, add it to the list
		items.Add(new Item_Quantity(item = _item, quantity = _quantity));

	}
	public void RemoveItem(UniqueItem item, uint quantity){
		int i = 0;
		Item_Quantity kvp;

		for(i = 0; i < items.Count; i++){
			kvp = items[i];
			
			if (kvp.Key == item){

				if(kvp.Value - quantity <= 0){
					items.RemoveAt(i);
				}
				else
				{
					kvp = new Item_Quantity(item, kvp.Value - quantity);
				}
			}
		}
	}
	/// <summary>
	/// 
	/// </summary>
	public Godot.Error EatItemExample(UniqueItem item){
		if (FindItemQuantity(item).Value >= 1) {
			
		}
	}
}