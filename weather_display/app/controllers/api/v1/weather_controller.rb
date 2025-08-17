module Api
  module V1
    class WeatherController < ApplicationController
      def index
        timezone = params[:timezone] || 'UTC'
        
        begin
          # Получаем текущую дату в указанной таймзоне
          user_timezone = ActiveSupport::TimeZone[timezone] || ActiveSupport::TimeZone['UTC']
          user_today = Time.current.in_time_zone(user_timezone).beginning_of_day
          user_tomorrow = user_today + 1.day
          
          # Конвертируем в UTC для поиска в базе
          utc_start = user_today.utc
          utc_end = user_tomorrow.utc
          
          @cities = WEATHER_CONFIG['cities']
          @weather_data = {}
          
          @cities.each do |city|
            @weather_data[city] = WeatherDatum.where(city: city)
                                             .where('timestamp >= ? AND timestamp < ?', utc_start, utc_end)
                                             .order(timestamp: :desc)
                                             .limit(10)  # Ограничиваем количество записей для производительности
          end
          
          render json: {
            success: true,
            timezone: timezone,
            user_date: user_today.strftime('%d.%m.%Y'),
            data: @weather_data
          }
        rescue => e
          render json: {
            success: false,
            error: e.message
          }, status: :unprocessable_entity
        end
      end
    end
  end
end
