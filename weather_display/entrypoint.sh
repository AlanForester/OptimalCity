#!/bin/bash

echo "🚀 Starting weather_display application..."

# Проверяем необходимые переменные окружения
if [ -z "$RAILS_MASTER_KEY" ]; then
    echo "❌ ERROR: RAILS_MASTER_KEY не установлен"
    exit 1
fi

if [ -z "$DATABASE_URL" ]; then
    echo "❌ ERROR: DATABASE_URL не установлен"
    exit 1
fi

echo "✅ Переменные окружения проверены"

# Инициализируем базу данных
./init_production.sh

# Проверяем, что инициализация прошла успешно
if [ $? -ne 0 ]; then
    echo "❌ ERROR: Ошибка инициализации базы данных"
    exit 1
fi

# Запускаем Rails сервер
echo "🌐 Starting Rails server..."
bundle exec rails server -b 0.0.0.0
