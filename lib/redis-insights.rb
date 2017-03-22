require 'resolv'
require 'pp'

require 'oj'
require 'redis'
require 'httparty'

class RedisInsights
  def self.redis_host_info(redis_url)
    redis_uri = URI(redis_url)

    @host_ip =
      if redis_uri.host == 'localhost'
        Resolv.getaddress(Socket.gethostname)
      else
        Resolv.getaddress(redis_uri.host)
      end

    [@host_ip, redis_uri.host]
  end

  def initialize(redis_url, insights_event_url, insights_insert_key, insights_event_type)
    @redis = Redis.new(:url => redis_url)
    @redis_host_ip, @redis_host_name = RedisInsights.redis_host_info(redis_url)
    @insights_event_type = insights_event_type
    @insights_event_url = insights_event_url
    @insights_insert_key = insights_insert_key
  end

  def info_to_insights
    info = @redis.info
    info.merge!('host_name'    => @redis_host_name,
                'host_ip'      => @redis_host_ip,
                'eventType'    => @insights_event_type,
                'eventVersion' => 1)
    info = Hash[ info.map { | k,v| [k, to_number(v)] } ]
    response = HTTParty.post(@insights_event_url,
            :body    => Oj.dump(info),
            :headers => {'Content-Type' => 'application/json',
                         'X-Insert-Key' => @insights_insert_key})
    puts response
  end

  private 

  def to_number(string)
    Integer(string) rescue Float(string) rescue string
  end
end
