#!/usr/bin/env python3
# pip install trilium-py tqdm python-dotenv
import argparse
from pathlib import Path
from tqdm import tqdm
from trilium_py.client import ETAPI

def etapi(server_url: str, token: str, password: str) -> ETAPI:
    if token:
        return ETAPI(server_url, token)
    if not password:
        raise SystemExit("Provide --token or --password.")
    ea = ETAPI(server_url)
    _token = ea.login(password)
    print(f"[info] logged in, token: {_token}")
    return ea

def import_files(ea: ETAPI, parent_id: str, files, limit: int):
    for f in tqdm(files[:limit], desc="📤 Uploading", unit="file"):
        title = f.name
        note = ea.create_note(parentNoteId=parent_id, title=title, type="file")
        ea.upload_note_content(noteId=note["note"]["noteId"], filePath=str(f))

def main():
    ap = argparse.ArgumentParser(description="Import local assets into Trilium")
    ap.add_argument("--server-url", required=True, help="Trilium server URL")
    ap.add_argument("--token", help="ETAPI token")
    ap.add_argument("--password", help="Account password")
    ap.add_argument("--parent-id", required=True, help="Parent note ID to import under")
    ap.add_argument("--assets-dir", default="assets", help="Directory containing assets")
    ap.add_argument("--limit", type=int, default=10, help="Max number of files to upload")
    args = ap.parse_args()

    ea = etapi(args.server_url, args.token, args.password)

    root = Path(args.assets_dir)
    files = sorted([f for f in root.rglob("*") if f.is_file()])
    print(f"Found {len(files)} files, uploading {args.limit} of them...")

    import_files(ea, args.parent_id, files, args.limit)

    print("✅ Import complete.")

if __name__ == "__main__":
    main()

