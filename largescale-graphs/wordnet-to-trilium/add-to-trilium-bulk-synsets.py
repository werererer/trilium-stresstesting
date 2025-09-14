#!/usr/bin/env python3
# add-to-trilium-bulk-synsets.py
# pip install trilium-py python-dotenv tqdm

import argparse
import os
import csv
import json
from pathlib import Path
from html import escape
from typing import Optional, List, Tuple

# ---------- caching ----------
_children_cache: dict[str, dict[str, str]] = {}


try:
    from dotenv import load_dotenv  # type: ignore
    load_dotenv()
except Exception:
    pass

from tqdm import tqdm
from trilium_py.client import ETAPI

# ---------- constants ----------
COUNTER_DIGITS = 4          # number of digits in the path (depth)
COUNTER_BASE = 100          # max per digit
STATE_FILE = Path("import_state.json")

# ---------- utils ----------
def normalize_text(s: str) -> str:
    return s.replace("_", " ").strip()

def load_counter() -> List[int]:
    if STATE_FILE.exists():
        try:
            return json.loads(STATE_FILE.read_text())
        except Exception:
            pass
    return [0] * COUNTER_DIGITS

def save_counter(path: List[int]) -> None:
    tmp_file = STATE_FILE.with_suffix(".tmp")
    with open(tmp_file, "w", encoding="utf-8") as f:
        json.dump(path, f)
    os.replace(tmp_file, STATE_FILE)  # ✅ atomic swap

# ---------- ETAPI helpers ----------
def etapi(server_url: str, token: Optional[str], password: Optional[str]) -> ETAPI:
    if token:
        return ETAPI(server_url, token)
    if not password:
        raise SystemExit("Provide --token or --password, or set ETAPI_TOKEN in your environment.")
    ea = ETAPI(server_url)
    _token = ea.login(password)
    print(f"[info] logged in, token: {_token}")
    return ea

def make_definition_table(definition: str) -> str:
    return (
        '<figure class="table" style="width:100%;">'
        '<table class="ck-table-resized">'
        "<colgroup>"
        '<col style="width:20%;">'
        '<col style="width:80%;">'
        "</colgroup>"
        "<tbody>"
        f"<tr><td>Definition</td><td>{escape(definition)}</td></tr>"
        "</tbody></table></figure>"
    )

def create_note(
    ea: ETAPI,
    parent_id: str,
    title: str,
    content: str,
    lemmas: List[str],
) -> str:
    res = ea.create_note(parentNoteId=parent_id, title=normalize_text(title), type="text", content=content)
    note_id = res["note"]["noteId"]

    # add lemma labels
    for lemma in lemmas:
        ea.create_attribute(
            noteId=note_id, type="label", name="lemma", value=normalize_text(lemma), isInheritable=False
        )

    return note_id

def append_definition(ea: ETAPI, note_id: str, definition: str, lemmas: List[str]) -> None:
    current = ea.get_note_content(note_id) or ""
    new_content = current + "\n" + make_definition_table(definition)
    ea.update_note_content(note_id, new_content)

    note = ea.get_note(noteId=note_id)
    existing = {(a["name"], normalize_text(a["value"])) for a in note.get("attributes", [])}

    for lemma in lemmas:
        norm = normalize_text(lemma)
        if ("lemma", norm) not in existing:
            ea.create_attribute(noteId=note_id, type="label", name="lemma", value=norm, isInheritable=False)

def find_note_with_lemma(ea: ETAPI, word: str, lemmas: List[str]) -> Optional[str]:
    res = ea.search_note(search=f"note.title =* '{normalize_text(word)}'", fastSearch=False, limit=10)

    for r in res.get("results", []):
        title = normalize_text(r.get("title", ""))
        base = title.split("+", 1)[0].strip()

        if base.lower() != normalize_text(word).lower():
            continue

        note_id = r["noteId"]
        note = ea.get_note(noteId=note_id)
        attrs = note.get("attributes", [])
        lemma_tags = [normalize_text(a["value"]) for a in attrs if a["name"] == "lemma"]

        if not lemma_tags:
            return note_id

        if any(normalize_text(l).lower() in (lt.lower() for lt in lemma_tags) for l in lemmas):
            return note_id

    return None

# ---------- hierarchy helpers ----------
def get_children(ea: ETAPI, parent_id: str) -> dict[str, str]:
    """Return {title: noteId} for direct children of parent_id, with caching."""
    if parent_id not in _children_cache:
        res = ea.traverse_note_tree(parent_id, depth=2)
        subnotes = res[1:] if res else []
        _children_cache[parent_id] = {child["title"]: child["noteId"] for child in subnotes}
    return _children_cache[parent_id]

def ensure_dir(ea: ETAPI, parent_id: str, idx: int) -> str:
    """Ensure a child folder with given idx exists under parent_id."""
    title = f"{idx:02d}"
    children = get_children(ea, parent_id)

    if title in children:
        return children[title]

    # create new note if missing
    note_id = create_note(ea, parent_id, title, "<p></p>", [])
    # update cache
    _children_cache.setdefault(parent_id, {})[title] = note_id
    return note_id

def ensure_path(ea: ETAPI, root_id: str, indices: List[int]) -> str:
    parent = root_id
    for idx in indices:
        parent = ensure_dir(ea, parent, idx)
    return parent

def increment_path(path: List[int]) -> List[int]:
    carry = 1
    for i in reversed(range(len(path))):
        if carry == 0:
            break
        path[i] += carry
        if path[i] == COUNTER_BASE:
            path[i] = 0
            carry = 1
        else:
            carry = 0

    if carry == 1:
        raise Exception(f"Path overflow: more than {COUNTER_BASE}^{len(path)} entries.")

    return path

# ---------- CSV helpers ----------
def load_entries(input_file: str):
    rows = []
    entries: List[Tuple[str, List[str], str, List[str], int]] = []
    with open(input_file, encoding="utf-8", newline="") as f:
        reader = csv.DictReader(f)
        required = {"word", "synset", "definition", "synonyms"}
        if not required.issubset(reader.fieldnames or []):
            raise SystemExit(f"CSV must have columns: {', '.join(required)}")

        for i, row in enumerate(reader):
            word = normalize_text(row["word"])
            synset = row["synset"]
            definition = row["definition"].strip()

            raw_lemmas = [
                normalize_text(s) for s in row.get("synonyms", "").replace(",", ";").split(";") if s.strip()
            ]
            lemmas = [lemma for lemma in raw_lemmas if lemma != word]

            imported = row.get("imported", "").strip()

            if not word or not definition:
                continue

            rows.append(row)
            if imported.lower() in ("yes", "1", "true", "done"):
                continue

            entries.append((word, synset, definition, lemmas, i))
    return rows, entries

def save_entries(output_file: Path, rows, imported_indices):
    fieldnames = rows[0].keys() if rows else ["word", "synset", "definition", "synonyms", "imported"]
    tmp_file = output_file.with_suffix(output_file.suffix + ".tmp")

    with open(tmp_file, "w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        for i, row in enumerate(rows):
            if i in imported_indices:
                row["imported"] = "yes"
            writer.writerow(row)

    # ✅ Atomic replacement: either old CSV stays or new one is fully swapped in
    os.replace(tmp_file, output_file)

# ---------- import logic ----------
def place_entries(ea: ETAPI, parent_id: str, entries, rows, output_file: Path) -> set[int]:
    current_path = load_counter()
    imported_indices = set()

    for word, synset, definition, lemmas, row_idx in tqdm(entries, desc="📥 Importing", unit="word"):
        existing_id = find_note_with_lemma(ea, word, lemmas)
        if existing_id:
            append_definition(ea, existing_id, definition, lemmas)
        else:
            folder_id = ensure_path(ea, parent_id, current_path[:-1])
            title = normalize_text(word if not lemmas else f"{word} + {sorted(lemmas)[0]}")
            content = make_definition_table(definition)
            create_note(ea, folder_id, title, content, lemmas)
            current_path = increment_path(current_path)
            save_counter(current_path)

        imported_indices.add(row_idx)
        rows[row_idx]["imported"] = "yes"
        save_entries(output_file, rows, imported_indices)

    return imported_indices

# ---------- main ----------
def main():
    env_server = os.getenv("SERVER_URL") or os.getenv("TRILIUM_SERVER_URL")
    env_token = os.getenv("ETAPI_TOKEN") or os.getenv("TRILIUM_ETAPI_TOKEN")

    ap = argparse.ArgumentParser(description="Bulk import words/definitions with lemma tags.")
    ap.add_argument("--server-url", default=env_server, help="Trilium server URL")
    ap.add_argument("--token", default=env_token, help="ETAPI token")
    ap.add_argument("--password", help="Account password")
    ap.add_argument("--parent-id", default="xRQS4Z3jvVG6", help="Parent note under which to create the import tree")
    ap.add_argument("--input", required=True, help="Path to a CSV file with word,synset,definition,synonyms[,imported]")
    args = ap.parse_args()

    if not args.server_url:
        raise SystemExit("Missing server URL (set SERVER_URL in env or use --server-url).")
    if not (args.token or args.password):
        raise SystemExit("Missing credentials (set ETAPI_TOKEN in env or use --token/--password).")

    ea = etapi(args.server_url, args.token, args.password)

    top_id = args.parent_id
    print(f"📂 using existing parent folder (id={top_id})")

    rows, entries = load_entries(args.input)
    print(f"⚙️ importing {len(entries)} new entries...")

    output_file = Path(args.input)
    imported_indices = place_entries(ea, top_id, entries, rows, output_file)

    print(f"✅ import complete. Updated file written to {output_file}")

if __name__ == "__main__":
    main()
