#!/usr/bin/env bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=src/utils.sh
. "$ROOT_DIR/../utils.sh"

# shellcheck disable=SC2005
plugin_weather_icon=$(get_tmux_option "@theme_plugin_weather_icon" "󰖕 ")
plugin_weather_accent_color=$(get_tmux_option "@theme_plugin_weather_accent_color" "blue7")
plugin_weather_accent_color_icon=$(get_tmux_option "@theme_plugin_weather_accent_color_icon" "blue0")
plugin_weather_location=$(get_tmux_option "@theme_plugin_weather_location" "")
plugin_weather_unit=$(get_tmux_option "@theme_plugin_weather_unit" "")

export plugin_weather_icon plugin_weather_accent_color plugin_weather_accent_color_icon

plugin_weather_format_string=$(get_tmux_option "@theme_plugin_weather_format" "%t+H:%h")

# Cache configuration
CACHE_DIR="${TMPDIR:-/tmp}/tmux-tokyo-night-cache"
LOCATION_CACHE="${CACHE_DIR}/location"
WEATHER_CACHE="${CACHE_DIR}/weather"
LOCATION_CACHE_TTL=$(get_tmux_option "@theme_plugin_weather_location_cache_ttl" "$((6 * 60 * 60))")  # Default: 6 hours
WEATHER_CACHE_TTL=$(get_tmux_option "@theme_plugin_weather_cache_ttl" "$((5 * 60))")                # Default: 5 minutes

# Create cache directory if it doesn't exist
mkdir -p "$CACHE_DIR"

function is_cache_valid() {
    local cache_file="$1"
    local ttl="$2"
    
    if [[ ! -f "$cache_file" ]]; then
        return 1
    fi
    
    local current_time=$(date +%s)
    local file_time
    if [[ "$OSTYPE" == "darwin"* ]]; then
        file_time=$(stat -f %m "$cache_file")
    else
        file_time=$(stat -c %Y "$cache_file")
    fi
    local age=$((current_time - file_time))
    
    if [[ $age -lt $ttl ]]; then
        return 0
    else
        return 1
    fi
}

function update_location_cache() {
    (curl -s http://ip-api.com/json | jq -r '"\(.city), \(.country)"' 2>/dev/null > "$LOCATION_CACHE.tmp" && mv "$LOCATION_CACHE.tmp" "$LOCATION_CACHE") >/dev/null 2>&1 &
}

function update_weather_cache() {
    local location="$1"
    local unit="$2"
    local format="$3"
    (curl -sL "wttr.in/${location// /%20}?${unit:+$unit&}format=${format}" 2>/dev/null > "$WEATHER_CACHE.tmp" && mv "$WEATHER_CACHE.tmp" "$WEATHER_CACHE") >/dev/null 2>&1 &
}

function get_location() {
    if [[ -n "$plugin_weather_location" ]]; then
        echo "$plugin_weather_location"
        return
    fi
    
    # If cache exists, use it immediately (even if stale) for fast startup
    if [[ -f "$LOCATION_CACHE" ]]; then
        cat "$LOCATION_CACHE"
        # Update cache in background if expired
        if ! is_cache_valid "$LOCATION_CACHE" "$LOCATION_CACHE_TTL"; then
            update_location_cache
        fi
    else
        # No cache exists, fetch in background and return empty for now
        update_location_cache
        echo ""
    fi
}

function get_weather() {
    local location="$1"
    
    # If cache exists, use it immediately (even if stale) for fast startup
    if [[ -f "$WEATHER_CACHE" ]]; then
        cat "$WEATHER_CACHE"
        # Update cache in background if expired
        if ! is_cache_valid "$WEATHER_CACHE" "$WEATHER_CACHE_TTL"; then
            update_weather_cache "$location" "$plugin_weather_unit" "$plugin_weather_format_string"
        fi
    else
        # No cache exists, fetch in background and return placeholder
        update_weather_cache "$location" "$plugin_weather_unit" "$plugin_weather_format_string"
        echo "..."
    fi
}

function load_plugin() {
    if ! command -v jq &> /dev/null; then
        exit 1
    fi

    local location=$(get_location)
    local weather=$(get_weather "$location")
    
    echo "${weather}"
}

load_plugin
