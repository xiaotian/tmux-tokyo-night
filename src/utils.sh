#!/usr/bin/env bash

function get_tmux_option() {
	local option=$1
	local default_value=$2
	local -r option_value=$(tmux show-option -gqv "$option")

	if [ -z "$option_value" ]; then
		echo "$default_value"
	else
		echo "$option_value"
	fi
}

function generate_left_side_string() {

	session_icon=$(get_tmux_option "@theme_session_icon" " ")
	hostname_icon=$(get_tmux_option "@theme_hostname_icon" "󰒋 ")
	show_hostname=$(get_tmux_option "@theme_show_hostname" "0")
	left_separator=$(get_tmux_option "@theme_left_separator" "")
	transparent=$(get_tmux_option "@theme_transparent_status_bar" "false")

	local hostname_part=""
	local session_separator_start=""
	if [ "$show_hostname" = "1" ]; then
		if [ "$transparent" = "true" ]; then
			local hostname_separator="#[bg=default,fg=${PALLETE[blue0]}]${left_separator:?}#[none]"
			local left_separator_inverse=$(get_tmux_option "@theme_transparent_left_separator_inverse" "")
			session_separator_start="#[bg=default]#{?client_prefix,#[fg=${PALLETE[yellow]}],#[fg=${PALLETE[green]}]}${left_separator_inverse}#{?client_prefix,#[bg=${PALLETE[yellow]}],#[bg=${PALLETE[green]}]}#[fg=${PALLETE[bg_highlight]}]"
		else
			local hostname_separator="#[bg=${PALLETE[bg_highlight]},fg=${PALLETE[blue0]}]${left_separator:?}#[none]"
			session_separator_start="#{?client_prefix,#[bg=${PALLETE[yellow]}],#[bg=${PALLETE[green]}]}#[fg=${PALLETE[bg_highlight]}]${left_separator:?}#[none]"
		fi
		hostname_part="#[fg=${PALLETE[white]},bold,bg=${PALLETE[blue0]}] ${hostname_icon}#h ${hostname_separator}"
	else
		session_separator_start=""
	fi

	if [ "$transparent" = "true" ]; then
		local separator_end="#[bg=default]#{?client_prefix,#[fg=${PALLETE[yellow]}],#[fg=${PALLETE[green]}]}${left_separator:?}#[none]"
	else
		local separator_end="#[bg=${PALLETE[bg_highlight]}]#{?client_prefix,#[fg=${PALLETE[yellow]}],#[fg=${PALLETE[green]}]}${left_separator:?}#[none]"
	fi

	echo "${hostname_part}${session_separator_start}#[fg=${PALLETE[fg_gutter]},bold]#{?client_prefix,#[bg=${PALLETE[yellow]}],#[bg=${PALLETE[green]}]} ${session_icon} #S ${separator_end}"
}

function generate_inactive_window_string() {

	inactive_window_icon=$(get_tmux_option "@theme_plugin_inactive_window_icon" " ")
	zoomed_window_icon=$(get_tmux_option "@theme_plugin_zoomed_window_icon" " ")
	left_separator=$(get_tmux_option "@theme_left_separator" "")
	transparent=$(get_tmux_option "@theme_transparent_status_bar" "false")
	inactive_window_title=$(get_tmux_option "@theme_inactive_window_title" "#W ")

	if [ "$transparent" = "true" ]; then
		left_separator_inverse=$(get_tmux_option "@theme_transparent_left_separator_inverse" "")

		local separator_start="#[bg=default,fg=${PALLETE['dark5']}]${left_separator_inverse}#[bg=${PALLETE['dark5']},fg=${PALLETE['bg_highlight']}]"
		local separator_internal="#[bg=${PALLETE['dark3']},fg=${PALLETE['dark5']}]${left_separator:?}#[none]"
		local separator_end="#[bg=default,fg=${PALLETE['dark3']}]${left_separator:?}#[none]"
	else
		local separator_start="#[bg=${PALLETE['dark5']},fg=${PALLETE['bg_highlight']}]${left_separator:?}#[none]"
		local separator_internal="#[bg=${PALLETE['dark3']},fg=${PALLETE['dark5']}]${left_separator:?}#[none]"
		local separator_end="#[bg=${PALLETE[bg_highlight]},fg=${PALLETE['dark3']}]${left_separator:?}#[none]"
	fi

	echo "${separator_start}#[fg=${PALLETE[white]}]#I${separator_internal}#[fg=${PALLETE[white]}] #{?window_zoomed_flag,$zoomed_window_icon,$inactive_window_icon}${inactive_window_title}${separator_end}"
}

function generate_active_window_string() {

	active_window_icon=$(get_tmux_option "@theme_plugin_active_window_icon" " ")
	zoomed_window_icon=$(get_tmux_option "@theme_plugin_zoomed_window_icon" " ")
	pane_synchronized_icon=$(get_tmux_option "@theme_plugin_pane_synchronized_icon" "✵")
	left_separator=$(get_tmux_option "@theme_left_separator" "")
	transparent=$(get_tmux_option "@theme_transparent_status_bar" "false")
	active_window_title=$(get_tmux_option "@theme_active_window_title" "#W ")

	if [ "$transparent" = "true" ]; then
		left_separator_inverse=$(get_tmux_option "@theme_transparent_left_separator_inverse" "")
		
		separator_start="#[bg=default,fg=${PALLETE['magenta']}]${left_separator_inverse}#[bg=${PALLETE['magenta']},fg=${PALLETE['bg_highlight']}]"
		separator_internal="#[bg=${PALLETE['purple']},fg=${PALLETE['magenta']}]${left_separator:?}#[none]"
		separator_end="#[bg=default,fg=${PALLETE['purple']}]${left_separator:?}#[none]"
	else
		separator_start="#[bg=${PALLETE['magenta']},fg=${PALLETE['bg_highlight']}]${left_separator:?}#[none]"
		separator_internal="#[bg=${PALLETE['purple']},fg=${PALLETE['magenta']}]${left_separator:?}#[none]"
		separator_end="#[bg=${PALLETE[bg_highlight]},fg=${PALLETE['purple']}]${left_separator:?}#[none]"
	fi

	echo "${separator_start}#[fg=${PALLETE[white]}]#I${separator_internal}#[fg=${PALLETE[white]}] #{?window_zoomed_flag,$zoomed_window_icon,$active_window_icon}${active_window_title}#{?pane_synchronized,$pane_synchronized_icon,}${separator_end}#[none]"
}
