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
      res = Faraday.new(JWT_URL).get("/team/t#{@team_id}/tail/cloud-jwt-token") do |req|
        req.headers["Cookie"] = "_session=#{@session_cookie}"
      end
      raise "Failed to fetch JWT: HTTP #{res.status}" unless res.success?

      JSON.parse(res.body)["tokens"].values.first
    end
  end
end
