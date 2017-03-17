require 'clockwork'
require 'redis'
require 'httparty'

REDIS_HOST = ENV['REDIS_HOST'] || 'localhost'
REDIS_PORT = ENV['REDIS_PORT'] || 6379
INSIGHTS_INSERT_KEY   = ENV['INSIGHTS_INSERT_KEY']
INSIGHTS_EVENT_URL    = ENV['INSIGHTS_EVENT_URL']
INSIGHTS_EVENT_TYPE   = ENV['INSIGHTS_EVENT_TYPE'] || 'RedisInfo'

module Clockwork
  
  @redis = Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)

  every 30.seconds, 'pull redis INFO and post to Insights' do
    info = @redis.info
    info['eventType'] = INSIGHTS_EVENT_TYPE
    info['eventVersion'] = 1
    response = HTTParty.post(INSIGHTS_EVENT_URL,
            :body    => Oj.dump(events),
            :headers => {'Content-Type' => 'application/json',
                         'X-Insert-Key' => INSIGHTS_INSERT_KEY})    
  end
end
