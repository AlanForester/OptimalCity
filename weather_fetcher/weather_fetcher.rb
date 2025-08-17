require 'nats/client'
require 'httparty'
require 'json'
require 'yaml'
require 'active_support/time'

class WeatherFetcher
  def initialize(config_path = 'config.yml')
    @config = load_config(config_path)
    @nats = NATS.connect(ENV.fetch('NATS_URL', 'nats://localhost:4222'))
    @cities = @config['cities'] || ['Москва', 'Санкт-Петербург']
    @interval = @config['interval'] || 1200
  end

  def start
    puts "Сервис получения данных о погоде запущен"
    puts "Города: #{@cities.join(', ')}"
    puts "Интервал обновления: каждые 20 минут"
    puts "Текущее время UTC: #{Time.now.utc.strftime('%H:%M:%S')}"
    
    # Проверяем, нужно ли ждать до следующего интервала
    current_time = Time.now.utc
    current_minutes = current_time.min
    
    if current_minutes % 20 == 0
      puts "Текущее время делится на 20 минут, начинаем сразу"
      fetch_and_publish_weather
    else
      puts "Ожидание до следующего 20-минутного интервала..."
      sleep_until_next_interval
    end
    
    loop do
      fetch_and_publish_weather
      sleep_until_next_interval
    end
  rescue Interrupt
    puts "\nЗавершение работы сервиса..."
    @nats.close
  end

  private

  def load_config(config_path)
    if File.exist?(config_path)
      config = YAML.load_file(config_path)
      # Обрабатываем ERB синтаксис для api_key
      if config['api_key'].is_a?(String) && config['api_key'].include?('ENV')
        config['api_key'] = ENV['WEATHER_API_KEY']
      end
      config
    else
      {
        'cities' => ['Москва', 'Санкт-Петербург'],
        'interval' => 1200,
        'api_key' => ENV['WEATHER_API_KEY']
      }
    end
  end

  def fetch_and_publish_weather
    @cities.each do |city|
      temperature = fetch_temperature(city)
      if temperature
        publish_weather_data(city, temperature)
        puts "#{Time.now.utc.strftime('%H:%M:%S')} UTC - #{city}: #{temperature}°C"
      else
        puts "#{Time.now.utc.strftime('%H:%M:%S')} UTC - Ошибка получения данных для #{city}"
      end
    end
  end

  def fetch_temperature(city)
    case city
    when 'Москва'
      fetch_moscow_temperature
    when 'Санкт-Петербург'
      fetch_spb_temperature
    else
      fetch_generic_temperature(city)
    end
  rescue => e
    puts "Ошибка при получении данных для #{city}: #{e.message}"
    nil
  end

  def fetch_moscow_temperature
    response = HTTParty.get('https://api.openweathermap.org/data/2.5/weather', 
                           query: {
                             q: 'Moscow,RU',
                             appid: @config['api_key'],
                             units: 'metric'
                           })
    
    if response.success?
      data = JSON.parse(response.body)
      data['main']['temp']
    else
      nil
    end
  end

  def fetch_spb_temperature
    response = HTTParty.get('https://api.openweathermap.org/data/2.5/weather', 
                           query: {
                             q: 'Saint Petersburg,RU',
                             appid: @config['api_key'],
                             units: 'metric'
                           })
    
    if response.success?
      data = JSON.parse(response.body)
      data['main']['temp']
    else
      nil
    end
  end

  def fetch_generic_temperature(city)
    response = HTTParty.get('https://api.openweathermap.org/data/2.5/weather', 
                           query: {
                             q: "#{city},RU",
                             appid: @config['api_key'],
                             units: 'metric'
                           })
    
    if response.success?
      data = JSON.parse(response.body)
      data['main']['temp']
    else
      nil
    end
  end

  def publish_weather_data(city, temperature)
    # Округляем время до ближайших 20 минут в UTC
    utc_time = Time.now.utc
    rounded_time = round_to_20_minutes(utc_time)
    
    # Проверяем, что время делится на 20 минут
    if rounded_time.min % 20 != 0
      puts "#{Time.now.strftime('%H:%M:%S')} - Пропускаем запись для #{city}: время #{rounded_time.strftime('%H:%M')} не делится на 20 минут"
      return
    end
    
    data = {
      city: city,
      temperature: temperature,
      timestamp: rounded_time.iso8601
    }.to_json

    @nats.publish('weather.data', data)
  end

  def round_to_20_minutes(time)
    minutes = time.min
    rounded_minutes = (minutes / 20) * 20
    Time.utc(time.year, time.month, time.day, time.hour, rounded_minutes, 0)
  end

  def sleep_until_next_interval
    utc_time = Time.now.utc
    next_interval = get_next_20_minute_interval(utc_time)
    sleep_seconds = (next_interval - utc_time).to_i
    
    puts "Текущее время: #{utc_time.strftime('%H:%M:%S')} UTC"
    puts "Следующее обновление в #{next_interval.strftime('%H:%M:%S')} UTC (через #{sleep_seconds} секунд)"
    
    # Если нужно ждать больше часа, показываем прогресс
    if sleep_seconds > 3600
      puts "Ожидание более часа, показываем прогресс каждые 5 минут..."
      remaining = sleep_seconds
      while remaining > 0
        sleep_time = [remaining, 300].min  # максимум 5 минут
        sleep sleep_time
        remaining -= sleep_time
        puts "Осталось ждать: #{remaining} секунд (#{(remaining / 60.0).round(1)} минут)"
      end
    else
      sleep sleep_seconds
    end
  end

  def get_next_20_minute_interval(time)
    minutes = time.min
    next_minutes = ((minutes / 20) + 1) * 20
    
    if next_minutes >= 60
      next_hour = time.hour + 1
      next_minutes = 0
      if next_hour >= 24
        next_day = time.day + 1
        next_hour = 0
        Time.utc(time.year, time.month, next_day, next_hour, next_minutes, 0)
      else
        Time.utc(time.year, time.month, time.day, next_hour, next_minutes, 0)
      end
    else
      Time.utc(time.year, time.month, time.day, time.hour, next_minutes, 0)
    end
  end
end

if __FILE__ == $0
  fetcher = WeatherFetcher.new
  fetcher.start
end
