require 'nats/client'

class NatsService
  def initialize
    @nats = nil
  end

  def connect
    @nats = NATS.connect(ENV.fetch('NATS_URL', 'nats://localhost:4222'))
  end

  def publish(topic, data)
    @nats.publish(topic, data)
  end

  def subscribe(topic, &block)
    @nats.subscribe(topic, &block)
  end

  def publish_weather_data(city, temperature, timestamp)
    data = {
      city: city,
      temperature: temperature,
      timestamp: timestamp
    }.to_json

    @nats.publish('weather.data', data)
  end

  def subscribe_to_weather_data
    @nats.subscribe('weather.data') do |msg|
      data = JSON.parse(msg.data)
      WeatherDatum.create!(
        city: data['city'],
        temperature: data['temperature'],
        timestamp: Time.parse(data['timestamp'])
      )
    end
  end

  def close
    @nats&.close
  end
end
