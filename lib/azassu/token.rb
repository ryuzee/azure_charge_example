module Azassu
  module Token
    # Get API Token
    def self.get(application_id, client_secret, tenant_id)
      url = "https://login.microsoftonline.com/#{tenant_id}/oauth2/token?api-version=1.0"
     payload = {
        'grant_type' => 'client_credentials',
        'client_id' => application_id,
        'client_secret' => client_secret,
        'resource' => "https://management.azure.com/"
      }
      headers = {
        "Content-Type" => "application/x-www-form-urlencoded"
      }
      RestClient.post(url, payload, headers){ |response, request, result, &block|
        case response.code
        when 200
          json = JSON.parse(response)
          token = json["access_token"]
          token
        else
          false
        end
      }
    end
  end
end
