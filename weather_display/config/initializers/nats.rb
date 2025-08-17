require 'nats/client'

Rails.application.config.after_initialize do
  Thread.new do
    begin
      puts "🔄 Инициализация подключения к NATS..."
      
      # Ждем готовности NATS
      sleep 5
      
      nats_service = NatsService.new
      nats_service.connect
      
      puts "✅ Подключение к NATS установлено"
      
      # Подписываемся на данные о погоде
      nats_service.subscribe('weather.data') do |msg|
        begin
          data = JSON.parse(msg.data)
          WeatherDatum.create!(
            city: data['city'],
            temperature: data['temperature'],
            timestamp: Time.parse(data['timestamp'])
          )
          puts "📊 Получены данные о погоде: #{data['city']} - #{data['temperature']}°C"
        rescue => e
          puts "❌ Ошибка обработки данных NATS: #{e.message}"
        end
      end
      
      puts "👂 Слушаем данные о погоде..."
      
    rescue => e
      puts "❌ Ошибка подключения к NATS: #{e.message}"
      puts "🔄 Повторная попытка через 10 секунд..."
      sleep 10
      retry
    end
  end
end
