require 'rails_helper'

RSpec.describe NatsService do
  let(:nats_service) { NatsService.new }
  let(:mock_nats) { double('nats') }

  before do
    allow(NATS).to receive(:connect).and_return(mock_nats)
    allow(mock_nats).to receive(:subscribe)
    allow(mock_nats).to receive(:publish)
    allow(mock_nats).to receive(:close)
  end

  describe '#connect' do
    it 'подключается к NATS серверу' do
      expect(NATS).to receive(:connect).with('nats://nats:4222')
      nats_service.connect
    end

    it 'использует переменную окружения NATS_URL' do
      ENV['NATS_URL'] = 'nats://custom:4222'
      expect(NATS).to receive(:connect).with('nats://custom:4222')
      nats_service.connect
      ENV.delete('NATS_URL')
    end
  end

  describe '#publish' do
    before do
      nats_service.connect
    end

    it 'публикует сообщение в указанный топик' do
      data = { city: 'Москва', temperature: 22.5 }
      expect(mock_nats).to receive(:publish).with('weather.data', data)
      
      nats_service.publish('weather.data', data)
    end

    it 'конвертирует данные в JSON' do
      data = { city: 'Санкт-Петербург', temperature: 18.3 }
      expect(mock_nats).to receive(:publish).with('weather.data', data)
      
      nats_service.publish('weather.data', data)
    end
  end

  describe '#subscribe' do
    before do
      nats_service.connect
    end

    it 'подписывается на указанный топик' do
      expect(mock_nats).to receive(:subscribe).with('weather.data')
      
      nats_service.subscribe('weather.data') { |data| puts data }
    end

    it 'выполняет блок при получении сообщения' do
      received_data = nil
      allow(mock_nats).to receive(:subscribe).and_yield('{"city":"Москва","temperature":22.5}')
      
      nats_service.subscribe('weather.data') do |data|
        received_data = JSON.parse(data)
      end
      
      expect(received_data['city']).to eq('Москва')
      expect(received_data['temperature']).to eq(22.5)
    end
  end

  describe '#close' do
    before do
      nats_service.connect
    end

    it 'закрывает соединение с NATS' do
      expect(mock_nats).to receive(:close)
      nats_service.close
    end
  end

  describe 'интеграция с WeatherDatum' do
    before do
      nats_service.connect
    end

    it 'сохраняет данные о погоде при получении сообщения' do
      weather_data = {
        city: 'Москва',
        temperature: 22.5,
        timestamp: Time.current.iso8601
      }.to_json

      allow(mock_nats).to receive(:subscribe).and_yield(weather_data)
      
      expect {
        nats_service.subscribe('weather.data') do |data|
          parsed_data = JSON.parse(data)
          WeatherDatum.create!(
            city: parsed_data['city'],
            temperature: parsed_data['temperature'],
            timestamp: Time.parse(parsed_data['timestamp'])
          )
        end
      }.to change(WeatherDatum, :count).by(1)

      weather_datum = WeatherDatum.last
      expect(weather_datum.city).to eq('Москва')
      expect(weather_datum.temperature).to eq(22.5)
    end
  end
end
