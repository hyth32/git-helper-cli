#! /bin/bash

if ! git rev-parse --is-inside-work-tree &>/dev/null; then
  echo "Текущая папка не является git репозиторием"
  exit 1
fi

while true; do
  choice=$(echo -e "Выбор ветки\nПоследние коммиты\nКоммит\nВыход" | fzf --height 10 --border --layout=reverse-list --prompt="Выберите действие: ")

  case "$choice" in
    "Выбор ветки")
        branch=$(git branch --all | sed 's/^[ *]*//' | fzf --height 10 --border --layout=reverse-list --prompt="Выберите ветку: ")
        if [ -n "$branch" ]; then
          echo "Выбранная ветка: $branch"
        fi
        read -p "Нажмите Enter, чтобы вернуться в меню"
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

