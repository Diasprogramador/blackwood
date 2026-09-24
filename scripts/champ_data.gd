class_name ChampData
extends Object

## Dados dos campeões/roles — port dos enums Java (Role + skills do GamePanel).

const CHAMPS := [
	{ nome = "Garen", role = "tank", desc = "Tanque blindado,\nresiste a tudo",
	  color = Color(0.27, 0.39, 0.71) },
	{ nome = "Zed", role = "assassin", desc = "Dano explosivo,\nmuito frágil",
	  color = Color(0.2, 0.2, 0.24) },
	{ nome = "Ahri", role = "mage", desc = "Dano mágico alto,\nhabilidades arcanas",
	  color = Color(0.59, 0.27, 0.78) },
	{ nome = "Ashe", role = "marksman", desc = "Dano físico constante,\nbom de kiting",
	  color = Color(0.2, 0.63, 0.35) },
	{ nome = "Janna", role = "support", desc = "Cura e proteção,\nsuporte time",
	  color = Color(0.27, 0.71, 0.71) },
]

## Raridades das habilidades (slot 0→4 = comum→mítico).
const RARITIES := [
	{ name = "COMUM", color = Color(0.72, 0.72, 0.76) },
	{ name = "RARO", color = Color(0.3, 0.6, 1.0) },
	{ name = "ÉPICO", color = Color(0.7, 0.35, 1.0) },
	{ name = "LENDÁRIO", color = Color(1.0, 0.6, 0.15) },
	{ name = "MÍTICO", color = Color(1.0, 0.22, 0.3) },
]

const SKILL_SLOTS := 5

const ROLES := {
	"tank": {
		display = "Tanque", hp = 150, atk = 12, def = 14, mag = 8, mana = 120, range = 70,
		skills = [
			{ name = "Golpe Destemido", kind = "damage", mana = 14, power = 20, cd = 2.0, rarity = 0, price = 30, desc = "Golpe rápido e confiável." },
			{ name = "Fúria de Ferro", kind = "damage", mana = 22, power = 34, cd = 7.0, rarity = 1, price = 70, desc = "Esmaga com o escudo." },
			{ name = "Impacto Sísmico", kind = "damage", mana = 30, power = 52, cd = 13.0, rarity = 2, price = 140, desc = "O chão treme." },
			{ name = "Cólera do Colosso", kind = "damage", mana = 40, power = 78, cd = 21.0, rarity = 3, price = 240, desc = "Fúria imparável." },
			{ name = "Julgamento de Demacia", kind = "damage", mana = 55, power = 115, cd = 34.0, rarity = 4, price = 400, desc = "O veredito final." },
		],
	},
	"assassin": {
		display = "Assassino", hp = 80, atk = 18, def = 8, mag = 10, mana = 95, range = 60,
		skills = [
			{ name = "Sombra Relâmpago", kind = "damage", mana = 14, power = 22, cd = 1.8, rarity = 0, price = 30, desc = "Corte veloz das sombras." },
			{ name = "Lâmina das Sombras", kind = "damage", mana = 24, power = 38, cd = 7.0, rarity = 1, price = 70, desc = "Lâmina envenenada." },
			{ name = "Dança das Adagas", kind = "damage", mana = 32, power = 58, cd = 13.0, rarity = 2, price = 140, desc = "Chuva de lâminas." },
			{ name = "Marca da Morte", kind = "damage", mana = 42, power = 85, cd = 21.0, rarity = 3, price = 240, desc = "Sentença marcada." },
			{ name = "Eclipse Sombrio", kind = "damage", mana = 58, power = 125, cd = 34.0, rarity = 4, price = 400, desc = "A escuridão consome." },
		],
	},
	"mage": {
		display = "Mago", hp = 60, atk = 8, def = 6, mag = 18, mana = 145, range = 200,
		skills = [
			{ name = "Orbe Arcano", kind = "magic", mana = 14, power = 24, cd = 2.2, rarity = 0, price = 30, desc = "Projétil arcano." },
			{ name = "Corte Rápido", kind = "damage", mana = 12, power = 26, cd = 1.6, rarity = 1, price = 70, desc = "Lâmina de vento." },
			{ name = "Explosão Rúnica", kind = "magic", mana = 30, power = 55, cd = 12.0, rarity = 2, price = 140, desc = "Detona as runas." },
			{ name = "Tempestade Arcana", kind = "magic", mana = 40, power = 85, cd = 20.0, rarity = 3, price = 240, desc = "Céu em fúria." },
			{ name = "Supernova", kind = "magic", mana = 55, power = 130, cd = 34.0, rarity = 4, price = 400, desc = "Uma estrela morre." },
		],
	},
	"marksman": {
		display = "Atirador", hp = 70, atk = 16, def = 6, mag = 12, mana = 105, range = 260,
		skills = [
			{ name = "Flecha de Gelo", kind = "damage", mana = 14, power = 22, cd = 2.0, rarity = 0, price = 30, desc = "Tiro congelante." },
			{ name = "Chuva de Flechas", kind = "damage", mana = 26, power = 40, cd = 9.0, rarity = 1, price = 70, desc = "Saraivada certeira." },
			{ name = "Tiro Perfurante", kind = "damage", mana = 32, power = 60, cd = 13.0, rarity = 2, price = 140, desc = "Atravessa armadura." },
			{ name = "Saraivada Mortal", kind = "damage", mana = 42, power = 88, cd = 21.0, rarity = 3, price = 240, desc = "Sem escapatória." },
			{ name = "Flecha do Fim", kind = "damage", mana = 58, power = 128, cd = 34.0, rarity = 4, price = 400, desc = "Um tiro, um fim." },
		],
	},
	"support": {
		display = "Suporte", hp = 90, atk = 8, def = 10, mag = 14, mana = 125, range = 150,
		skills = [
			{ name = "Ventania Curativa", kind = "heal", mana = 14, power = 30, cd = 3.0, rarity = 0, price = 30, desc = "Brisa que restaura." },
			{ name = "Vento Cortante", kind = "damage", mana = 16, power = 28, cd = 4.0, rarity = 1, price = 70, desc = "Para se defender." },
			{ name = "Bênção de Janna", kind = "heal", mana = 28, power = 55, cd = 12.0, rarity = 2, price = 140, desc = "Proteção sagrada." },
			{ name = "Olho da Tempestade", kind = "heal", mana = 38, power = 85, cd = 20.0, rarity = 3, price = 240, desc = "O olho acalma tudo." },
			{ name = "Renascimento", kind = "heal", mana = 55, power = 130, cd = 34.0, rarity = 4, price = 400, desc = "A tormenta cura." },
		],
	},
}

static func rarity_name(r: int) -> String:
	var rr: Dictionary = RARITIES[clampi(r, 0, RARITIES.size() - 1)]
	return str(rr.get("name", "?"))

static func rarity_color(r: int) -> Color:
	var rr: Dictionary = RARITIES[clampi(r, 0, RARITIES.size() - 1)]
	return rr.get("color", Color.WHITE)

const UPGRADE_NAMES := ["Vitalidade", "Força", "Armadura", "Poder Mágico", "Precisão", "Fluxo de Mana"]
const UPGRADE_DESCS := [
	"+30 HP máximo", "+5 ATK", "+4 DEF", "+4 MAG", "+5% Crítico", "+1.5 Mana Regen"
]
const UPGRADE_ICONS := ["♥", "⚔", "🛡", "✦", "◎", "💧"]
const UPGRADE_BASE_COST := [50, 60, 55, 55, 80, 70]
