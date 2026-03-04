require "faraday"
require "json"

module API
  class Client
    BASE_URL = "https://telemetry.betterstack.com"

    def initialize(auth_token: nil, session_cookie: nil)
      @auth_token = auth_token
      @session_cookie = session_cookie
    end

    def get(path)
      response = connection.get(path) do |req|
        req.headers["Authorization"] = "Bearer #{@auth_token}" if @auth_token
        req.headers["Cookie"] = @session_cookie if @session_cookie
      end
      raise "HTTP #{response.status} from #{path}" unless response.success?
      JSON.parse(response.body)
    end

    private

    def connection
      @connection ||= Faraday.new(BASE_URL)
    end
  end
end
