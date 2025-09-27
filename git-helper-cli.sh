#! /bin/bash

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Текущая папка не является git репозиторием"
    exit 1
fi

while true; do
  current_branch=$(git symbolic-ref --short HEAD)

  actions=("Выбор ветки" "Последние коммиты" "Коммит" "Выход")

  choice=$(printf "%s\n" "${actions[@]}" \
        | fzf --height 10 --border \
              --reverse \
              --header-first \
              --header="Текущая ветка: $current_branch" \
              --prompt="Выберите действие: " \
  )

  case "$choice" in
    "Выбор ветки")
        while true; do
            branches=$(git branch --all)
            branches="Назад"$'\n'"$branches"

            selected_branch=$(echo "$branches" | fzf --height 15 --border --reverse --prompt="Выберите ветку: ")

            if [ "$selected_branch" == "Назад" ] || [ -z "$selected_branch" ]; then
                break
            else
                selected_branch=$(echo "$selected_branch" | sed 's/^ *//' | sed 's/^\* //')
                echo "Переключение на ветку $selected_branch"
                git checkout "$selected_branch"
                break
            fi
        done
        ;;
    "Последние коммиты")
        echo "Здесь будет список последних коммитов"
        ;;
    "Коммит")
        echo "Здесь будет логика коммита"
        read -p "Нажмите Enter, чтобы вернуться в меню"
        ;;
    "Выход")
        echo "Выход"
        exit 0
        ;;
    *)
        echo "Неверный выбор"
        ;;
  esac
done

