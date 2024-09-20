class_name CharacterDefaultStats

enum available {MARIO, LUIGI, WARIO, WALUIGI, PEACH}

func create_character(chosed_character : available) -> Brother:
    var bros = Brother.new("Dummy",1,1)

    match(chosed_character):
        available.MARIO:
            bros.character_name = "Mario"
            bros.level = 5
            bros.xp = 300
            bros.max_hp = 21
            bros.hp = bros.max_hp
            bros.max_bp = 18
            bros.bp = bros.max_bp
            bros.attack = 15
            bros.defense = 11
            bros.speed = 16
            bros.action_button = &"MarioButton"
            
        available.LUIGI:
            bros.character_name = "Luigi"
            bros.level = 5
            bros.xp = 300
            bros.max_hp = 24
            bros.hp = bros.max_hp
            bros.max_bp = 15
            bros.bp = bros.max_bp
            bros.attack = 14
            bros.defense = 13
            bros.speed = 14
            bros.action_button = &"LuigiButton"

    return bros
             