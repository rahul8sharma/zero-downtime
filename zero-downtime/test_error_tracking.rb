require 'net/http'
require 'json'

API_KEY = '6be91b9643340e01630579fe39eeb38e'
APP_KEY = 'ddapp_XZ1EYlVP8hprni5XLojlhp4JvxDj4cbuCc'
SITE = 'datadoghq.eu'

puts "=" * 80
puts "Testing Error Tracking Issues API"
puts "=" * 80

# Try Error Tracking API
uri = URI("https://api.#{SITE}/api/v2/apm/issues")

from_time = (7.days.ago.to_f * 1000).to_i
to_time = (Time.now.to_f * 1000).to_i

# Add query parameters
uri.query = URI.encode_www_form({
  'filter[service]': 'zero-downtime',
  'filter[from]': from_time,
  'filter[to]': to_time,
  'page[limit]': 100
})

puts "URL: #{uri}"
puts ""

request = Net::HTTP::Get.new(uri)
request['DD-API-KEY'] = API_KEY
request['DD-APPLICATION-KEY'] = APP_KEY
request['Accept'] = 'application/json'

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30) do |http|
  http.request(request)
end

puts "Response Code: #{response.code}"
puts ""

if response.code == '200'
  data = JSON.parse(response.body)
  issues = data['data'] || []
  
  puts "✅ SUCCESS! Found #{issues.length} error issues"
  
  if issues.any?
    puts "\nError Issues:"
    issues.first(5).each_with_index do |issue, i|
      attrs = issue['attributes'] || {}
      
      puts "\n#{i + 1}. #{attrs['title'] || 'Unknown Error'}"
      puts "   Type: #{attrs['error_type']}"
      puts "   Status: #{attrs['status']}"
      puts "   Count: #{attrs['count']}"
      puts "   First Seen: #{Time.at(attrs['first_seen'] / 1000) rescue 'N/A'}"
      puts "   Last Seen: #{Time.at(attrs['last_seen'] / 1000) rescue 'N/A'}"
    end
  else
    puts "\nNo error issues found."
  end
  
  # Show metadata
  if data['meta']
    puts "\nMetadata:"
    puts "  Total count: #{data['meta']['page']&.dig('total_count')}"
  end
  
else
  error = JSON.parse(response.body) rescue response.body
  puts "❌ FAILED"
  puts "Error: #{error}"
end

puts "\n" + "=" * 80
