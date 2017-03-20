#!/usr/bin/env ruby

require_relative '../lib/redis-insights'

require 'uri'
require 'resolv'
require 'pp'

require 'trollop'
require 'clockwork'
require 'redis'
require 'httparty'
require 'oj'


module Clockwork
  opts = Trollop::options do 
    opt :redis_url, 'redis connect string', type: String, default: 'redis://localhost:6379', short: '-s'
    opt :insights_event_url, 'New Relic Insights custom event URL', type: String, required: true, short: '-u'
    opt :insights_insert_key, 'Insights Insert API Key', type: String, required: true, short: '-k'
    opt :report_frequency, 'Frequency of INFO query and event insertion', type: Integer, required: false, default: 60, short: '-f'
    opt :insights_event_type, 'Type field for the Insights event', type: String, short: '-t', default: 'RedisInfo'
  end

  @redis = Redis.new(:url => opts[:redis_url])
  @redis_host_ip, @redis_host_name = RedisInsights::redis_host_info(opts[:redis_url])

  every opts[:report_frequency].seconds, 'pull redis INFO and post to Insights' do
    puts @redis_host_name
    info = @redis.info
    info.merge!('host_name'    => @redis_host_name,
                'host_ip'      => @redis_host_ip,
                'eventType'    => opts[:insights_event_type],
                'eventVersion' => 1)
    info = Hash[ info.map { | k,v| [k, RedisInsights::to_number(v)] } ]
    response = HTTParty.post(opts[:insights_event_url],
            :body    => Oj.dump(info),
            :headers => {'Content-Type' => 'application/json',
                         'X-Insert-Key' => opts[:insights_insert_key]})
    puts response
  end
end

