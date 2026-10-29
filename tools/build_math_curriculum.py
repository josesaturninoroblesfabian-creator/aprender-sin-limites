"""Build the reviewed mathematics missions and their offline narration catalog."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOICE_ROOT = "res://assets/audio/llama/activities/"

UNITS = [
    ("addition", "Juntamos hasta 5", "Junta dos cantidades para encontrar el total.", (2, 3), [(1, 1), (2, 1), (0, 3), (2, 2), (3, 2), (4, 0)]),
    ("addition", "Sumamos hasta 10", "Empieza en el número mayor y cuenta lo que agregas.", (5, 4), [(5, 2), (3, 4), (6, 2), (4, 5), (7, 3), (6, 4)]),
    ("addition", "Pasamos por el 10", "Completa una decena y suma lo que falta.", (8, 5), [(8, 4), (9, 3), (7, 6), (8, 7), (6, 9), (9, 8)]),
    ("addition", "Decenas y unidades", "Suma unidades y decenas; cambia diez unidades por una decena.", (27, 18), [(24, 13), (35, 22), (28, 15), (46, 27), (57, 18), (38, 26)]),
    ("subtraction", "Quitamos hasta 5", "Descubre qué queda cuando quitamos una parte.", (5, 2), [(3, 1), (4, 2), (5, 1), (5, 3), (4, 3), (5, 5)]),
    ("subtraction", "Retrocedemos hasta 10", "Empieza en la cantidad inicial y retrocede.", (9, 4), [(8, 2), (9, 3), (7, 4), (10, 5), (8, 0), (10, 7)]),
    ("subtraction", "Cruzamos una decena", "Descompón lo que quitas para pasar por el diez.", (14, 6), [(12, 5), (13, 7), (15, 8), (16, 9), (14, 8), (17, 9)]),
    ("subtraction", "Cambiamos una decena", "Cambia una decena por diez unidades cuando lo necesites.", (42, 17), [(38, 14), (57, 23), (43, 18), (62, 27), (71, 36), (54, 28)]),
    ("multiplication", "Grupos del mismo tamaño", "Multiplicar cuenta objetos organizados en grupos iguales.", (3, 2), [(2, 2), (3, 2), (2, 3), (4, 2), (3, 3), (2, 4)]),
    ("multiplication", "Saltos de 2, 5 y 10", "Relaciona las tablas con sumas repetidas.", (5, 4), [(2, 6), (5, 3), (10, 2), (2, 8), (5, 6), (10, 4)]),
    ("multiplication", "Filas y columnas", "Una fila es un grupo; cuenta todas sin perder ninguna.", (4, 6), [(3, 4), (4, 5), (6, 3), (3, 7), (4, 8), (6, 6)]),
    ("multiplication", "Tablas que se conectan", "Usa grupos conocidos para construir productos nuevos.", (7, 8), [(7, 4), (8, 3), (9, 5), (7, 6), (8, 8), (9, 7)]),
    ("division", "Repartimos por igual", "Cada cesta recibe la misma cantidad.", (6, 2), [(4, 2), (6, 2), (6, 3), (8, 2), (9, 3), (10, 2)]),
    ("division", "Una ronda para cada cesta", "Reparte una a cada cesta y repite hasta terminar.", (12, 3), [(12, 2), (12, 3), (15, 3), (16, 4), (18, 3), (20, 5)]),
    ("division", "Dividir y multiplicar", "Comprueba el reparto multiplicando grupos por cantidad.", (24, 4), [(24, 3), (24, 4), (28, 4), (30, 5), (36, 6), (42, 6)]),
    ("division", "El reparto completo", "Encuentra cuánto recibe cada grupo y comprueba el total.", (56, 7), [(35, 7), (48, 6), (56, 8), (63, 7), (72, 9), (81, 9)]),
]


def result(operation, a, b):
    return {"addition": lambda: a + b, "subtraction": lambda: a - b,
            "multiplication": lambda: a * b, "division": lambda: a // b}[operation]()


def question(operation, a, b, qid):
    item = f"{a} manzana" + ("s" if a != 1 else "")
    prompts = {
        "addition": f"En una canasta hay {item}. Agregamos {b} más. ¿Cuántas hay ahora?",
        "subtraction": f"En una canasta había {item}. Retiramos {b}. ¿Cuántas quedan?",
        "multiplication": f"Hay {a} cestas con {b} manzanas en cada una. ¿Cuántas manzanas hay en total?",
        "division": f"Repartimos {item} por igual entre {b} cestas. ¿Cuántas van en cada cesta?",
    }
    value = result(operation, a, b)
    return {"id": qid, "operation": operation, "a": a, "b": b, "result": value,
            "text": prompts[operation], "audio": VOICE_ROOT + qid + ".mp3"}


def build():
    lessons, clips = [], {}
    guides = {
        "addition": "Vamos a aprender a sumar. Elige una misión. Primero mueve las cantidades y después resuelve seis retos.",
        "subtraction": "Vamos a aprender a restar. Mira la cantidad inicial, quita una parte y descubre cuánto queda.",
        "multiplication": "Vamos a multiplicar. Forma grupos del mismo tamaño y descubre la suma que se repite.",
        "division": "Vamos a dividir. Reparte por igual y comprueba que todas las cestas reciben lo mismo.",
        "count_objects": "Bienvenido al huerto. Toca cada objeto una sola vez para contarlo y elige cuántos hay. Son ocho rondas.",
        "solve_exercises": "La feria necesita tu ayuda. Elige las operaciones y la dificultad. Lee o escucha cada problema, piensa y responde.",
        "level_game": "Una aventura por los Andes. Mueve la llama, salta y recoge estrellas. Resuelve las tres puertas matemáticas para llegar a la meta.",
        "quick_challenge": "Bienvenido a la fiesta de globos. Resuelve la operación y toca el globo correcto. Puedes jugar con tiempo o sin reloj.",
        "correct": "¡Muy bien pensado! Sigue así.",
        "retry": "Todavía no. Puedes mirar la pista y probar otra vez. Aprender también es intentarlo.",
        "done": "¡Misión terminada! Tu avance se guardó en este dispositivo.",
        "model_done": "¡Lo descubriste paso a paso! Ahora te toca resolver seis retos.",
        "resume": "Puedes continuar donde lo dejaste o empezar de nuevo para practicar.",
        "help": "Escucha la pregunta, observa el dibujo y mueve las cantidades. Puedes pedir una pista. No hay prisa para aprender.",
        "step_add": "Empezamos en la primera cantidad y avanzamos lo que agregamos. Observa cómo cambia el total.",
        "step_sub": "Empezamos en la cantidad que teníamos. Cada salto hacia atrás representa una parte que quitamos.",
        "step_mult": "Cada fila tiene la misma cantidad. Añade un grupo y observa cómo crece el total.",
        "step_div": "Reparte una ronda. Cada cesta recibe una manzana. Repite hasta que todas queden repartidas.",
        "pause": "Hacemos una pausa. Puedes seguir cuando quieras.",
        "level_done": "¡Llegaste a la meta! Resolviste las tres puertas y completaste el camino.",
        "quick_ready": "Cuando estés listo, empieza la fiesta. Cada acierto enciende un globo. Los errores son otra oportunidad para aprender.",
        "choose_answer": "Piensa en la operación y elige tu respuesta.",
        "look_problem": "Mira el problema. Puedes escucharlo y abrir la pista si necesitas ayuda.",
    }
    for key, text in guides.items():
        clips[key] = {"file": key + ".mp3", "text": text}
    counters = {}
    for operation, title, aim, model, pairs in UNITS:
        counters[operation] = counters.get(operation, 0) + 1
        tier = counters[operation]
        uid = f"{operation}_{tier}"
        example = question(operation, *model, uid + "_intro")
        intro = f"{title}. {aim} {example['text']} Vamos a descubrirlo juntos."
        example["audio"] = VOICE_ROOT + uid + "_intro.mp3"
        clips[uid + "_intro"] = {"file": uid + "_intro.mp3", "text": intro}
        questions = [question(operation, *pair, f"{uid}_q{i + 1}") for i, pair in enumerate(pairs)]
        for item in questions:
            clips[item["id"]] = {"file": item["id"] + ".mp3", "text": item["text"]}
        lessons.append({"id": uid, "topic": operation, "tier": tier, "title": title, "aim": aim,
                        "intro": intro, "model": example, "questions": questions})
    for value in range(1, 21):
        key = f"count_{value}"
        clips[key] = {"file": key + ".mp3", "text": "Toca los objetos para contarlos. ¿Cuántos hay en total?"}
    target = ROOT / "data/math"
    target.mkdir(parents=True, exist_ok=True)
    (target / "activities.json").write_text(json.dumps({"version": 1, "lessons": lessons}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    (target / "activities_voice_lines.json").write_text(json.dumps({"clips": clips}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Built {len(lessons)} lessons, {sum(len(l['questions']) for l in lessons)} questions and {len(clips)} voice entries.")


if __name__ == "__main__":
    build()
