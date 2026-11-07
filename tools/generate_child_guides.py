"""Generate fictional Spanish guide voices locally with Qwen3-TTS VoiceDesign."""

import argparse
import json
from pathlib import Path

import soundfile as sf
import torch
from qwen_tts import Qwen3TTSModel


CLIPS = {
    "boy-welcome": ("boy", "¿Qué deseas aprender? Escoge el tema que quieres aprender."),
    "boy-goodbye": ("boy", "¡Aprendiste mucho hoy!"),
    "girl-welcome": ("girl", "¡Bienvenido a Aprende sin Límites!"),
    "girl-goodbye": ("girl", "¡Hasta la próxima! ¡Adiós!"),
    "dictionary-intro": ("boy", "¡Hola! Soy tu guía del Diccionario. Escribe una palabra y toca Buscar. También puedes escuchar los ejemplos: sol, árbol y casa."),
    "sol": ("boy", "Sol. Estrella que nos da luz y calor."),
    "arbol": ("boy", "Árbol. Planta grande con tronco, ramas y hojas."),
    "casa": ("boy", "Casa. Lugar donde vivimos."),
    "encyclopedia-intro": ("girl", "¡Hola! Elige un tema del libro. ¡Vamos a descubrir el mundo juntos!"),
    "history": ("girl", "Viajemos al pasado. ¿Con qué escribían las personas hace mucho tiempo?"),
    "astronomy": ("girl", "En Astronomía miramos al cielo. Piensa en la Luna: ¿por qué crees que algunas noches la vemos con una forma diferente?"),
    "biology": ("girl", "En Biología aprendemos sobre los seres vivos. Piensa en una planta: ¿qué necesita para crecer?"),
    "anatomy": ("girl", "En Anatomía exploramos el cuerpo humano. Pon la mano sobre tu pecho. ¿Puedes sentir cómo late el corazón?"),
    "zoology": ("girl", "En Zoología exploramos los animales. Piensa en dos que conozcas. ¿En qué se parecen y en qué son diferentes?"),
}
PROFILES = {
    "boy": "A fictional young boy, about 9 years old, speaking native Latin American Spanish. Light and naturally youthful boyish timbre, warm and curious. Cheerful friendly educational game guide. Clear conversational pronunciation, relaxed medium pace, expressive natural intonation and small pauses. Gentle, confident, never shouting.",
    "girl": "A fictional young girl, about 9 years old, speaking native Latin American Spanish. Clear, sweet, naturally youthful girlish timbre, warm and curious. Cheerful friendly educational game guide. Conversational pronunciation, relaxed medium pace, expressive natural intonation and small pauses. Gentle and confident, never shouting.",
}


def generate(model_path: Path, destination: Path, names: list[str]) -> None:
    destination.mkdir(parents=True, exist_ok=True)
    model = Qwen3TTSModel.from_pretrained(
        str(model_path), device_map="cuda:0", dtype=torch.bfloat16,
        attn_implementation="sdpa",
    )
    for name in names:
        character, text = CLIPS[name]
        output = destination / f"{name}.wav"
        if output.exists():
            print(f"Ya preparado: {name}", flush=True)
            continue
        torch.manual_seed(430 if character == "boy" else 720)
        with torch.inference_mode():
            waves, rate = model.generate_voice_design(
                text=text, language="Spanish", instruct=PROFILES[character],
                max_new_tokens=1800, temperature=0.75, top_p=0.9,
            )
        sf.write(output, waves[0], rate, subtype="PCM_16")
        print(f"Preparado: {name}, {len(waves[0]) / rate:.1f} s", flush=True)
    (destination / "provenance.json").write_text(
        json.dumps({"model": "Qwen/Qwen3-TTS-12Hz-1.7B-VoiceDesign", "license": "Apache-2.0",
                    "profiles": PROFILES, "clips": CLIPS, "synthetic_characters": True,
                    "seeds": {"boy": 430, "girl": 720}},
                   ensure_ascii=False, indent=2), encoding="utf-8",
    )


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--model", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--clips", nargs="+", choices=CLIPS, default=list(CLIPS))
    arguments = parser.parse_args()
    generate(arguments.model, arguments.output, arguments.clips)
