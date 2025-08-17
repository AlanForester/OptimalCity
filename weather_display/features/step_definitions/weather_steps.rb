# language: en

Given('I am on the home page') do
  visit root_path
end

Then('I should see the heading {string}') do |title|
  expect(page).to have_content(title)
end

Then('I should see a section for the city {string}') do |city|
  expect(page).to have_content(city)
end

Given('the database has weather information for Moscow') do
  WeatherDatum.create!(
    city: 'Moscow',
    temperature: 15.5,
    timestamp: Time.current
  )
end

Then('I should see the temperature for Moscow') do
  expect(page).to have_content('15.5°C')
end

Then('I should see the measurement time') do
  expect(page).to have_content(Time.current.strftime('%H:%M'))
end

Given('the database has no weather information') do
  WeatherDatum.destroy_all
end

Then('I should see the message {string}') do |message|
  expect(page).to have_content(message)
end
