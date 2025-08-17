require 'nats/client'

Rails.application.config.after_initialize do
  Thread.new do
    begin
      nats_service = NatsService.new
      nats_service.subscribe_to_weather_data
      
      loop do
        sleep 1
      end
    rescue => e
      Rails.logger.error "Ошибка подключения к NATS: #{e.message}"
      sleep 5
      retry
    end
  end
end
