require 'rails_helper'

RSpec.describe 'Weather Configuration', type: :config do
  describe 'WEATHER_CONFIG' do
    it 'загружается корректно' do
      expect(WEATHER_CONFIG).to be_a(Hash)
      expect(WEATHER_CONFIG).to have_key('cities')
      expect(WEATHER_CONFIG['cities']).to be_an(Array)
    end

    it 'содержит города из конфигурации' do
      cities = WEATHER_CONFIG['cities']
      expect(cities).to include('Москва')
      expect(cities).to include('Санкт-Петербург')
    end

    it 'города являются строками' do
      WEATHER_CONFIG['cities'].each do |city|
        expect(city).to be_a(String)
        expect(city).not_to be_empty
      end
    end
  end

  describe 'weather.yml' do
    let(:config_file) { Rails.root.join('config', 'weather.yml') }
    let(:yaml_content) { YAML.load_file(config_file, aliases: true) }

    it 'файл конфигурации существует' do
      expect(File.exist?(config_file)).to be true
    end

    it 'содержит правильную структуру' do
      expect(yaml_content).to have_key('default')
      expect(yaml_content).to have_key('development')
      expect(yaml_content).to have_key('test')
      expect(yaml_content).to have_key('production')
    end

    it 'использует YAML алиасы' do
      expect(yaml_content['development']).to eq(yaml_content['default'])
      expect(yaml_content['test']).to eq(yaml_content['default'])
      expect(yaml_content['production']).to eq(yaml_content['default'])
    end

    it 'содержит города в default секции' do
      expect(yaml_content['default']).to have_key('cities')
      expect(yaml_content['default']['cities']).to be_an(Array)
      expect(yaml_content['default']['cities']).to include('Москва')
      expect(yaml_content['default']['cities']).to include('Санкт-Петербург')
    end
  end
end
