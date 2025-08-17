#!/bin/bash

echo "🚀 Initializing production database..."

# Ждем подключения к базе данных с таймаутом
echo "⏳ Waiting for database connection..."
for i in {1..30}; do
  echo "⏳ Attempt $i/30: Testing database connection..."
  
  # Пробуем подключиться с явным указанием хоста
  if bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
    echo "✅ Database connection established!"
    break
  else
    echo "⏳ Database not ready, waiting..."
    sleep 2
  fi
done

# Проверяем, что подключение установлено
if ! bundle exec rails runner "ActiveRecord::Base.connection.execute('SELECT 1')" > /dev/null 2>&1; then
  echo "❌ Failed to connect to database after 60 seconds"
  echo "🔍 Debugging connection..."
  echo "DATABASE_URL: $DATABASE_URL"
  echo "RAILS_ENV: $RAILS_ENV"
  echo "Testing direct connection..."
  bundle exec rails runner "puts ActiveRecord::Base.connection_config"
  exit 1
fi

# Создаем базу данных если не существует
echo "📦 Creating database if not exists..."
bundle exec rails db:create

# Запускаем миграции
echo "🔄 Running database migrations..."
bundle exec rails db:migrate

echo "✅ Production database initialized successfully!"
exit 0
