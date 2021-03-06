store_init () {
    jv_debug "Refreshing store database..."
    export store_json="$(curl -s http://domotiquefacile.fr/jarvis/all.json)"
    #export store_json_lower="$(echo "$store_json" | tr '[:upper:]' '[:lower:]')"
    jv_debug "Store database updated"
}

store_get_nb_plugins () {
    echo "$store_json" | jq '.nodes | length'
}

store_get_categories () {
    echo "$store_json" | jq -r '.nodes | unique_by(.node.category) | sort_by(.node.category) | .[].node.category'
}

store_list_plugins () { # $1:category, $2:(optional)order_by
    # build jq filter based on category selected
    local filter=".nodes"
    if [ "$1" != "All" ]; then
        filter="$filter | map(select(.node.category==\"$1\"))"
    fi
    if [ -n "$2" ]; then
        filter="$filter | sort_by(.node.\"$2\") | reverse"
    fi
    filter="$filter | .[].node.title"
    echo "$store_json" | jq -r "$filter"
}

store_search_plugins () { # $1:space separated search terms
    # TODO test not available in jq 1.4 (raspbian)
    #echo "$store_json" | jq -r ".nodes[] | select(.node.body | test(\"$1\"; \"i\")) | .node.title"
    echo "$store_json" | jq -r ".nodes[] | select(.node.title | contains(\"$1\")) | .node.title" #TODO create new keyword field on plugins?
}

store_get_field () { # $1:plugin_name, $2:field_name
    echo "$store_json" | jq -r ".nodes | map(select(.node.title==\"$1\")) | .[0].node.$2"
}

store_get_field_by_repo () {
    echo "$store_json" | jq -r ".nodes | map(select(.node.repo==\"$1\")) | .[0].node.$2"
}

store_display_readme () { # $1:plugin_url
    local plugin_readme_url="${plugin_url/github.com/raw.githubusercontent.com}/master/README.md"
    clear
    curl -s "$plugin_readme_url" | sed '/<!--/,/-->/d' & # strip comments
   jv_spinner $!
    press_enter_to_continue
}

store_install_plugin () { # $1:plugin_url
    local plugin_name="${1##*/}" #extract repo_name from url
    cd plugins
    git clone "$1.git" #https://github.com/alexylem/jarvis.git
    if [[ $? -eq 0 ]]; then
        cd "$plugin_name"
        ./install.sh
        if [[ -s "config.sh" ]]; then
            dialog_msg "This plugin needs configuration"
            editor "config.sh"
        fi
        cd ../
        dialog_msg "Installation Complete"
    else
        jv_error "An error has occured"
        press_enter_to_continue
    fi
    cd ../
    
}
