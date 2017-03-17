#!/usr/bin/env ruby

require 'resolv'
require 'clockwork'
require 'redis'
require 'httparty'
require 'oj'

REDIS_HOST = ENV['REDIS_HOST'] || 'localhost'
REDIS_PORT = ENV['REDIS_PORT'] || 6379
INSIGHTS_INSERT_KEY   = ENV['INSIGHTS_INSERT_KEY']
INSIGHTS_EVENT_URL    = ENV['INSIGHTS_EVENT_URL']
INSIGHTS_EVENT_TYPE   = ENV['INSIGHTS_EVENT_TYPE'] || 'RedisInfo'

module Clockwork
  
  @redis = Redis.new(:host => REDIS_HOST, :port => REDIS_PORT)
  @redis_host_ip = Resolv.getaddress(REDIS_HOST)

  every 20.seconds, 'pull redis INFO and post to Insights' do
    info = @redis.info
    info.merge!('host_name' => REDIS_HOST,
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

def to_number(string)
  Integer(string) rescue Float(string) rescue string
end
