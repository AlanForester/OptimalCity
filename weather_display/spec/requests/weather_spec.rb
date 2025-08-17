require 'rails_helper'

RSpec.describe "Weather", type: :request do
  describe "GET /" do
    it "возвращает успешный ответ" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "отображает заголовок страницы" do
      get root_path
      expect(response.body).to include("Прогноз погоды")
    end

    it "отображает города Москва и Санкт-Петербург" do
      get root_path
      expect(response.body).to include("Москва")
      expect(response.body).to include("Санкт-Петербург")
    end
  end

  describe "GET /weather/index" do
    it "возвращает успешный ответ" do
      get weather_index_path
      expect(response).to have_http_status(:success)
    end
  end
end
