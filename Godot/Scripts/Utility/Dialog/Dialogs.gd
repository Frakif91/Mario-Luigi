class_name Dialog extends Resource

@export var linked_script : Script

func execute(_tree, _player, _npc):
    #assert(linked_script, "This dialog : " + str(self) + " doesn't contain a linked script")

    if linked_script:
        linked_script.call(&"execute")