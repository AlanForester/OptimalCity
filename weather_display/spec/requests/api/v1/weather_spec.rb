require 'rails_helper'

RSpec.describe 'Api::V1::Weather', type: :request do
  describe 'GET /api/v1/weather' do
    before do
      # Создаем тестовые данные
      @moscow_data = WeatherDatum.create!(
        city: 'Москва',
        temperature: 22.5,
        timestamp: Time.current - 1.hour
      )
      
      @spb_data = WeatherDatum.create!(
        city: 'Санкт-Петербург',
        temperature: 18.3,
        timestamp: Time.current - 1.hour
      )
    end

    it 'возвращает данные о погоде для указанной таймзоны' do
      get '/api/v1/weather', params: { timezone: 'Europe/Moscow' }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['timezone']).to eq('Europe/Moscow')
      expect(json['data']).to have_key('Москва')
      expect(json['data']).to have_key('Санкт-Петербург')
      expect(json['data']['Москва']).to be_an(Array)
      expect(json['data']['Санкт-Петербург']).to be_an(Array)
    end

    it 'работает с UTC таймзоной' do
      get '/api/v1/weather', params: { timezone: 'UTC' }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['timezone']).to eq('UTC')
    end

    it 'работает с американской таймзоной' do
      get '/api/v1/weather', params: { timezone: 'America/New_York' }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['timezone']).to eq('America/New_York')
    end

    it 'возвращает пустые массивы когда нет данных' do
      WeatherDatum.destroy_all
      
      get '/api/v1/weather', params: { timezone: 'Europe/Moscow' }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['data']['Москва']).to eq([])
      expect(json['data']['Санкт-Петербург']).to eq([])
    end

    it 'обрабатывает некорректную таймзону' do
      get '/api/v1/weather', params: { timezone: 'Invalid/Timezone' }
      
      expect(response).to have_http_status(:success)
      json = JSON.parse(response.body)
      
      expect(json['success']).to be true
      expect(json['timezone']).to eq('Invalid/Timezone')
    end
  end
end
