#!/bin/bash
# Checks the translations in Resources/<lang>.lproj:
#   - every .strings file is valid (with plutil, on macOS)
#   - every language has the same files and keys as en.lproj, and no extra keys
# Usage: bash scripts/check-strings.sh   (also run by build.sh)
#
# 检查 Resources/<lang>.lproj 里的翻译：
#   - 每个 .strings 文件格式正确（macOS 上用 plutil 检查）
#   - 每种语言的文件和键都与 en.lproj 一致，没有多余的键
# 用法：bash scripts/check-strings.sh（build.sh 也会运行它）
set -euo pipefail
cd "$(dirname "$0")/.."
export LC_ALL=C

BASE="Resources/en.lproj"
failed=0

# Prints the keys of a .strings file, one per line, sorted.
# 按行输出 .strings 文件里的键（已排序）。
keys() {
    grep -oE '^[[:space:]]*"([^"\\]|\\.)+"[[:space:]]*=' "$1" \
        | sed -E 's/^[[:space:]]*"(.*)"[[:space:]]*=$/\1/' | sort
}

if command -v plutil >/dev/null; then
    for file in Resources/*.lproj/*.strings; do
        plutil -lint -s "$file" || failed=1
    done
fi

for dir in Resources/*.lproj; do
    [[ "$dir" == "$BASE" ]] && continue
    for base_file in "$BASE"/*.strings; do
        file="$dir/$(basename "$base_file")"
        if [[ ! -f "$file" ]]; then
            echo "error: $file is missing" >&2
            failed=1
            continue
        fi
        missing="$(comm -23 <(keys "$base_file") <(keys "$file"))"
        extra="$(comm -13 <(keys "$base_file") <(keys "$file"))"
        [[ -n "$missing" ]] && { echo "error: $file is missing keys:" >&2; sed 's/^/  /' <<<"$missing" >&2; failed=1; }
        [[ -n "$extra" ]] && { echo "error: $file has keys not in $BASE:" >&2; sed 's/^/  /' <<<"$extra" >&2; failed=1; }
    done
done

if [[ $failed -eq 0 ]]; then
    langs=(Resources/*.lproj)
    langs=("${langs[@]#Resources/}")
    echo "Strings OK: ${langs[*]}"
fi
exit $failed
