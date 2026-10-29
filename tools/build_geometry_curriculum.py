"""Build reviewed geometry missions, interactive examples and offline narration."""
import json
import copy
from pathlib import Path
import random

ROOT = Path(__file__).resolve().parents[1]
VOICE = "res://assets/audio/llama/geometry_activities/"
PLANES = ["circle", "triangle", "square", "rectangle", "pentagon", "hexagon"]
SOLIDS = ["cube", "sphere", "cylinder", "cone"]
NAMES = {"circle": "círculo", "triangle": "triángulo", "square": "cuadrado", "rectangle": "rectángulo alargado",
         "pentagon": "pentágono", "hexagon": "hexágono", "cube": "cubo", "sphere": "esfera", "cylinder": "cilindro", "cone": "cono"}
SIDES = {"circle": 0, "triangle": 3, "square": 4, "rectangle": 4, "pentagon": 5, "hexagon": 6}
COLORS = ["red", "blue", "gold", "green", "violet", "turquoise"]
COLOR_NAMES = {"red": "rojo", "blue": "azul", "gold": "amarillo", "green": "verde", "violet": "violeta", "turquoise": "turquesa"}
TOPICS = ["flat_shapes", "solid_shapes", "sides_vertices", "shape_patterns"]
FEATURES = {
    "circle": "un borde curvo y ninguna esquina",
    "triangle": "tres lados rectos y tres esquinas",
    "square": "cuatro lados iguales y cuatro esquinas rectas",
    "rectangle": "dos lados largos, dos cortos y cuatro esquinas rectas",
    "pentagon": "cinco lados rectos y cinco esquinas",
    "hexagon": "seis lados rectos y seis esquinas",
}


def token(shape, color):
    return shape + ":" + color


def shuffled(values, seed):
    items = list(values)
    random.Random(seed).shuffle(items)
    return items


def choices(target, pool, seed):
    return shuffled([target, *[value for value in shuffled(pool, seed) if value != target][:3]], seed + 123)


def plane(shape, qid, angle=0, property_prompt=False):
    text = f"Busca la figura con {FEATURES[shape]}. Encájala en su contorno." if property_prompt else f"Encaja el {NAMES[shape]} en su contorno. Aunque gire, sigue siendo la misma figura."
    seed = sum(map(ord, qid))
    return {"id": qid, "kind": "plane", "shape": shape, "angle": angle, "color": COLORS[seed % 6],
            "options": choices(shape, PLANES, seed), "result": shape, "text": text}


def solid(shape, qid, object_match=False, prompt=None):
    articles = {"cube": "el cubo", "sphere": "la esfera", "cylinder": "el cilindro", "cone": "el cono"}
    text = prompt or ("Mira el objeto. ¿A qué cuerpo geométrico se parece?" if object_match else "Observa el cuerpo. ¿Cómo se llama?")
    return {"id": qid, "kind": "solid", "shape": shape, "object_match": object_match,
            "options": shuffled(SOLIDS, sum(map(ord, qid))), "result": shape, "text": text,
            "fact": {"cube": "El cubo tiene seis caras planas cuadradas.", "sphere": "La esfera tiene una superficie curva y ninguna cara plana.",
                     "cylinder": "El cilindro tiene dos bases circulares y una superficie lateral curva.", "cone": "El cono tiene una base circular, una superficie curva y una punta."}[shape],
            "spoken_name": articles[shape]}


def count(shape, part, qid, angle=0):
    noun = "lados rectos" if part == "sides" else "vértices o esquinas"
    text = f"Toca uno a uno los {noun} del {NAMES[shape]}. Después elige cuántos hay."
    if shape == "circle": text = "Toca el borde del círculo. Es curvo. ¿Cuántos lados rectos tiene?"
    return {"id": qid, "kind": "count", "shape": shape, "part": part, "angle": angle,
            "result": SIDES[shape], "text": text}


def pattern(unit, qid, holes, repeats=3, color_matters=False):
    sequence = unit * repeats
    if len(sequence) > 9: raise ValueError(qid)
    result = [sequence[i] if color_matters else sequence[i].split(":")[0] for i in holes]
    expected = [sequence[i] for i in holes]
    seed = sum(map(ord, qid))
    pool = [token(shape, color) for shape in PLANES for color in COLORS]
    options = list(dict.fromkeys(expected))
    for value in shuffled(pool, seed):
        if len(options) == 4: break
        if value in options: continue
        if not color_matters and value.split(":")[0] in [t.split(":")[0] for t in options]: continue
        options.append(value)
    names = [NAMES[t.split(":")[0]] + (" " + COLOR_NAMES[t.split(":")[1]] if color_matters else "") for t in unit]
    rule = "La parte que se repite es: " + ", ".join(names) + "."
    return {"id": qid, "kind": "pattern", "sequence": sequence, "unit_size": len(unit), "holes": holes,
            "color_matters": color_matters, "options": shuffled(options, seed), "result": result,
            "text": "Completa los huecos del patrón. " + ("Mira la forma y el color." if color_matters else "Fíjate en la forma, aunque cambie de color."), "rule": rule}


def build():
    lessons, clips = [], {}
    guides = {
        "flat_shapes": "Exploramos figuras planas. Elige una misión. Escucha y arrastra la pieza a su contorno. También puedes tocar la pieza y después el hueco.",
        "solid_shapes": "Vamos a descubrir cuerpos con volumen. Desliza el dedo para girarlos, o usa las flechas de giro. Observa sus caras y superficies y elige su nombre.",
        "sides_vertices": "Los lados rectos unen las esquinas. Los vértices son esas esquinas. Toca cada parte una vez, cuenta y elige cuántas hay. El círculo tiene un borde curvo, sin lados rectos.",
        "shape_patterns": "Un patrón repite una regla. Mira las piezas, encuentra lo que se repite y completa el hueco. Si lo indica la consigna, también importa el color.",
        "find_shape": "Comienza el safari de las formas. Escucha qué figura buscamos. Encuentra todas las que son iguales por su forma, aunque cambien de color, tamaño o posición.",
        "build_pattern": "El telar necesita sus piezas. Arrastra una figura a un hueco, o toca la figura y después el hueco. Completa todos siguiendo la misma regla.",
        "count_sides": "La llama recorre el contorno. Toca cada lado o cada esquina según la consigna. No cuentes una parte dos veces. Después elige la cantidad.",
        "quick_challenge": "Vuela con la llama. Lee o escucha el reto. Puedes tocar la nube de tu respuesta para que el globo viaje hasta ella. También puedes usar los controles para volar. No se pierden vidas al equivocarse.",
        "help": "Escucha lo que pide el reto. Las figuras se arrastran a los huecos. Los cuerpos se giran deslizando el dedo. Los lados y las esquinas se tocan una vez para contarlos. Puedes pedir una pista y volver a intentar.",
        "retry": "Observa otra vez. Mira la forma, no solo el color. Puedes pedir una pista y volver a intentarlo.",
        "correct": "¡Lo descubriste! La forma y sus partes te ayudaron a pensar.",
        "model_done": "¡Ejemplo completado! Ahora tienes cinco retos parecidos para practicar a tu ritmo.",
        "done": "¡Misión completada! Tu progreso quedó guardado en este dispositivo.",
        "resume": "Continuamos tu misión. Se conservaron tus respuestas y las piezas que ya habías colocado.",
        "pause": "El viaje y el reloj esperan. Continúa cuando estés listo.",
        "finish": "¡Buen trabajo! Mira tu resultado. Puedes volver a jugar para mejorar tu mejor marca.",
        "rotate": "Desliza sobre el cuerpo para girarlo, o toca una flecha de giro. Ahora puedes observarlo desde otro lado.",
        "square_rectangle": "Un cuadrado también es un rectángulo: tiene cuatro esquinas rectas y sus cuatro lados son iguales. En estos retos, cuando pedimos un rectángulo alargado, buscamos uno con dos lados largos y dos cortos.",
    }
    for key, text in guides.items(): clips[key] = {"file": key + ".mp3", "text": text}

    def narrate(q):
        q["audio"] = VOICE + q["id"] + ".mp3"
        clips[q["id"]] = {"file": q["id"] + ".mp3", "text": q["text"]}
        return q

    def lesson(topic, tier, title, aim, model, questions):
        lid = f"{topic}_{tier}"
        model["id"] = lid + "_model"
        if model["kind"] == "solid": model["text"] = "Gira el cuerpo para verlo desde otro lado. Después elige su nombre. " + model["fact"]
        for i, q in enumerate(questions):
            q["id"] = f"{lid}_q{i+1}"
        lessons.append({"id": lid, "topic": topic, "tier": tier, "title": title, "aim": aim,
                        "model": narrate(model), "questions": [narrate(q) for q in questions]})

    flat_specs = [
        ("Curvas y esquinas", "Distingue el borde curvo del círculo de los lados rectos.", ["circle", "triangle", "circle", "square", "circle"]),
        ("Tres lados: triángulos", "Reconoce un triángulo por sus tres lados, aunque gire.", ["triangle", "triangle", "triangle", "triangle", "triangle"]),
        ("Cuadrados y rectángulos", "Mira los lados y las cuatro esquinas rectas, no solo la posición.", ["square", "rectangle", "square", "rectangle", "square"]),
        ("Cinco y seis lados", "Reconoce pentágonos y hexágonos contando sus lados.", ["pentagon", "hexagon", "pentagon", "hexagon", "pentagon"]),
        ("La forma sigue siendo la misma", "Girar, cambiar el tamaño o el color no cambia la figura.", ["square", "triangle", "rectangle", "pentagon", "hexagon"]),
    ]
    for tier, (title, aim, shapes) in enumerate(flat_specs, 1):
        qs = [plane(shape, f"flat_{tier}_{i}", angle=[0, 35, 90, 160, 240][i], property_prompt=i % 2 == 1) for i, shape in enumerate(shapes)]
        lesson("flat_shapes", tier, title, aim, plane(shapes[0], "example", 25), qs)

    solid_specs = [
        ("Un cubo para explorar", "Gira el cubo y descubre sus seis caras cuadradas.", "cube"),
        ("La esfera y su superficie", "Una esfera es curva: no tiene caras planas ni esquinas.", "sphere"),
        ("Dos bases: el cilindro", "Observa sus dos bases circulares y su superficie curva.", "cylinder"),
        ("Una base y una punta", "El cono tiene una base circular y una punta.", "cone"),
        ("Cuerpos en nuestro mundo", "Relaciona objetos cotidianos con los cuerpos a los que se parecen.", "sphere"),
    ]
    for tier, (title, aim, shape) in enumerate(solid_specs, 1):
        shapes = [shape] * 5 if tier < 5 else ["cube", "sphere", "cylinder", "cone", "cube"]
        qs = [solid(s, f"solid_{tier}_{i}", object_match=i % 2 == 1 or tier == 5) for i, s in enumerate(shapes)]
        lesson("solid_shapes", tier, title, aim, solid(shape, "example"), qs)

    count_specs = [
        ("Seguimos los lados", "Cada lado recto se cuenta una sola vez.", [("triangle", "sides")] * 5),
        ("Tocamos las esquinas", "Un vértice es una esquina: toca cada una una vez.", [("triangle", "vertices")] * 5),
        ("Cuatro, aunque la figura gire", "Cuadrados y rectángulos tienen cuatro lados y cuatro vértices.", [("square", "sides"), ("rectangle", "vertices"), ("square", "vertices"), ("rectangle", "sides"), ("square", "sides")]),
        ("Contornos de cinco y seis", "Recorre pentágonos y hexágonos sin saltarte partes.", [("pentagon", "sides"), ("hexagon", "vertices"), ("pentagon", "vertices"), ("hexagon", "sides"), ("pentagon", "sides")]),
        ("Recto o curvo", "El círculo no es un polígono: su borde es curvo y no tiene lados rectos.", [("circle", "sides"), ("triangle", "vertices"), ("circle", "sides"), ("square", "sides"), ("hexagon", "vertices")]),
    ]
    for tier, (title, aim, pairs) in enumerate(count_specs, 1):
        qs = [count(s, part, f"count_{tier}_{i}", i * 33) for i, (s, part) in enumerate(pairs)]
        lesson("sides_vertices", tier, title, aim, count(*pairs[0], "example", 15), qs)

    pattern_specs = [
        ("Una y otra vez", "Reconoce una regla de dos figuras que alternan.", ["circle:red", "triangle:blue"], False),
        ("Dos iguales y una distinta", "Busca el grupo completo que se repite.", ["square:gold", "square:gold", "circle:blue"], False),
        ("Tres figuras en una regla", "Mantén el mismo orden en cada grupo.", ["circle:red", "square:blue", "triangle:gold"], False),
        ("Un hueco en medio", "La regla también vale antes y después del hueco.", ["pentagon:green", "hexagon:violet"], False),
        ("Forma y color", "En esta misión se repiten la forma y el color.", ["circle:red", "circle:blue"], True),
    ]
    for tier, (title, aim, unit, colors) in enumerate(pattern_specs, 1):
        length = len(unit) * 3
        qs = [pattern(unit, f"pattern_{tier}_{i}", [pos], color_matters=colors) for i, pos in enumerate([length - 1, 2, length - 2, 1, length - 3])]
        lesson("shape_patterns", tier, title, aim, pattern(unit, "example", [len(unit) * 2 - 1], repeats=2, color_matters=colors), qs)

    games = {"find_shape": [], "build_pattern": [], "count_sides": []}
    for difficulty in [1, 2]:
        shapes = PLANES[:4] if difficulty == 1 else PLANES
        for i in range(8):
            target = shapes[i % len(shapes)]
            qid = f"find_{difficulty}_{i+1}"
            items = []
            target_slots = {(i + offset) % 8 for offset in [0, 3, 6]}
            for j in range(8):
                shape = target if j in target_slots else [s for s in shapes if s != target][j % (len(shapes) - 1)]
                items.append({"shape": shape, "color": COLORS[(i + j) % 6], "angle": (i * 29 + j * 43) % 360, "scale": [0.8, 1.0, 0.9][j % 3]})
            q = {"id": qid, "kind": "find", "target": target, "items": items, "difficulty": difficulty,
                 "result": sorted(target_slots), "text": f"Encuentra los tres {NAMES[target] + 's' if target != 'rectangle' else 'rectángulos alargados'}. Aunque cambien de posición, busca su forma."}
            games["find_shape"].append(narrate(q))
            unit = pattern_specs[i % (3 if difficulty == 1 else 5)][2]
            colors = difficulty == 2 and i % 5 == 4
            length = len(unit) * 3
            q = pattern(unit, f"weave_{difficulty}_{i+1}", [length - 2, length - 1] if difficulty == 1 else [1, length - 3, length - 1], color_matters=colors)
            q["difficulty"] = difficulty
            games["build_pattern"].append(narrate(q))
            shape = ["triangle", "square", "rectangle"][(i + difficulty) % 3] if difficulty == 1 else PLANES[1:][i % 5]
            q = count(shape, "sides" if i % 2 == 0 else "vertices", f"outline_{difficulty}_{i+1}", i * 37)
            q["difficulty"] = difficulty
            games["count_sides"].append(narrate(q))
    games["quick_challenge"] = []
    for item in lessons:
        for original in item["questions"]:
            q = copy.deepcopy(original)
            q["id"] = "sky_" + original["id"]
            q["difficulty"] = 2 if q.get("shape") in ["pentagon", "hexagon"] or q.get("color_matters", False) else 1
            if q["kind"] == "plane":
                q["text"] = f"Lleva el globo al {NAMES[q['shape']]}. Toca su nube o usa los controles para volar."
            elif q["kind"] == "solid":
                q["text"] = "¿A qué cuerpo se parece el objeto? Toca su nube para viajar." if q["object_match"] else "Lleva el globo hasta " + q["spoken_name"] + ". Toca su nube para viajar."
            elif q["kind"] == "count":
                q["text"] = f"¿Cuántos {'lados rectos' if q['part'] == 'sides' else 'vértices o esquinas'} tiene esta figura? Toca la nube con tu respuesta."
            elif q["kind"] == "pattern":
                q["kind"] = "sky_pattern"
                q["result"] = q["result"][0]
                q["text"] = "¿Qué figura falta en el patrón? " + ("Mira la forma y el color. " if q["color_matters"] else "Mira la forma. ") + "Toca su nube para viajar."
            games["quick_challenge"].append(narrate(q))
    data = {"version": 1, "lessons": lessons, "games": games}
    folder = ROOT / "data/geometry"
    folder.mkdir(parents=True, exist_ok=True)
    for name, content in [("activities.json", data), ("voice_lines.json", {"clips": clips})]:
        (folder / name).write_text(json.dumps(content, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Built 20 geometry missions, 100 challenges, 48 game rounds, 100 flight challenges and {len(clips)} local voice lines.")


if __name__ == "__main__":
    build()
