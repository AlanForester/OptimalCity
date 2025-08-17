class CreateWeatherData < ActiveRecord::Migration[8.0]
  def change
    create_table :weather_data do |t|
      t.string :city
      t.decimal :temperature
      t.datetime :timestamp

      t.timestamps
    end
  end
end
