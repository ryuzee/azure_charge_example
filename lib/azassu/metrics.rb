# See https://docs.microsoft.com/ja-jp/azure/monitoring-and-diagnostics/monitoring-rest-api-walkthrough

module Azassu
  module Metrics
    def self.get(token, subscription_id, resource_group, resource_provider_ns, resource_type, resource_name, filter)

      api_version = "2016-06-01"
      url = "https://management.azure.com/subscriptions/#{subscription_id}/resourceGroups/#{resource_group}/providers/#{resource_provider_ns}/#{resource_type}/#{resource_name}/providers/microsoft.insights/metrics?$filter=#{url_encode(filter)}&api-version=#{api_version}"
      headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }

      RestClient.get(url, headers) do |response, _request, _result|
        case response.code
        when 200
          json = JSON.parse(response)
          json["value"][0]["data"]
        else
          false
        end
      end
    end

    def self.get_resources(token, subscription_id)
      api_version = "2016-06-01"
      url = "https://management.azure.com/subscriptions/#{subscription_id}/resources?api-version=#{api_version}"
      headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }

      RestClient.get(url, headers) do |response, _request, _result|
        case response.code
        when 200
          json = JSON.parse(response)
          json
        else
          false
        end
      end
    end
  end
end
