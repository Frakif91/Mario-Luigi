class_name Dialog extends Object

@export var linked_script : Script

func execute(tree, player, npc):
    #assert(linked_script, "This dialog : " + str(self) + " doesn't contain a linked script")

    if linked_script:
        linked_script.call(&"execute")