require 'sinatra'
require 'time'
require 'tzinfo'

configure do
  set :server, :puma
end

TIMEZOME_CACHE = {}
UTC_TIME = Time.now.utc
CACHE_EXPIRATION_TIME = 3600

get '/time' do
  cities = params['cities']
  if cities.nil? || cities.empty?
    content_type :text
    "UTC: #{UTC_TIME}\n"
  else
    result = cities.split(',').map(&:strip).map do |city|
      local_time = UTC_TIME + Time.zone_offset(Time.now.zone)

      cached_timezone = TIMEZOME_CACHE[city]
      if cached_timezone && cached_timezone[:expiration_time] > Time.now
        timezone = cached_timezone[:timezone]
      else
        timezone = TZInfo::Timezone.get(city)
        TIMEZOME_CACHE[city] = { timezone: timezone, expiration_time: Time.now + CACHE_EXPIRATION_TIME }
      end

      local_time = UTC_TIME + timezone.current_period.utc_total_offset if timezone
      "#{city}: #{local_time}"
    end.join("\n")

    content_type :text
    "#{result}\n"
  end
end
