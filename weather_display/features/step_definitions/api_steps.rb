# frozen_string_literal: true

Дано('в базе данных есть записи о погоде для {string}') do |city|
  WeatherDatum.create!(
    city: city,
    temperature: 22.5,
    timestamp: Time.current - 1.hour
  )
end

Дано('в базе данных нет записей о погоде') do
  WeatherDatum.destroy_all
end

Когда('я отправляю GET запрос на {string} с параметрами:') do |path, table|
  params = table.rows_hash
  get path, params: params
end

Тогда('ответ должен содержать статус {int}') do |status|
  expect(response).to have_http_status(status)
end

Тогда('JSON ответ должен содержать:') do |table|
  json = JSON.parse(response.body)
  table.rows_hash.each do |key, value|
    expect(json[key]).to eq(value)
  end
end

Тогда('в данных должна быть информация о {string}') do |city|
  json = JSON.parse(response.body)
  expect(json['data']).to have_key(city)
  expect(json['data'][city]).to be_an(Array)
  expect(json['data'][city]).not_to be_empty
end

Тогда('данные для {string} должны быть пустым массивом') do |city|
  json = JSON.parse(response.body)
  expect(json['data'][city]).to eq([])
end
