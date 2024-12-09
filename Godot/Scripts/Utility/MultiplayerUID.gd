# This class is used as the User IDentifier for Multiplayer

class MultiplayerPublicUID:
    var username : String
    var id : int

class MultiplayerAdminUID:
    var username : String
    var id : int

@rpc("any_peer")
func _send_info():
    