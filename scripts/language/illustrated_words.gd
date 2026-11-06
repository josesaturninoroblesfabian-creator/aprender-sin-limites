extends RefCounted

const WORDS_BY_LETTER := {
	"A": ["Árbol|🌳", "Avión|✈️", "Abeja|🐝"], "B": ["Barco|🚢", "Balón|⚽", "Bicicleta|🚲"],
	"C": ["Casa|🏠", "Conejo|🐇", "Cereza|🍒"], "D": ["Dado|🎲", "Delfín|🐬", "Dinosaurio|🦖"],
	"E": ["Elefante|🐘", "Estrella|⭐", "Escoba|🧹"], "F": ["Flor|🌸", "Foca|🦭", "Flauta|🪈"],
	"G": ["Gato|🐈", "Globo|🎈", "Guitarra|🎸"], "H": ["Helado|🍦", "Huevo|🥚", "Hormiga|🐜"],
	"I": ["Isla|🏝️", "Iguana|🦎", "Imán|🧲"], "J": ["Jirafa|🦒", "Jabón|🧼", "Jardín|🌷"],
	"K": ["Koala|🐨", "Kiwi|🥝", "Kimono|👘"], "L": ["León|🦁", "Luna|🌙", "Lápiz|✏️"],
	"M": ["Manzana|🍎", "Mariposa|🦋", "Montaña|⛰️"], "N": ["Nube|☁️", "Naranja|🍊", "Nido|🪺"],
	"Ñ": ["Ñandú|🐦", "Ñame|🍠", "Ñu|🦬"], "O": ["Oso|🐻", "Oveja|🐑", "Olla|🍲"],
	"P": ["Perro|🐕", "Pelota|⚽", "Piña|🍍"], "Q": ["Queso|🧀", "Quena|🪈", "Quetzal|🐦"],
	"R": ["Rana|🐸", "Reloj|⌚", "Robot|🤖"], "S": ["Sol|☀️", "Sandía|🍉", "Silla|🪑"],
	"T": ["Tortuga|🐢", "Tren|🚂", "Tomate|🍅"], "U": ["Uva|🍇", "Unicornio|🦄", "Uniforme|👔"],
	"V": ["Vaca|🐄", "Vela|🕯️", "Volcán|🌋"], "W": ["Wafle|🧇", "Wifi|📶", "Wok|🍳"],
	"X": ["Xilófono|🎼", "Xoloitzcuintle|🐕", "Xenón|💡"], "Y": ["Yate|🛥️", "Yegua|🐎", "Yoyo|🪀"],
	"Z": ["Zapato|👞", "Zorro|🦊", "Zanahoria|🥕"]
}
