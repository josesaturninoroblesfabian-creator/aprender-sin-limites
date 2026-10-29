"""Build the reviewed place-value curriculum and offline narration for Numbers."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
VOICE = "res://assets/audio/llama/numbers_activities/"
SMALL = ["cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve",
         "diez", "once", "doce", "trece", "catorce", "quince", "dieciséis", "diecisiete", "dieciocho", "diecinueve",
         "veinte", "veintiuno", "veintidós", "veintitrés", "veinticuatro", "veinticinco", "veintiséis", "veintisiete", "veintiocho", "veintinueve"]
TENS = ["", "", "veinte", "treinta", "cuarenta", "cincuenta", "sesenta", "setenta", "ochenta", "noventa"]
HUNDREDS = ["", "ciento", "doscientos", "trescientos", "cuatrocientos", "quinientos", "seiscientos", "setecientos", "ochocientos", "novecientos"]
TOPICS = ["one_digit", "two_digits", "three_digits", "four_digits"]
PLACES = ["unidad", "decena", "centena", "unidad de millar"]
PLURALS = ["unidades", "decenas", "centenas", "unidades de millar"]


def words(n):
    assert 0 <= n <= 9999
    if n < 30:
        return SMALL[n]
    if n < 100:
        return TENS[n // 10] + (" y " + SMALL[n % 10] if n % 10 else "")
    if n == 100:
        return "cien"
    if n < 1000:
        return HUNDREDS[n // 100] + (" " + words(n % 100) if n % 100 else "")
    thousands, rest = divmod(n, 1000)
    return ("mil" if thousands == 1 else words(thousands) + " mil") + (" " + words(rest) if rest else "")


def parts(n, width):
    return [n // 10 ** p % 10 for p in range(width)]


def composition(n, width):
    terms = []
    for p in reversed(range(width)):
        digit = n // 10 ** p % 10
        if not digit:
            continue
        terms.append(f"{digit} {PLACES[p] if digit == 1 else PLURALS[p]}")
    return ", ".join(terms) if terms else "cero unidades"


def question(kind, n, width, qid, **extra):
    q = {"id": qid, "kind": kind, "number": n, "width": width, **extra}
    if kind == "build":
        q.update(text=f"Forma el número {n} con las piezas.", result=n)
    elif kind == "read":
        q.update(text=f"Encuentra el número: {words(n)}.", result=n, written=words(n))
    elif kind == "place":
        p = q["place"]
        digit = n // 10 ** p % 10
        q.update(text=f"En {n}, ¿cuánto vale el {digit} de las {PLURALS[p]}?", result=digit * 10 ** p)
    elif kind == "compose":
        q.update(text=f"¿Qué número forman {composition(n, width)}?", result=n)
    elif kind == "neighbor":
        offset = q.get("offset", 1)
        q.update(text=f"¿Qué número va {'después' if offset == 1 else 'antes'} de {n}?", result=n + offset)
    elif kind == "order":
        values = q["values"]
        q.update(text="Ordena de menor a mayor: " + ", ".join(map(str, values)) + ".", result=sorted(values))
    else:
        raise ValueError(kind)
    q["audio"] = VOICE + qid + ".mp3"
    return q


# Five different learning goals per width. Values deliberately include zeros and
# boundaries; the numbers are reviewed constants, not unrestricted random sums.
UNITS = [
    (1, "Reconozco cantidades", "Cada objeto cuenta una vez. Cero significa que no hay ninguno.", "build", [0, 2, 5, 7, 9]),
    (1, "Construyo mi número", "Las unidades forman los números de una cifra.", "build", [3, 1, 6, 8, 4]),
    (1, "Lo escucho y lo encuentro", "Relaciona el nombre que escuchas con su cifra.", "read", [0, 4, 6, 8, 9]),
    (1, "Antes y después", "Avanza o retrocede un lugar en la recta.", "neighbor", [0, 3, 5, 8, 9]),
    (1, "Del menor al mayor", "Compara y coloca tres números en orden.", "order", [[3, 0, 1], [5, 2, 4], [9, 7, 8], [6, 3, 5], [8, 0, 4]]),
    (2, "Diez unidades, una decena", "Cambia diez cubitos por una barra de diez.", "build", [10, 12, 15, 18, 19]),
    (2, "Cada cifra tiene su lugar", "Una decena vale diez unidades. Las columnas cambian el valor.", "build", [23, 41, 36, 72, 89]),
    (2, "El lugar del cero", "Un cero guarda una columna vacía; no la borres.", "build", [20, 40, 60, 80, 90]),
    (2, "Leo y descompongo", "Escucha el número y descubre sus decenas y unidades.", "read", [21, 32, 48, 67, 95]),
    (2, "Vecinos de dos cifras", "Antes y después también funciona al cruzar una decena.", "neighbor", [19, 30, 49, 70, 98]),
    (3, "Diez decenas, una centena", "Cambia diez barras de diez por una placa de cien.", "build", [100, 110, 120, 150, 190]),
    (3, "Armo centenas", "Combina centenas, decenas y unidades para construir.", "build", [234, 341, 526, 672, 893]),
    (3, "Ceros que importan", "Una cifra puede valer cero sin mover las demás.", "place", [105, 208, 340, 506, 790]),
    (3, "Leo y reconstruyo", "Une el nombre, las partes y el número completo.", "compose", [125, 260, 407, 518, 936]),
    (3, "Cruzo la centena", "Observa qué cambia al avanzar o retroceder un lugar.", "neighbor", [199, 300, 499, 700, 998]),
    (4, "Diez centenas, un millar", "Diez placas de cien forman una unidad de millar.", "build", [1000, 1100, 1200, 1500, 1900]),
    (4, "Mi taller de millares", "Cada columna conserva su valor: millares, centenas, decenas y unidades.", "build", [1234, 2413, 3562, 4721, 6983]),
    (4, "Ceros entre las cifras", "Distingue 1002 de 1020. Un lugar vacío también cuenta.", "place", [1002, 2030, 4056, 7008, 8900]),
    (4, "Leo números grandes", "Escucha, descompón y reconstruye hasta cuatro cifras.", "read", [1024, 2106, 3040, 5708, 9999]),
    (4, "Vecinos y orden", "Ordena por valor posicional y cruza límites con cuidado.", "order", [[1002, 1020, 1000], [2300, 2030, 2003], [4050, 4500, 4005], [8001, 7999, 8000], [9999, 9909, 9990]]),
]


def build():
    lessons, clips = [], {}
    counters = {width: 0 for width in range(1, 5)}
    guides = {
        "one_digit": "Vamos a descubrir los números de una cifra. Cuenta, construye y escucha. Puedes empezar por cualquier misión y pedir una pista.",
        "two_digits": "Bienvenido al taller de las decenas. Diez unidades forman una decena. Mueve las cifras y observa cuánto vale cada una.",
        "three_digits": "Exploramos las centenas. Diez decenas forman cien. Coloca cada cifra en su columna y fíjate en los ceros.",
        "four_digits": "Una aventura con millares. Diez centenas forman mil. Construye, escucha y ordena sin perder el lugar de cada cifra.",
        "count_objects": "El mercado necesita un buen contador. Toca cada producto una sola vez. Cada diez marcados forman un grupo. Después elige cuántos hay. Si no hay ninguno, es cero.",
        "sequences": "Construye el puente de los números. Descubre la regla de los saltos. Arrastra la piedra correcta al hueco o tócala. La llama cruzará cuando completes la secuencia.",
        "compare": "Compara los dos números. Empieza por la columna de mayor valor. Elige mayor que, menor que o igual. El lado abierto del signo mira al número mayor.",
        "quick_challenge": "¡Todos a bordo del tren de los números! Escucha la pregunta, elige una vía y pulsa Viajar. La respuesta correcta lleva el paquete a su estación. Puedes jugar sin reloj.",
        "help": "Escucha la consigna. Para construir, arrastra las piezas a su columna o toca Añadir. Cada cubito vale uno, una barra vale diez, una placa cien y un cubo grande mil. Para quitar una pieza, toca Quitar o devuélvela a la bandeja.",
        "blocks": "Primero mira el número que queremos formar. Arrastra las piezas a la columna de su mismo color o toca Añadir. El número de abajo cambia con cada pieza. Si sobran piezas, toca Quitar. Cuando esté listo, pulsa Comprobar. Para formar cero, deja el espacio vacío.",
        "correct": "¡Bien pensado! Descubriste cómo funciona el número.",
        "retry": "Observa otra vez. Cada columna tiene un valor. Puedes mirar la pista y volver a intentarlo.",
        "done": "¡Misión completada! Tus cinco descubrimientos quedaron guardados.",
        "model_done": "¡Lo construiste! Ahora tienes cinco retos para practicar a tu ritmo.",
        "resume": "Seguimos con tu misión. Tus respuestas y tus pistas anteriores se conservaron.",
        "exchange_units": "Aquí hay diez unidades. Toca Cambiar diez piezas por una para convertirlas en una decena. La cantidad sigue siendo diez.",
        "exchange_tens": "Aquí hay diez decenas. Toca Cambiar diez piezas por una para convertirlas en una centena. La cantidad sigue siendo cien.",
        "exchange_hundreds": "Aquí hay diez centenas. Toca Cambiar diez piezas por una para convertirlas en una unidad de millar. La cantidad sigue siendo mil.",
        "count": "Toca cada producto una vez. Mira cómo viaja a la canasta. Cuando los marques todos, elige el total.",
        "sequence_done": "¡El puente está completo! La regla sirve para todos sus pasos.",
        "comparison_done": "¡Eso es! Puedes comparar primero la columna de mayor valor que cambia.",
        "train_ready": "Elige la vía de la respuesta y toca Viajar. Puedes cambiar de vía antes de salir.",
        "pause": "El viaje espera. Continúa cuando estés listo.",
        "finish": "¡Buen trabajo! Mira lo que aprendiste y vuelve a jugar para mejorar tu mejor marca.",
    }
    for key, text in guides.items():
        clips[key] = {"text": text, "file": key + ".mp3"}
    for width, title, aim, kind, values in UNITS:
        counters[width] += 1
        tier = counters[width]
        topic = TOPICS[width - 1]
        lid = f"{topic}_{tier}"
        questions = []
        for i, value in enumerate(values):
            extra = {}
            n = value[0] if kind == "order" else value
            if kind == "order": extra["values"] = value
            if kind == "neighbor": extra["offset"] = 1 if i % 2 == 0 and n < 10 ** width - 1 else -1
            if kind == "place": extra["place"] = [1, 2, 0, 2, 1][i] if width == 3 else [1, 3, 2, 0, 2][i]
            q = question(kind, n, width, f"{lid}_q{i+1}", **extra)
            questions.append(q)
            clips[q["id"]] = {"text": q["text"], "file": q["id"] + ".mp3"}
        model_n = {1: 4, 2: 23, 3: 234, 4: 1234}[width]
        if tier == 1 and width > 1: model_n = 10 ** (width - 1)
        if tier == 3 and width > 1: model_n = {2: 20, 3: 105, 4: 1002}[width]
        extra = {}
        if kind == "neighbor":
            model_n = {1: 4, 2: 19, 3: 199, 4: 1999}[width]
            extra["offset"] = 1
        elif kind == "place":
            extra["place"] = 1
        elif kind == "order":
            extra["values"] = [4, 1, 3] if width == 1 else [1234, 1024, 1204]
            model_n = extra["values"][0]
        model = question(kind, model_n, width, lid + "_model", **extra)
        if kind == "build":
            model["text"] = f"Vamos a formar {words(model_n)}. Arrastra las piezas a su columna o toca Añadir. Mira cómo cambia el número de abajo. Cuando esté listo, pulsa Comprobar."
        clips[model["id"]] = {"text": model["text"], "file": model["id"] + ".mp3"}
        intro = title + ". " + aim + " Primero descubrimos un ejemplo moviendo las piezas. Después tienes cinco retos."
        clips[lid + "_intro"] = {"text": intro, "file": lid + "_intro.mp3"}
        lessons.append({"id": lid, "topic": topic, "tier": tier, "width": width, "title": title, "aim": aim,
                        "model_number": model_n, "model": model, "exchange_place": width - 2 if tier == 1 and width > 1 else -1,
                        "questions": questions})
    sequences = []
    # Each row: first number, step, missing index. All five terms stay in range.
    sequence_specs = {
        1: [(0, 1, 2), (1, 2, 4), (9, -1, 1), (8, -2, 3), (2, 1, 4), (7, -1, 2), (0, 2, 1), (5, 1, 3)],
        2: [(18, 1, 2), (25, 5, 3), (90, -10, 1), (48, -2, 4), (31, 2, 2), (60, 5, 1), (74, -1, 3), (12, 10, 4)],
        3: [(198, 1, 2), (150, 10, 4), (900, -100, 1), (550, -10, 3), (321, 2, 2), (600, 50, 1), (704, -1, 4), (125, 5, 3)],
        4: [(1998, 1, 2), (1200, 100, 3), (9000, -1000, 1), (5050, -10, 4), (3210, 10, 2), (6000, 500, 1), (7004, -1, 3), (1250, 50, 4)],
    }
    comparisons = []
    pairs = {1: [(3, 7), (9, 2), (4, 4), (0, 5), (8, 6), (0, 0), (1, 9), (7, 7)],
             2: [(12, 21), (54, 45), (30, 30), (19, 20), (90, 89), (60, 60), (42, 47), (81, 18)],
             3: [(301, 299), (105, 150), (400, 400), (620, 602), (199, 200), (707, 770), (890, 809), (999, 999)],
             4: [(1002, 1020), (2090, 2009), (4500, 4500), (7999, 8000), (3040, 3400), (9001, 8999), (5708, 5780), (9999, 9999)]}
    for width, specs in sequence_specs.items():
        for i, (start, step, missing) in enumerate(specs):
            terms = [start + step * j for j in range(5)]
            qid = f"sequence_{width}_{i+1}"
            read = [str(n) if j != missing else "un hueco" for j, n in enumerate(terms)]
            text = "Completa la secuencia: " + ", ".join(read) + ". ¿Qué número falta?"
            sequences.append({"id": qid, "width": width, "terms": terms, "step": step, "missing": missing,
                              "result": terms[missing], "text": text, "audio": VOICE + qid + ".mp3"})
            clips[qid] = {"text": text, "file": qid + ".mp3"}
        for i, (left, right) in enumerate(pairs[width]):
            qid = f"comparison_{width}_{i+1}"
            text = f"Compara {left} con {right}. ¿El primero es mayor, menor o igual?"
            comparisons.append({"id": qid, "width": width, "left": left, "right": right,
                                "result": ">" if left > right else "<" if left < right else "=", "text": text, "audio": VOICE + qid + ".mp3"})
            clips[qid] = {"text": text, "file": qid + ".mp3"}
    folder = ROOT / "data/numbers"
    folder.mkdir(parents=True, exist_ok=True)
    data = {"version": 1, "lessons": lessons, "sequences": sequences, "comparisons": comparisons, "market_totals": [0, 4, 7, 10, 13, 18, 25, 32]}
    for name, value in [("activities.json", data), ("voice_lines.json", {"clips": clips})]:
        (folder / name).write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(f"Built {len(lessons)} lessons, 100 challenges, {len(sequences)} sequences, {len(comparisons)} comparisons and {len(clips)} voice lines.")


if __name__ == "__main__":
    build()
