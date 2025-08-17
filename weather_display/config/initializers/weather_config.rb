# Загружаем конфигурацию погоды
WEATHER_CONFIG = YAML.load_file(Rails.root.join('config', 'weather.yml'), aliases: true)[Rails.env]
