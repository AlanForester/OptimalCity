#!/bin/bash

echo "🚀 Starting weather_display application..."

# Инициализируем базу данных
./init_production.sh

# Запускаем Rails сервер
echo "🌐 Starting Rails server..."
bundle exec rails server -b 0.0.0.0
