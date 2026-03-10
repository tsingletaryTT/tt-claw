#!/bin/bash
# Install OpenClaw skills for TT-CLAW adventure games
# Copies skill wrappers to ~/.openclaw/skills/

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/../skills"
SKILLS_DEST="$HOME/.openclaw/skills"

echo "Installing TT-CLAW adventure game skills..."

# Create skills directory if it doesn't exist
mkdir -p "$SKILLS_DEST"

# Copy all skill wrappers
for skill in "$SKILLS_SOURCE"/*; do
    skill_name=$(basename "$skill")
    echo "  Installing: $skill_name"
    cp "$skill" "$SKILLS_DEST/"
    chmod +x "$SKILLS_DEST/$skill_name"
done

echo ""
echo "✓ Skills installed to: $SKILLS_DEST"
echo ""
echo "Installed skills:"
ls -1 "$SKILLS_DEST"
echo ""
echo "Test a skill:"
echo "  $SKILLS_DEST/roll-dice 3d6"
