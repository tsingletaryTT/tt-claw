#!/usr/bin/env python3
"""
Index TT documentation into Hermes memory system
"""
import os
import shutil
from pathlib import Path

HERMES_MEMORY = Path.home() / ".hermes" / "memories"
TT_DOCS = [
    ("/home/ttuser/code/tt-vscode-toolkit/content/lessons", "lessons"),
    ("/home/ttuser/tt-metal/METALIUM_GUIDE.md", "metalium"),
    ("/home/ttuser/code/tt-inference-server/docs", "inference"),
    ("/home/ttuser/tt-claw/CLAUDE.md", "tt-claw"),
]

def index_docs():
    """Copy TT docs to Hermes memory for searchability"""
    tt_memory = HERMES_MEMORY / "tt-docs"
    tt_memory.mkdir(parents=True, exist_ok=True)

    for source, name in TT_DOCS:
        source_path = Path(source)
        dest = tt_memory / name

        if source_path.is_file():
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source_path, dest.with_suffix('.md'))
            print(f"✅ Indexed: {source}")
        elif source_path.is_dir():
            if dest.exists():
                shutil.rmtree(dest)
            shutil.copytree(source_path, dest)
            file_count = len(list(dest.glob('**/*.md')))
            print(f"✅ Indexed: {source} ({file_count} markdown files)")

if __name__ == "__main__":
    index_docs()
    print(f"\n🎓 TT documentation indexed to {HERMES_MEMORY / 'tt-docs'}/")
    print(f"   Total size: {sum(f.stat().st_size for f in (HERMES_MEMORY / 'tt-docs').rglob('*') if f.is_file()) / 1024 / 1024:.1f} MB")
