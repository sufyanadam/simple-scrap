require 'net/http'
require 'date'
require 'json'


QUERY = ARGV[0] || 'melbourne, fl'
NUMBER_OF_DAYS = (ARGV[1] || 7).to_i


def query_airbnb (params = {})
  uri = URI('http://www.airbnb.com/search/ajax_get_results')

  default_params = {
    new_search: 'true',
    search_view: 1,
    min_bedrooms: 0,
    min_bathrooms: 0,
    min_beds: 0,
    page: 1,
  }

  uri.query = URI.encode_www_form(default_params.merge(params))
  
  request = Net::HTTP::Get.new(uri.request_uri)
  request['X-Requested-With'] = 'XMLHttpRequest'
  request['Accept'] = 'application/json, text/javascript, */*; q=0.01'

  response = Net::HTTP.start(uri.hostname, uri.port) {  |http| http.request(request) }
end

def properties_from_query(params = {})
  response = query_airbnb params
  json_response = JSON.parse response.body
  json_response['properties']
end

def property_availabilities_by_day_for(location)
  property_availabilities = {} 

  NUMBER_OF_DAYS.times do |i|
    checkin_date = Date.today + i
    current_properties = properties_from_query(
      location: location,
      checkin: checkin_date.strftime("%m/%d/%Y"),
      checkout: (checkin_date + 1).strftime("%m/%d/%Y")
    )

    current_properties.each do |property|
      property_availabilities[property] ||= []
      property_availabilities[property][i] = true
    end
  end
  
  property_availabilities
end

PROPERTY_NAME_COLUMN_SIZE = 20

availabilities = property_availabilities_by_day_for(QUERY)
availabilities = availabilities.sort_by {|_, a| a.count {|available| available }}.reverse

puts "Property\t\t\t\t #{(1..NUMBER_OF_DAYS).to_a.map { |i| "Day #{i}  "  }.join("") }"

availabilities.each do |property, days|
  puts "#{property['name'][0...PROPERTY_NAME_COLUMN_SIZE].ljust(PROPERTY_NAME_COLUMN_SIZE, ".")}     #{days.map{|value| value ? "x" : " "  }.join(" " * 6) }"
end
