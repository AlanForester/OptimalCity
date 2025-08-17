require 'rails_helper'

RSpec.describe WeatherDatum, type: :model do
  describe 'валидации' do
    it 'должен быть валидным с корректными данными' do
      weather_data = WeatherDatum.new(
        city: 'Москва',
        temperature: 22.5,
        timestamp: Time.current
      )
      expect(weather_data).to be_valid
    end

    it 'должен требовать город' do
      weather_data = WeatherDatum.new(temperature: 22.5, timestamp: Time.current)
      weather_data.valid?
      expect(weather_data.errors[:city]).to include("can't be blank")
    end

    it 'должен требовать температуру' do
      weather_data = WeatherDatum.new(city: 'Москва', timestamp: Time.current)
      weather_data.valid?
      expect(weather_data.errors[:temperature]).to include("can't be blank")
    end

    it 'должен требовать временную метку' do
      weather_data = WeatherDatum.new(city: 'Москва', temperature: 22.5)
      weather_data.valid?
      expect(weather_data.errors[:timestamp]).to include("can't be blank")
    end

    it 'должен предотвращать дублирование записей' do
      timestamp = Time.current
      WeatherDatum.create!(city: 'Москва', temperature: 22.5, timestamp: timestamp)
      
      duplicate = WeatherDatum.new(city: 'Москва', temperature: 23.0, timestamp: timestamp)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:timestamp]).to include("запись для этого города в это время уже существует")
    end
  end

  describe 'области видимости' do
    let!(:moscow_data) { WeatherDatum.create!(city: 'Москва', temperature: 22.5, timestamp: 1.hour.ago) }
    let!(:spb_data) { WeatherDatum.create!(city: 'Санкт-Петербург', temperature: 18.3, timestamp: 1.hour.ago) }

    it 'должен возвращать данные для конкретного города' do
      moscow_records = WeatherDatum.where(city: 'Москва')
      expect(moscow_records).to include(moscow_data)
      expect(moscow_records).not_to include(spb_data)
    end

    it 'должен возвращать данные за текущий день' do
      today_records = WeatherDatum.where('timestamp >= ?', Time.current.beginning_of_day)
      expect(today_records).to include(moscow_data, spb_data)
    end
  end
end
