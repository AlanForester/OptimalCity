FactoryBot.define do
  factory :weather_datum do
    city { ['Москва', 'Санкт-Петербург'].sample }
    temperature { rand(-30.0..40.0).round(1) }
    timestamp { Time.current }
  end
end
