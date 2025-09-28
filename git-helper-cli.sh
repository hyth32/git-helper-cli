#! /bin/bash

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Текущая папка не является git репозиторием"
    exit 1
fi

build_fzf() {
    local header="$1"
    local prompt="$2"
    local extra_opts="$3"

    shift 3
    printf "%s\n" "$@" | fzf \
        --height 10 \
        --border \
        --reverse \
        --header-first \
        --header="$header" \
        --prompt="$prompt" \
        --marker="*" \
        $extra_opts
}

build_fzf_menu() {
    local header="$1"
    local prompt="$2"
    shift 2
    build_fzf "$header" "$prompt" "" "$@"
}

build_fzf_menu_multiselect() {
    local header="$1"
    local prompt="$2"
    shift 2
    build_fzf "$header" "$prompt" "--multi" "$@"
}

add_back_button_to_list() {
    echo "Назад"$'\n'"$@"
}

print_current_branch() {
    current_branch=$(git symbolic-ref --short HEAD)
    echo "Текущая ветка: $current_branch"
}

return_to_menu() {
    read -p "Нажмите Enter, чтобы вернуться в меню"
}

show_main_menu() {
    actions=("Выбор ветки" "Список коммитов" "Сравнение коммитов" "Коммит" "Выход")
    build_fzf_menu \
        "$(print_current_branch)" \
        "Выберите действие: " \
        "${actions[@]}"
}

change_branch() {
    branches=$(add_back_button_to_list "$(git branch --all)")

    selected_branch=$(
        build_fzf_menu \
        "Выбор ветки" \
        "Выберите ветку: " \
        "$branches"
    )
    
    if [ -z "$selected_branch" ] || [ "$selected_branch" == "Назад" ]; then
        return
    else
        selected_branch=$(echo "$selected_branch" | sed 's/^ *//' | sed 's/^\* //')
        git checkout "$selected_branch"
        echo "Переключено на ветку: $selected_branch"
    fi
}

get_commits() {
    git log --oneline
}

show_commits() {
    commits=$(add_back_button_to_list "$(get_commits)")

    selected_commit=$(
        build_fzf_menu \
            "Список коммитов (доступен скролл стрелками)" \
            "Выберите коммит" \
            "$commits"
    )

    if [ -z "$selected_commit" ] || [ "$selected_commit" == "Назад" ]; then
        return
    else
        show_commit_details "$selected_commit"
    fi
}

show_commit_details() {
    commit="$1"
    commit_hash=$(get_commit_hash "$commit")
    clear
    echo "Детали коммита $commit_hash:"
    git show --stat --color=always "$commit_hash" | less -R
}

get_commit_hash() {
    echo "$1" | awk '{print $1}'
}

commit_changes() {
    if git diff --cached --quiet && git diff --quiet; then
        echo "Нет изменений для коммита"
        return_to_menu
        return
    fi

    print_current_branch
    git add .

    echo "Введите сообщение для коммита (оставьте пустым для отмены):"
    read commit_message

    if [ -z "$commit_message" ]; then
        git reset
        echo "Коммит отменен"
        return_to_menu
        return
    fi

    git commit -m "$commit_message"

    actions=("Да" "Нет")
    selected_action=$(
        build_fzf_menu \
            "Запушить коммит?" \
            "Выберите:" \
            "${actions[@]}"
    )

    if [ "$selected_action" == "Да" ]; then
        git push
        echo "Коммит запушен"
    else
        echo "Коммит создан локально"
    fi

    return_to_menu
}

diff_commits() {
    commits=$(add_back_button_to_list "$(get_commits)")

    selected_commit=$(
        build_fzf_menu_multiselect \
            "Сравнение коммитов" \
            "Выберите два коммита" \
            "$commits"
    )

    if [ -z "${selected_commit:-}" ]; then
        return
    fi

    mapfile -t selected_array <<< "$selected_commit"

    filtered=()
    for line in "${selected_array[@]}"; do
        [[ "$line" != "Назад" ]] && filtered+=("$line")
    done

    case ${#filtered[@]} in
        0) return ;;
        1) show_commit_details "${filtered[0]}" ;;
        2)
            first_commit=$(get_commit_hash "${filtered[0]}")
            second_commit=$(get_commit_hash "${filtered[1]}")
            git diff "$first_commit" "$second_commit" | less -R
            ;;
        *) 
            echo "Нужно выбрать максимум два коммита"
            return_to_menu
            ;;
    esac

    return_to_menu
}

while true; do
    choice=$(show_main_menu)

    if [ -z "$choice" ]; then
        echo "Выход"
        exit 0
    fi

    case "$choice" in
        "Выбор ветки") change_branch ;;
        "Список коммитов") show_commits ;;
        "Сравнение коммитов") diff_commits ;;
        "Коммит") commit_changes ;;
        "Выход") echo "Выход"; exit 0 ;;
        *) echo "Неверный выбор" ;;
    esac
done
