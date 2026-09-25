class_name MoveHelper
extends Object

## Movimento com corpo + anti-garra para player e inimigos.
## Antes a colisão testava só o ponto central: o corpo entrava em vão
## apertado (lago/mata/pedra) e o boneco garrava no canto. Agora o passo
## testa o destino com raio (centro + 4 pontos) e o watchdog teleporta
## para o ponto livre mais próximo se nada mais soltar.

## Raio do corpo para a colisão (metade do tile = 16; 10 passa em vão de 1 tile).
const BODY_R := 10.0

## Destino com folga total? (centro + cruz ao redor, tudo fora do sólido)
static func can_enter(world: World, pos: Vector2, r := BODY_R) -> bool:
	if world == null:
		return false
	if world.is_solid_at(pos.x, pos.y):
		return false
	if world.is_solid_at(pos.x - r, pos.y):
		return false
	if world.is_solid_at(pos.x + r, pos.y):
		return false
	if world.is_solid_at(pos.x, pos.y - r):
		return false
	if world.is_solid_at(pos.x, pos.y + r):
		return false
	return true

## Passo com deslizamento por eixo (nunca entra no sólido).
## Quem já está DENTRO do sólido sempre pode sair (regra de fuga).
static func slide_step(world: World, pos: Vector2, step: Vector2, r := BODY_R) -> Vector2:
	if world == null or step == Vector2.ZERO:
		return pos
	if world.is_solid_at(pos.x, pos.y):
		return pos + step
	var out := pos
	if can_enter(world, Vector2(pos.x + step.x, pos.y), r):
		out.x = pos.x + step.x
	if can_enter(world, Vector2(out.x, pos.y + step.y), r):
		out.y = pos.y + step.y
	if out == pos and step.length() > 0.5:
		# Canto côncavo: tenta meio-passo combinado antes de desistir.
		var half := pos + step * 0.5
		if can_enter(world, half, r):
			out = half
	return out

## Ponto livre (com folga) mais próximo, em anéis de tiles. INF se não achar.
static func find_free(world: World, pos: Vector2, max_ring := 8) -> Vector2:
	if world == null:
		return Vector2.INF
	var tile := float(World.TILE)
	var cx := int(floor(pos.x / tile))
	var cy := int(floor(pos.y / tile))
	for ring in range(1, max_ring + 1):
		for dy in range(-ring, ring + 1):
			for dx in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var cand := Vector2((cx + dx) * tile + tile * 0.5,
					(cy + dy) * tile + tile * 0.5)
				if can_enter(world, cand):
					return cand
	return Vector2.INF
