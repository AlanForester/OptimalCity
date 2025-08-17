#!/bin/bash

echo "Initializing production database..."

# Ждем подключения к базе данных
until bundle exec rails db:version; do
  echo "Waiting for database connection..."
  sleep 2
done

# Создаем базу данных если не существует
bundle exec rails db:create

# Запускаем миграции
bundle exec rails db:migrate

echo "Production database initialized successfully!"
