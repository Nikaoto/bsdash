require "faraday"
require "json"

module API
  class Auth
    JWT_URL = "https://telemetry.betterstack.com"

    def initialize(session_cookie:, team_id:)
      @session_cookie = session_cookie
      @team_id = team_id
    end

    def fetch_jwt
      response = Faraday.new(JWT_URL).get("/team/#{@team_id}/tail/cloud-jwt-token") do |req|
        req.headers["Cookie"] = "_session=" << @session_cookie
      end
      raise "Failed to fetch JWT: HTTP #{response.status}" unless response.success?

      body = response.body.strip
      # Response may be plain token string or JSON wrapper
      if body.start_with?("{")
        data = JSON.parse(body)
        data["token"] || data["jwt"] || data.values.first
      else
        body
      end
    end
  end
end
