"""Build the compatible story catalog from the reviewed eight-scene source."""
import copy
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
source = json.loads((ROOT / "data/stories/library.json").read_text(encoding="utf-8"))
catalog_path = ROOT / "assets/data/cuentos.json"
old = json.loads(catalog_path.read_text(encoding="utf-8"))
old_by_id = {story["id"]: story for story in old["stories"]}
stories = []
assert len(source["stories"]) == 16
assert set(old_by_id) == {story["id"] for story in source["stories"]}, "Preserve all 16 existing story IDs"
for index, original in enumerate(source["stories"]):
    story = copy.deepcopy(original)
    assert len(story["pages"]) == 8 and len(story["questions"]) == 4
    story["cover"] = old_by_id[story["id"]]["cover"]
    story["atlas"] = f"res://assets/stories/{story['id']}.png"
    story["order"] = [0, 2, 5, 7]
    for page_index, page in enumerate(story["pages"]):
        page["image"] = story["atlas"]
        page["audio"] = f"res://assets/audio/stories/{story['id']}/page_{page_index:02d}.mp3"
        page["timings"] = page["audio"].removesuffix(".mp3") + ".timing.json"
        page["narration"] = page["text"] + " " + page["speech"]
    for question_index, question in enumerate(story["questions"]):
        offset = (index + question_index) % 3
        options = question["choices"]
        assert len(set(options)) == 3 and question["answer"] in options
        question["choices"] = options[offset:] + options[:offset]
        question["audio"] = f"res://assets/audio/stories/{story['id']}/question_{question_index:02d}.mp3"
    stories.append(story)
catalog_path.write_text(json.dumps({"version": 2, "adaptation": source["adaptation"], "stories": stories}, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
print("Prepared 16 stories, 128 illustrated scenes, 64 questions and four modes per story.")
