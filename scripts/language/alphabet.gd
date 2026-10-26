extends RefCounted

## Shared Spanish alphabet; order is also used by the tracing selector.
const LETTERS := ["A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "Ñ", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"]

## Pronunciación del nombre de cada letra, en el mismo orden de LETTERS.
## Se usa como respaldo para TTS si falta un audio local.
const LETTER_NAMES := ["a", "be", "ce", "de", "e", "efe", "ge", "hache", "i", "jota", "ka", "ele", "eme", "ene", "eñe", "o", "pe", "cu", "erre", "ese", "te", "u", "uve", "doble u", "equis", "ye", "zeta"]
