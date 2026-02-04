#!/bin/bash

# read JSON input from stdin
input=$(cat)

# extract data
model_name=$(echo "$input" | jq -r '.model.display_name // "Unknown"')
current_dir=$(echo "$input" | jq -r '.workspace.current_dir // "~"')
dir_basename=$(basename "$current_dir")

# calculate context usage percentage
usage=$(echo "$input" | jq '.context_window.current_usage')
if [ "$usage" != "null" ]; then
    current=$(echo "$usage" | jq '.input_tokens + .cache_creation_input_tokens + .cache_read_input_tokens')
    size=$(echo "$input" | jq '.context_window.context_window_size')
    pct=$((current * 100 / size))
    context_str=$(printf '%d%%' "$pct")
else
    context_str="0%"
fi

# get git branch (skip optional locks to avoid hangs)
cd "$current_dir" 2>/dev/null
git_branch=""
if git rev-parse --git-dir > /dev/null 2>&1; then
    branch=$(git -c core.useBuiltinFSMonitor=false rev-parse --abbrev-ref HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        git_branch=$(printf ' \033[38;5;208m(\033[38;5;214m%s\033[38;5;208m)\033[0m' "$branch")
    fi
fi

# Anthropic-themed format with warm orange/amber tones
# 208 = orange, 214 = golden/amber, 202 = darker orange
printf '\033[1;38;5;208m%s\033[0m%s \033[38;5;246m[%s]\033[0m \033[38;5;202m[%s]\033[0m' \
    "$dir_basename" \
    "$git_branch" \
    "$model_name" \
    "$context_str"
