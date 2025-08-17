-- Инициализация базы данных для weather_display
CREATE DATABASE weather_display_production;
GRANT ALL PRIVILEGES ON DATABASE weather_display_production TO weather_user;
ALTER DATABASE weather_display_production OWNER TO weather_user;
