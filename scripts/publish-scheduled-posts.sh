#!/usr/bin/env bash
set -euo pipefail

TODAY=$(date -u +"%Y-%m-%d")
BLOG_FILE="stickypost-blog.html"
SCHEDULED_DIR="scheduled"
PUBLISHED=0

echo "Today's date: $TODAY"
echo "Checking for scheduled posts..."
echo ""

for dir in "$SCHEDULED_DIR"/*/; do
    [ -d "$dir" ] || continue

    folder_name=$(basename "$dir")
    publish_date="${folder_name%%_*}"

    # Skip future posts (string comparison works for YYYY-MM-DD)
    if [[ "$publish_date" > "$TODAY" ]]; then
        echo "Skipping $folder_name — scheduled for $publish_date (future)"
        continue
    fi

    echo "Publishing $folder_name (scheduled: $publish_date)..."

    # Find the blog post HTML file — any .html in the folder except card.html
    post_file=$(find "$dir" -maxdepth 1 -name "*.html" -not -name "card.html" | head -1)
    card_file="$dir/card.html"

    if [ -z "$post_file" ] || [ ! -f "$card_file" ]; then
        echo "ERROR: Missing post HTML or card.html in $dir — skipping"
        continue
    fi

    # 1. Copy the blog post to root
    cp "$post_file" .

    # 2. Insert card HTML at top of blog grid (right after <div class="blog-grid">)
    card_content=$(cat "$card_file")

    # Create a temp file with the insertion
    awk -v card="$card_content" '
    /<div class="blog-grid">/ {
        print
        print ""
        print card
        next
    }
    { print }
    ' "$BLOG_FILE" > "${BLOG_FILE}.tmp"

    mv "${BLOG_FILE}.tmp" "$BLOG_FILE"

    # 3. Remove the scheduled folder
    rm -rf "$dir"

    PUBLISHED=$((PUBLISHED + 1))
    echo "Published: $(basename "$post_file")"
    echo ""
done

echo "Done. Published $PUBLISHED post(s)."

if [ "$PUBLISHED" -eq 0 ]; then
    echo "nothing_to_publish=true" >> "$GITHUB_OUTPUT"
else
    echo "nothing_to_publish=false" >> "$GITHUB_OUTPUT"
fi
