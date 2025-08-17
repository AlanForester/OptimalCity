class WeatherController < ApplicationController
  def index
    @cities = WEATHER_CONFIG['cities']
  end
end
