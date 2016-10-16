require 'rest-client'
require 'json'
require 'erb'
include ERB::Util

module AzureCharge

  class Usage
    attr_accessor :meter_name
    attr_accessor :meter_category
    attr_accessor :meter_sub_category
    attr_accessor :meter_id
    attr_accessor :meter_region
    attr_accessor :quantity
    attr_accessor :name
    attr_accessor :rate
    attr_accessor :included_quantity

    def cost
      rate.to_f * quantity.to_f
    end

    def data_array
      [meter_name, meter_category, meter_sub_category, meter_region, rate, quantity, included_quantity, cost]
    end

    def self.header_array
      ['name', 'category', 'sub_category', 'region', 'rate', 'quantity', 'included', 'cost']
    end
  end

  # Get API Token
  def self.api_token(application_id, client_secret, tenant_id)
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

  # Get Usage
  #
  def self.usages(token, subscription_id, range)
    # Need UTC time end time string must end with +00:00
    now = DateTime.now.new_offset(0)
    case range
    when :yesterday then
      start_time =  DateTime.new(now.year, now.month, now.day - 1, 0, 0, 0)
      end_time =  DateTime.new(now.year, now.month, now.day, 0, 0, 0)
    when :this_month then
      start_time =  DateTime.new(now.year, now.month, 1, 0, 0, 0)
      end_time =  DateTime.new(now.year, now.month, now.day, 0, 0, 0)
    when :last_month then
      start_time =  DateTime.new(now.year, now.month, 1, 0, 0, 0) << 1
      end_time =  DateTime.new(now.year, now.month, 1, 0, 0, 0) - 1
    else
    end

    granularity = "Monthly"

    url = "https://management.azure.com/subscriptions/#{subscription_id}/providers/Microsoft.Commerce/UsageAggregates?api-version=2015-06-01-preview&reportedStartTime=#{url_encode(start_time.to_s)}&reportedEndTime=#{url_encode(end_time.to_s)}&aggreagationGranularity=#{granularity}&showDetails=false"
    puts url
    headers = {
      "Content-type" => "application/json",
      "Authorization" => "Bearer #{token}"
    }

    results = []
    RestClient.get(url, headers){ |response, request, result, &block|
      case response.code
      when 200
        json = JSON.parse(response)
        json["value"].each do |item|
          u = Usage.new
          u.meter_id = item["properties"]["meterId"]
          u.quantity = item["properties"]["quantity"]
          u.name = item["name"]
          results.push(u)
        end
        results
      else
        false
      end
    }
  end

  # Get RateCard
  #
  def self.rate_meters(token, subscription_id, offer_durable_id)
    url = "https://management.azure.com/subscriptions/#{subscription_id}/providers/Microsoft.Commerce/RateCard?api-version=2015-06-01-preview&$filter=OfferDurableId eq '#{offer_durable_id}' and Currency eq 'JPY' and Locale eq 'ja-JP' and RegionInfo eq 'JP'"
    headers = {
      "Content-type" => "application/json",
      "Authorization" => "Bearer #{token}"
    }
    RestClient.get(url, headers){ |response, request, result, &block|
      case response.code
      when 200
        json = JSON.parse(response)
        json["Meters"]
      else
        false
      end
    }
  end

  # Get merged data
  def self.usages_with_rate(usages, meters)
    usages.each do |u|
      meters.each do |j|
        if j["MeterId"] == u.meter_id
          u.meter_name = j["MeterName"]
          u.meter_category = j["MeterCategory"]
          u.meter_sub_category = j["MeterSubCategory"]
          u.meter_region = j["MeterRegion"]
          u.rate = j["MeterRates"]["0"]
          u.included_quantity = j["IncludedQuantity"]
        end
      end
    end
    usages
  end
end
