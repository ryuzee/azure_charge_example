require 'rest-client'
require 'json'
require 'erb'
include ERB::Util

module Azassu
  module Charge
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
        %w(name category sub_category region rate quantity included cost)
      end
    end

    # Get Usage
    #
    def self.usages(token, subscription_id, range)
      # Need UTC time end time string must end with +00:00
      now = DateTime.now.new_offset(0)
      case range
      when :yesterday then
        start_time =  DateTime.new(now.year, now.month, now.day - 1, 0, 0, 0)
        end_time = DateTime.new(now.year, now.month, now.day, 0, 0, 0)
      when :this_month then
        start_time = DateTime.new(now.year, now.month, 1, 0, 0, 0)
        end_time = DateTime.new(now.year, now.month, now.day, 0, 0, 0)
      when :last_month then
        start_time = DateTime.new(now.year, now.month, 1, 0, 0, 0) << 1
        end_time = DateTime.new(now.year, now.month, 1, 0, 0, 0) - 1
      end

      granularity = 'Monthly'

      url = "https://management.azure.com/subscriptions/#{subscription_id}/providers/Microsoft.Commerce/UsageAggregates?api-version=2015-06-01-preview&reportedStartTime=#{url_encode(start_time.to_s)}&reportedEndTime=#{url_encode(end_time.to_s)}&aggreagationGranularity=#{granularity}&showDetails=false"
      puts url
      headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }

      results = []
      RestClient.get(url, headers) do |response, _request, _result|
        case response.code
        when 200
          json = JSON.parse(response)
          json['value'].each do |item|
            u = Usage.new
            u.meter_id = item['properties']['meterId']
            u.quantity = item['properties']['quantity']
            u.name = item['name']
            results.push(u)
          end
          results
        else
          false
        end
      end
    end

    # Get RateCard
    #
    def self.rate_meters(token, subscription_id, offer_durable_id)
      url = "https://management.azure.com/subscriptions/#{subscription_id}/providers/Microsoft.Commerce/RateCard?api-version=2015-06-01-preview&$filter=OfferDurableId eq '#{offer_durable_id}' and Currency eq 'JPY' and Locale eq 'ja-JP' and RegionInfo eq 'JP'"
      headers = {
        'Content-type' => 'application/json',
        'Authorization' => "Bearer #{token}"
      }
      RestClient.get(url, headers) do |response, _request, _result|
        case response.code
        when 200
          json = JSON.parse(response)
          json['Meters']
        else
          false
        end
      end
    end

    # Get merged data
    def self.usages_with_rate(usages, meters)
      usages.each do |u|
        meters.each do |j|
          next unless j['MeterId'] == u.meter_id
          u.meter_name = j['MeterName']
          u.meter_category = j['MeterCategory']
          u.meter_sub_category = j['MeterSubCategory']
          u.meter_region = j['MeterRegion']
          u.rate = j['MeterRates']['0']
          u.included_quantity = j['IncludedQuantity']
        end
      end
      usages
    end
  end
end
