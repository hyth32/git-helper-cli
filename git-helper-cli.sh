#! /bin/bash

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Текущая папка не является git репозиторием"
    exit 1
fi

current_branch=$(git symbolic-ref --short HEAD)

show_main_menu() {
    actions=("Выбор ветки" "Последние коммиты" "Коммит" "Выход")
    printf "%s\n" "${actions[@]}" | fzf --height 10 --border \
        --reverse \
        --header-first \
        --header="Текущая ветка: $current_branch" \
        --prompt="Выберите действие: "
}

choose_branch() {
    branches=$(git branch --all)
    branches="Назад"$'\n'"$branches"
    
    selected_branch=$(echo "$branches" | fzf --height 15 --border \
        --reverse \
        --header-first \
        --header="Выбор ветки" \
        --prompt="Выберите ветку: ")
    
    if [ -z "$selected_branch" ] || [ "$selected_branch" == "Назад" ]; then
        break
    else
        selected_branch=$(echo "$selected_branch" | sed 's/^ *//' | sed 's/^\* //')
        git checkout "$selected_branch" >/dev/null 2>&1
        current_branch="$selected_branch"
        echo "Переключено на ветку: $selected_branch"
    fi
}

while true; do
    choice=$(show_main_menu)
    case "$choice" in
        "Выбор ветки") choose_branch ;;
        "Последние коммиты") echo "Здесь будет список последних коммитов" ;;
        "Коммит") echo "Здесь будет логика коммита"; read -p "Нажмите Enter, чтобы вернуться в меню" ;;
        "Выход") echo "Выход"; exit 0 ;;
        *) echo "Неверный выбор" ;;
    esac
done
