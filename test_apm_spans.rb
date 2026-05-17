require 'net/http'
require 'json'

API_KEY = '6be91b9643340e01630579fe39eeb38e'
APP_KEY = 'ddapp_XZ1EYlVP8hprni5XLojlhp4JvxDj4cbuCc'
SITE = 'datadoghq.eu'

puts "=" * 80
puts "Testing APM Spans API for errors"
puts "=" * 80

uri = URI("https://api.#{SITE}/api/v2/spans/events/search")

from_time = (24.hours.ago.to_f * 1000).to_i
to_time = (Time.now.to_f * 1000).to_i

request_body = {
  filter: {
    query: "service:zero-downtime @http.status_code:>=500",
    from: from_time,
    to: to_time
  },
  sort: "-timestamp",
  page: {
    limit: 10
  }
}.to_json

puts "Query: service:zero-downtime @http.status_code:>=500"
puts "From: #{Time.at(from_time / 1000)}"
puts "To: #{Time.at(to_time / 1000)}"
puts ""

request = Net::HTTP::Post.new(uri)
request['DD-API-KEY'] = API_KEY
request['DD-APPLICATION-KEY'] = APP_KEY
request['Content-Type'] = 'application/json'
request.body = request_body

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true, read_timeout: 30) do |http|
  http.request(request)
end

puts "Response Code: #{response.code}"
puts ""

if response.code == '200'
  data = JSON.parse(response.body)
  spans = data['data'] || []
  
  puts "✅ SUCCESS! Found #{spans.length} error spans"
  
  if spans.any?
    puts "\nFirst 3 errors:"
    spans.first(3).each_with_index do |span, i|
      attrs = span['attributes'] || {}
      tags = attrs['tags'] || []
      
      error_type = tags.find { |t| t.start_with?('error.type:') }&.split(':', 2)&.last
      error_msg = tags.find { |t| t.start_with?('error.message:') }&.split(':', 2)&.last
      http_status = tags.find { |t| t.start_with?('http.status_code:') }&.split(':', 2)&.last
      resource = attrs['resource_name']
      
      puts "\n#{i + 1}. #{error_type || 'Error'}"
      puts "   Resource: #{resource}"
      puts "   HTTP Status: #{http_status}"
      puts "   Message: #{error_msg&.truncate(80)}"
    end
  else
    puts "\nNo errors found. Trying broader query..."
    
    # Try without status code filter
    request_body = {
      filter: {
        query: "service:zero-downtime",
        from: from_time,
        to: to_time
      },
      page: { limit: 5 }
    }.to_json
    
    request.body = request_body
    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) { |http| http.request(request) }
    
    if response.code == '200'
      data = JSON.parse(response.body)
      puts "Total spans for service: #{data['data']&.length || 0}"
      
      if data['data']&.any?
        sample = data['data'].first['attributes']
        tags = sample['tags'] || []
        puts "Sample span tags:"
        tags.first(10).each { |t| puts "  - #{t}" }
      end
    end
  end
else
  error = JSON.parse(response.body) rescue response.body
  puts "❌ FAILED"
  puts "Error: #{error}"
end

puts "\n" + "=" * 80
