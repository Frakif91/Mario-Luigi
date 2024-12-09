class_name Multiplayer_Info extends Node

class MultiplayerClientUID extends Node:
	var username : String
	var id : int

class MultiplayerServerUID:
	var port : int
	var description : String
	var max_player : int
	var players : Array[MultiplayerClientUID]

class ServerState:
	var port : int
	var description : String
	var max_player : int
