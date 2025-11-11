require 'rails_helper'

RSpec.describe "VacationRequests", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/vacation_requests/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/vacation_requests/show"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /new" do
    it "returns http success" do
      get "/vacation_requests/new"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /create" do
    it "returns http success" do
      get "/vacation_requests/create"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /destroy" do
    it "returns http success" do
      get "/vacation_requests/destroy"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /pending" do
    it "returns http success" do
      get "/vacation_requests/pending"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /history" do
    it "returns http success" do
      get "/vacation_requests/history"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /approve" do
    it "returns http success" do
      get "/vacation_requests/approve"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /reject" do
    it "returns http success" do
      get "/vacation_requests/reject"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /mark_as_taken" do
    it "returns http success" do
      get "/vacation_requests/mark_as_taken"
      expect(response).to have_http_status(:success)
    end
  end

end
