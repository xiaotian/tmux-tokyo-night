#!/usr/bin/env bash
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=src/utils.sh
. "$ROOT_DIR/../utils.sh"

# shellcheck disable=SC2005
plugin_weather_icon=$(get_tmux_option "@theme_plugin_weather_icon" " ")
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
    local file_time=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null)
    local age=$((current_time - file_time))
    
    if [[ $age -lt $ttl ]]; then
        return 0
    else
        return 1
    fi
}

function get_location() {
    if [[ -n "$plugin_weather_location" ]]; then
        echo "$plugin_weather_location"
        return
    fi
    
    if is_cache_valid "$LOCATION_CACHE" "$LOCATION_CACHE_TTL"; then
        cat "$LOCATION_CACHE"
    else
        local location=$(curl -s http://ip-api.com/json | jq -r '"\(.city), \(.country)"' 2> /dev/null)
        if [[ -n "$location" && "$location" != "null, null" ]]; then
            echo "$location" > "$LOCATION_CACHE"
            echo "$location"
        elif [[ -f "$LOCATION_CACHE" ]]; then
            # If API fails, use stale cache as fallback
            cat "$LOCATION_CACHE"
        fi
    fi
}

function get_weather() {
    local location="$1"
    
    if is_cache_valid "$WEATHER_CACHE" "$WEATHER_CACHE_TTL"; then
        cat "$WEATHER_CACHE"
    else
        local weather=$(curl -sL "wttr.in/${location// /%20}?${plugin_weather_unit:+$plugin_weather_unit&}format=${plugin_weather_format_string}" 2> /dev/null)
        if [[ -n "$weather" ]]; then
            echo "$weather" > "$WEATHER_CACHE"
            echo "$weather"
        elif [[ -f "$WEATHER_CACHE" ]]; then
            # If API fails, use stale cache as fallback
            cat "$WEATHER_CACHE"
        fi
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
