#!/usr/bin/env ruby

require 'uri'
require 'resolv'

require 'clockwork'
require 'redis'
require 'httparty'
require 'oj'

REPORT_FREQUENCY_SEC = ENV['REPORT_FREQUENCY_SEC'] || 20
REDIS_URL            = ENV['REDIS_URL'] || 'redis://localhost:6379'
INSIGHTS_INSERT_KEY  = ENV['INSIGHTS_INSERT_KEY']
INSIGHTS_EVENT_URL   = ENV['INSIGHTS_EVENT_URL']
INSIGHTS_EVENT_TYPE  = ENV['INSIGHTS_EVENT_TYPE'] || 'RedisInfo'

def to_number(string)
  Integer(string) rescue Float(string) rescue string
end

def redis_host_info(redis_url)
  redis_uri = URI(redis_url)

  @host_ip =
    if redis_uri.host == 'localhost'
      Resolv.getaddress(Socket.gethostname)
    else
      Resolv.getaddress(redis_uri.host)
    end

  [@host_ip, redis_uri.host]
end

module Clockwork
  begin
    @report_frequency = Integer(REPORT_FREQUENCY_SEC)
    puts "Will report every #{@report_frequency} seconds..."
  rescue ArgumentError
    puts "You must specify an integer as REPORT_FREQUENCY_SEC!"
    exit 1
  end

  @redis = Redis.new(:url => REDIS_URL)
  @redis_host_ip, @redis_host_name = redis_host_info(REDIS_URL)

  every @report_frequency.seconds, 'pull redis INFO and post to Insights' do
    info = @redis.info
    info.merge!('host_name' => @redis_host_name,
                'host_ip'  => @redis_host_ip,
                'eventType' => INSIGHTS_EVENT_TYPE,
                'eventVersion' => 1)
    info = Hash[ info.map { | k,v| [k, to_number(v)] } ]
    response = HTTParty.post(INSIGHTS_EVENT_URL,
            :body    => Oj.dump(info),
            :headers => {'Content-Type' => 'application/json',
                         'X-Insert-Key' => INSIGHTS_INSERT_KEY})
    puts response
  end

end

