require 'spec_helper'
require_relative '../weather_fetcher'

RSpec.describe WeatherFetcher do
  let(:config_path) { 'spec/fixtures/test_config.yml' }
  let(:fetcher) { WeatherFetcher.new(config_path) }

  before do
    allow(NATS).to receive(:connect).and_return(double('nats'))
  end

  describe '#initialize' do
    it 'загружает конфигурацию из файла' do
      expect(fetcher.instance_vari able_get(:@cities)).to eq(['Москва', 'Санкт-Петербург'])
      expect(fetcher.instance_variable_get(:@interval)).to eq(1200)
    end

    it 'использует значения по умолчанию если файл не найден' do
      fetcher = WeatherFetcher.new('несуществующий_файл.yml')
      expect(fetcher.instance_variable_get(:@cities)).to eq(['Москва', 'Санкт-Петербург'])
    end
  end

  describe '#fetch_temperature' do
    it 'вызывает соответствующий метод для Москвы' do
      expect(fetcher).to receive(:fetch_moscow_temperature)
      fetcher.send(:fetch_temperature, 'Москва')
    end

    it 'вызывает соответствующий метод для Санкт-Петербурга' do
      expect(fetcher).to receive(:fetch_spb_temperature)
      fetcher.send(:fetch_temperature, 'Санкт-Петербург')
    end

    it 'вызывает общий метод для других городов' do
      expect(fetcher).to receive(:fetch_generic_temperature).with('Екатеринбург')
      fetcher.send(:fetch_temperature, 'Екатеринбург')
    end
  end

  describe '#publish_weather_data' do
    it 'публикует данные в NATS' do
      nats = fetcher.instance_variable_get(:@nats)
      city = 'Москва'
      temperature = 15.5

      expect(nats).to receive(:publish) do |topic, data|
        expect(topic).to eq('weather.data')
        parsed_data = JSON.parse(data)
        expect(parsed_data['city']).to eq(city)
        expect(parsed_data['temperature']).to eq(temperature)
        expect(parsed_data['timestamp']).to be_a(String)
      end

      fetcher.send(:publish_weather_data, city, temperature)
    end
  end
end
