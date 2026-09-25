class_name Netplay
extends Node

## Transporte multiplayer (ENet, host autoritativo, até 2 jogadores).
## Sem relay externo: funciona na mesma rede e, pela internet, quando o
## host alcança o amigo (UPnP automático) ou via VPN virtual
## (Radmin/ZeroTier — sem configurar roteador). Sem Godot instalado aqui,
## então revise com carinho: toda RPC tem par e mesmo caminho de nó
## (/root/Main/Netplay nos dois lados).

signal peer_joined(id: int)
signal peer_left(id: int)
signal server_ready
signal connect_failed

const PORT := 4242
const MAX_PLAYERS := 2

var mode := 0  # 0 = solo, 1 = host, 2 = client
var peer: ENetMultiplayerPeer = null
var upnp_info := ""
var local_ip := ""

func is_mp() -> bool:
	return mode != 0

func is_host() -> bool:
	return mode == 1

func is_client() -> bool:
	return mode == 2

func _ready() -> void:
	get_tree().multiplayer.peer_connected.connect(_on_peer_connected)
	get_tree().multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	get_tree().multiplayer.connected_to_server.connect(func(): server_ready.emit())
	get_tree().multiplayer.connection_failed.connect(func(): connect_failed.emit())

func _on_peer_connected(id: int) -> void:
	peer_joined.emit(id)

func _on_peer_disconnected(id: int) -> void:
	peer_left.emit(id)

func has_ally() -> bool:
	if mode == 1:
		return get_tree().multiplayer.get_peers().size() > 0
	return mode == 2

# ----------------------------------------------------------------------
#  HOST / JOIN / SAIR
# ----------------------------------------------------------------------
func host(port := PORT) -> String:
	leave()
	local_ip = _pick_local_ip()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_server(port, MAX_PLAYERS - 1)
	if err != OK:
		return "Falha ao hospedar (porta %d ocupada?)" % port
	peer = p
	get_tree().multiplayer.multiplayer_peer = peer
	mode = 1
	upnp_info = _try_upnp(port)
	return ""

func join(ip: String, port := PORT) -> String:
	leave()
	var clean := ip.strip_edges()
	if clean == "":
		return "Digite o IP do host."
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(clean, port)
	if err != OK:
		return "Falha ao conectar."
	peer = p
	get_tree().multiplayer.multiplayer_peer = peer
	mode = 2
	return ""

func leave() -> void:
	if peer != null:
		peer.close()
		peer = null
	get_tree().multiplayer.multiplayer_peer = null
	mode = 0

func _pick_local_ip() -> String:
	for ip in IP.get_local_addresses():
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	for ip in IP.get_local_addresses():
		if not ip.begins_with("127.") and ip.find(":") < 0:
			return ip
	return "127.0.0.1"

## UPnP best-effort (muitos roteadores abrem sozinhos; CGNAT não abre).
func _try_upnp(port: int) -> String:
	var up := UPNP.new()
	var err := up.discover(2000, 2, "InternetGatewayDevice")
	if err != UPNP.UPNP_RESULT_SUCCESS:
		return "UPnP indisponível — use mesma rede ou Radmin/ZeroTier."
	var gw = up.get_gateway()
	if gw == null or not gw.is_valid_gateway():
		return "UPnP indisponível — use mesma rede ou Radmin/ZeroTier."
	up.add_port_mapping(port, port, "Blackwood", "UDP")
	var ext := "?"
	ext = up.query_external_address()
	return "UPnP ok! IP externo: %s" % ext

# ----------------------------------------------------------------------
#  RPC: cliente -> host
# ----------------------------------------------------------------------
@rpc("any_peer", "reliable")
func hello(champ_idx: int) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_hello"):
		main.mp_on_hello(int(champ_idx))

@rpc("any_peer", "reliable")
func ready() -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_ready"):
		main.mp_on_ready()

@rpc("any_peer", "unreliable")
func push_input(move: Vector2, atk: bool, sk: Array, channel: bool, item: bool) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_input"):
		main.mp_on_input(move, atk, sk, channel, item)

@rpc("any_peer", "reliable")
func req_upgrade(idx: int) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_buy_upgrade"):
		main.mp_on_buy_upgrade(int(idx))

@rpc("any_peer", "reliable")
func req_item(idx: int) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_buy_item"):
		main.mp_on_buy_item(int(idx))

# ----------------------------------------------------------------------
#  RPC: host -> cliente
# ----------------------------------------------------------------------
@rpc("authority", "reliable")
func begin(seed_value: int, stage: int, diff: int, host_champ: int) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_begin"):
		main.mp_on_begin(int(seed_value), int(stage), int(diff), int(host_champ))

@rpc("authority", "unreliable")
func snap_players(a: Array, b: Array) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_apply_players"):
		main.mp_apply_players(a, b)

@rpc("authority", "unreliable")
func snap_enemies(list: Array) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_apply_enemies"):
		main.mp_apply_enemies(list)

@rpc("authority", "unreliable")
func snap_coins(list: Array) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_apply_coins"):
		main.mp_apply_coins(list)

@rpc("authority", "unreliable")
func snap_wave(arr: Array) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_apply_wave"):
		main.mp_apply_wave(arr)

@rpc("authority", "reliable")
func spawn_shot(from: Vector2, dir: Vector2, speed: float, dmg: int, col: Color) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_apply_shot"):
		main.mp_apply_shot(from, dir, float(speed), int(dmg), col)

@rpc("authority", "unreliable")
func fx_spawn(fx_type: int, x: float, y: float, s: float) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_apply_fx"):
		main.mp_apply_fx(int(fx_type), float(x), float(y), float(s))

@rpc("authority", "unreliable")
func float_txt(txt: String, x: float, y: float, col: Color, size: int) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_apply_float"):
		main.mp_apply_float(str(txt), float(x), float(y), col, int(size))

@rpc("authority", "reliable")
func force_state(s: int) -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_force_state"):
		main.mp_on_force_state(int(s))

@rpc("authority", "reliable")
func to_menu() -> void:
	var main := get_parent()
	if main != null and main.has_method("mp_on_to_menu"):
		main.mp_on_to_menu()

# ----------------------------------------------------------------------
#  Envio (chamados pelo main no lado certo)
# ----------------------------------------------------------------------
func send_input(move: Vector2, atk: bool, sk: Array, channel: bool, item: bool) -> void:
	if mode != 2:
		return
	push_input.rpc(move, atk, sk, channel, item)

func send_hello(champ_idx: int) -> void:
	if mode != 2:
		return
	hello.rpc(int(champ_idx))
	ready.rpc()

func send_buy_upgrade(idx: int) -> void:
	if mode != 2:
		return
	req_upgrade.rpc(int(idx))

func send_buy_item(idx: int) -> void:
	if mode != 2:
		return
	req_item.rpc(int(idx))
