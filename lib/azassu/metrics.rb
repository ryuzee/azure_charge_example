# See https://docs.microsoft.com/ja-jp/azure/monitoring-and-diagnostics/monitoring-rest-api-walkthrough

module Azassu
  module Metrics
    def self.get(token, subscription_id, resource_group, resource_provider_ns, resource_type, resource_name, filter)
      api_version = '2016-06-01'
      url = "https://management.azure.com/subscriptions/#{subscription_id}/resourceGroups/#{resource_group}/providers/#{resource_provider_ns}/#{resource_type}/#{resource_name}/providers/microsoft.insights/metrics?$filter=#{url_encode(filter)}&api-version=#{api_version}"
      headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
      RestClient.get(url, headers) do |response, _request, _result|
        case response.code
        when 200
          json = JSON.parse(response)
          json['value'][0]['data']
        else
          false
        end
      end
    end

    def self.get_by_name(token, subscription_id, resource_name, type, filter)
      resources = get_resources(token, subscription_id)
      return false unless resources
      target = resources.select { |h| h['name'] == resource_name.to_s && h['type'] == type.to_s }.first
      return false unless target
      self.get_by_url(token ,target['id'], filter)
    end

    def self.get_by_url(token, url, filter)
      api_version = '2016-06-01'
      url = "https://management.azure.com#{url}/providers/microsoft.insights/metrics?$filter=#{url_encode(filter)}&api-version=#{api_version}"
      headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
      RestClient.get(url, headers) do |response, _request, _result|
        case response.code
        when 200
          json = JSON.parse(response)
          json['value'][0]['data']
        else
          false
        end
      end
    end

    def self.get_resources(token, subscription_id)
      api_version = '2016-06-01'
      url = "https://management.azure.com/subscriptions/#{subscription_id}/resources?api-version=#{api_version}"
      headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }

      RestClient.get(url, headers) do |response, _request, _result|
        case response.code
        when 200
          json = JSON.parse(response)
          json['value']
        else
          false
        end
      end
    end

    # See https://docs.microsoft.com/en-us/azure/monitoring-and-diagnostics/monitoring-supported-metrics
    def self.generate_5mins_filter(filter_type = 'Percentage CPU', aggregation_type = 'Average')
      now = Time.now - 60
      start = now - 5 * 60
      "(name.value eq '#{filter_type}') and aggregationType eq '#{aggregation_type}' and startTime eq #{start.to_datetime} and endTime eq #{now.to_datetime} and timeGrain eq duration'PT1M'"
    end
  end
end
