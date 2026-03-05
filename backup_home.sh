#!/bin/bash

#  Параметры
SOURCE="/home/admivm/"
DEST="/tmp/backup"
LOG_DIR="/var/log/backup"               # директория для хранения логов
LOG_SUCCESS="$LOG_DIR/backup_success.log"
LOG_ERROR="$LOG_DIR/backup_error.log"
TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
TAG="BACKUP_SCRIPT"

# Подготовка
# Создаём директорию для логов (Если её нет)
mkdir -p "$LOG_DIR"

# Временный фаил для захвата  вывода rsync
TMP_OUT=$(mktemp)

#  Выполнение резервного копирования
rsync -a --delete --exclude='.*' --checksum "$SOURCE" "$DEST" > >(tee "$TMP_OUT") 2>&1 # Использовал комманду tee для вывода в терминал и записи в $TMP_OUT. 2>&1 Для перенаправления вывод с ошибками в стандартный
RSYNC_EXIT=$?

# Обработка результата
if [ $RSYNC_EXIT -eq 0 ]; then
    # Запись в success.log и системный лог
    echo "$TIMESTAMP: Резервное копирование успешно завершено" >> "$LOG_SUCCESS"
    logger -t "$TAG" "Резервное копирование успешно завершено"
else
    # Запись в error.log (с выводом rsync) и системный лог
    {
        echo "$TIMESTAMP: ОШИБКА при выполнении резервного копирования (код $RSYNC_EXIT)"
        echo "--- Вывод rsync ---"
        cat "$TMP_OUT"
        echo "-------------------"
    } >> "$LOG_ERROR"
    logger -t "$TAG" "ОШИБКА при выполнении резервного копирования (код $RSYNC_EXIT)"
fi

# Очистка временного фаила
rm -f "$TMP_OUT"


