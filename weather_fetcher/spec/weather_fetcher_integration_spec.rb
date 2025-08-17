require 'spec_helper'

RSpec.describe WeatherFetcher do
  let(:fetcher) { WeatherFetcher.new }
  let(:mock_config) do
    {
      'cities' => ['Москва', 'Санкт-Петербург'],
      'interval' => 1200,
      'api_key' => 'test_api_key'
    }
  end

  before do
    allow(fetcher).to receive(:load_config).and_return(mock_config)
    allow(fetcher).to receive(:connect_to_nats)
  end

  describe '#initialize' do
    it 'создает экземпляр с правильными параметрами' do
      expect(fetcher.instance_variable_get(:@cities)).to eq(['Москва', 'Санкт-Петербург'])
      expect(fetcher.instance_variable_get(:@interval)).to eq(1200)
    end
  end

  describe '#round_to_20_minutes' do
    it 'округляет время до ближайших 20 минут' do
      time = Time.utc(2025, 8, 17, 10, 15, 30)
      rounded = fetcher.send(:round_to_20_minutes, time)
      expect(rounded).to eq(Time.utc(2025, 8, 17, 10, 0, 0))
    end

    it 'округляет время до 20 минут' do
      time = Time.utc(2025, 8, 17, 10, 25, 0)
      rounded = fetcher.send(:round_to_20_minutes, time)
      expect(rounded).to eq(Time.utc(2025, 8, 17, 10, 20, 0))
    end

    it 'округляет время до 40 минут' do
      time = Time.utc(2025, 8, 17, 10, 35, 0)
      rounded = fetcher.send(:round_to_20_minutes, time)
      expect(rounded).to eq(Time.utc(2025, 8, 17, 10, 20, 0))
    end
  end

  describe '#get_next_20_minute_interval' do
    it 'возвращает следующий 20-минутный интервал' do
      time = Time.utc(2025, 8, 17, 10, 15, 0)
      next_interval = fetcher.send(:get_next_20_minute_interval, time)
      expect(next_interval).to eq(Time.utc(2025, 8, 17, 10, 20, 0))
    end

    it 'переходит на следующий час' do
      time = Time.utc(2025, 8, 17, 10, 45, 0)
      next_interval = fetcher.send(:get_next_20_minute_interval, time)
      expect(next_interval).to eq(Time.utc(2025, 8, 17, 11, 0, 0))
    end

    it 'переходит на следующий день' do
      time = Time.utc(2025, 8, 17, 23, 45, 0)
      next_interval = fetcher.send(:get_next_20_minute_interval, time)
      expect(next_interval).to eq(Time.utc(2025, 8, 18, 0, 0, 0))
    end
  end

  describe '#fetch_temperature' do
    it 'вызывает правильный метод для Москвы' do
      expect(fetcher).to receive(:fetch_moscow_temperature).and_return(22.5)
      result = fetcher.send(:fetch_temperature, 'Москва')
      expect(result).to eq(22.5)
    end

    it 'вызывает правильный метод для Санкт-Петербурга' do
      expect(fetcher).to receive(:fetch_spb_temperature).and_return(18.3)
      result = fetcher.send(:fetch_temperature, 'Санкт-Петербург')
      expect(result).to eq(18.3)
    end

    it 'вызывает общий метод для других городов' do
      expect(fetcher).to receive(:fetch_generic_temperature).with('Новосибирск').and_return(15.0)
      result = fetcher.send(:fetch_temperature, 'Новосибирск')
      expect(result).to eq(15.0)
    end

    it 'возвращает nil при ошибке' do
      allow(fetcher).to receive(:fetch_moscow_temperature).and_raise(StandardError, 'API error')
      result = fetcher.send(:fetch_temperature, 'Москва')
      expect(result).to be_nil
    end
  end

  describe '#publish_weather_data' do
    let(:mock_nats) { double('nats') }

    before do
      fetcher.instance_variable_set(:@nats, mock_nats)
    end

    it 'публикует данные в NATS' do
      allow(Time).to receive(:now).and_return(Time.utc(2025, 8, 17, 10, 20, 0))
      expect(mock_nats).to receive(:publish).with('weather.data', anything)
      
      fetcher.send(:publish_weather_data, 'Москва', 22.5)
    end

    it 'пропускает запись если время не делится на 20 минут' do
      allow(Time).to receive(:now).and_return(Time.utc(2025, 8, 17, 10, 25, 0))
      expect(mock_nats).not_to receive(:publish)
      
      fetcher.send(:publish_weather_data, 'Москва', 22.5)
    end
  end
end
