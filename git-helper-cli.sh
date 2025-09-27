#! /bin/bash

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Текущая папка не является git репозиторием"
    exit 1
fi

build_fzf_menu() {
    local header="$1"
    local prompt="$2"
    shift 2
    printf "%s\n" "$@" | fzf \
        --height 10 \
        --border \
        --reverse \
        --header-first \
        --header="$header" \
        --prompt="$prompt"
}

current_branch=$(git symbolic-ref --short HEAD)

show_main_menu() {
    actions=("Выбор ветки" "Список коммитов" "Коммит" "Выход")
    build_fzf_menu \
        "Текущая ветка: $current_branch" \
        "Выберите действие: " \
        "${actions[@]}"
}

change_branch() {
    branches=$(git branch --all)
    branches="Назад"$'\n'"$branches"

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
        git checkout "$selected_branch" >/dev/null 2>&1
        current_branch="$selected_branch"
        echo "Переключено на ветку: $selected_branch"
    fi
}

show_commits() {
    commits=$(git log --oneline)
    commits="Назад"$'\n'"$commits"

    selected_commit=$(
        build_fzf_menu \
            "Список коммитов (доступен скролл стрелками)" \
            "Выберите коммит" \
            "$commits"
    )

    if [ -z "$selected_commit" ] || [ "$selected_commit" == "Назад" ]; then
        return
    else
        commit_hash=$(echo "$selected_commit" | awk '{print $1}')
        clear
        echo "Детали коммита $commit_hash:"
        git show --stat --color=always "$commit_hash" | less -R
    fi
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
        "Коммит") echo "Здесь будет логика коммита"; read -p "Нажмите Enter, чтобы вернуться в меню" ;;
        "Выход") echo "Выход"; exit 0 ;;
        *) echo "Неверный выбор" ;;
    esac
done
