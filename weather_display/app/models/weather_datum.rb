class WeatherDatum < ApplicationRecord
  validates :city, presence: true
  validates :temperature, presence: true
  validates :timestamp, presence: true
  
  # Предотвращаем дублирование записей для одного города в одно время
  validates :timestamp, uniqueness: { scope: :city, message: "запись для этого города в это время уже существует" }
end
