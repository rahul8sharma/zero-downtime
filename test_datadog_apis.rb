require 'net/http'
require 'json'

# Get these from your project
API_KEY = ENV['DD_API_KEY'] || '9801e15c98a47c9de33f9c20cb257f7d'
APP_KEY = ENV['DD_APP_KEY'] || 'YOUR_APP_KEY_HERE'
SITE = 'datadoghq.eu'

puts "Testing Datadog APIs..."
puts "Site: #{SITE}"
puts "=" * 80

# Test different APIs to see which ones work
apis_to_test = [
  {
    name: "APM Services",
    method: :get,
    url: "https://api.#{SITE}/api/v1/apm/services",
    params: {}
  },
  {
    name: "Error Tracking Issues",
    method: :get,
    url: "https://api.#{SITE}/api/v2/apm/issues",
    params: { 'filter[from]': (7.days.ago.to_f * 1000).to_i, 'filter[to]': (Time.now.to_f * 1000).to_i }
  },
  {
    name: "Logs (with index main)",
    method: :post,
    url: "https://api.#{SITE}/api/v2/logs/events/search",
    body: {
      filter: {
        query: "status:error",
        from: 24.hours.ago.iso8601,
        to: Time.now.iso8601,
        indexes: ["main"]
      },
      page: { limit: 10 }
    }
  },
  {
    name: "Metrics",
    method: :get,
    url: "https://api.#{SITE}/api/v1/metrics",
    params: {}
  },
  {
    name: "Validate API Keys",
    method: :get,
    url: "https://api.#{SITE}/api/v1/validate",
    params: {}
  }
]

apis_to_test.each do |api|
  puts "\n" + "=" * 80
  puts "Testing: #{api[:name]}"
  puts "URL: #{api[:url]}"

  begin
    uri = URI(api[:url])

    if api[:method] == :get && api[:params].any?
      uri.query = URI.encode_www_form(api[:params])
    end

    request = if api[:method] == :post
      req = Net::HTTP::Post.new(uri)
      req['Content-Type'] = 'application/json'
      req.body = api[:body].to_json if api[:body]
      req
    else
      Net::HTTP::Get.new(uri)
    end

    request['DD-API-KEY'] = API_KEY
    request['DD-APPLICATION-KEY'] = APP_KEY
    request['Accept'] = 'application/json'

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 10) do |http|
      http.request(request)
    end

    puts "Status: #{response.code} #{response.message}"

    if response.code == '200'
      data = JSON.parse(response.body)
      puts "✅ SUCCESS!"
      puts "Response preview: #{response.body[0..200]}"

      # Show what data is available
      if data.is_a?(Hash)
        puts "Available keys: #{data.keys.join(', ')}"
        if data['data']
          puts "Data count: #{data['data'].length}" if data['data'].is_a?(Array)
        end
      end
    else
      error = JSON.parse(response.body) rescue response.body
      puts "❌ FAILED"
      puts "Error: #{error}"
    end

  rescue => e
    puts "❌ EXCEPTION: #{e.message}"
  end
end

puts "\n" + "=" * 80
puts "Testing complete!"
puts "\nNext steps:"
puts "1. Look for APIs that returned ✅ SUCCESS"
puts "2. Check which API returns error data you need"
puts "3. Update the service to use that endpoint"
