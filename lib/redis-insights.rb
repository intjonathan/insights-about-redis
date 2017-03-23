require 'resolv'

require 'oj'
require 'redis'
require 'httparty'

class RedisInsights
  attr_accessor :logger

  def self.redis_host_info(redis_url)
    redis_uri = URI(redis_url)
    begin
      @host_ip =
        if redis_uri.host == 'localhost'
          Resolv.getaddress(Socket.gethostname)
        else
          Resolv.getaddress(redis_uri.host)
        end
    rescue Resolv::ResolvError => e
      puts "IP resolution failed for host #{redis_uri.host} with error #{e}"
    end

    [@host_ip, redis_uri.host]
  end

  def initialize(redis_url, insights_event_url, insights_insert_key, insights_event_type)
    @redis = Redis.new(:url => redis_url)
    @redis_host_ip, @redis_host_name = RedisInsights.redis_host_info(redis_url)
    @insights_event_type = insights_event_type
    @insights_event_url = insights_event_url
    @insights_insert_key = insights_insert_key
    @logger ||= Logger.new(STDOUT)
  end

  def info_to_insights
    begin
      info = @redis.info
    rescue SocketError, Redis::CannotConnectError => e
      logger.error "Error capturing Redis INFO: #{e}"
      return
    end
    info.merge!('host_name'    => @redis_host_name,
                'host_ip'      => @redis_host_ip,
                'eventType'    => @insights_event_type,
                'eventVersion' => 1)
    info = Hash[ info.map { | k,v| [k, to_number(v)] } ]
    begin
      response = HTTParty.post(@insights_event_url,
              :body    => Oj.dump(info),
              :headers => {'Content-Type' => 'application/json',
                           'X-Insert-Key' => @insights_insert_key})
      logger.info response.body
      unless response.success?
        logger.error "POST replied with: #{response.body}"
      end
    rescue HTTParty::Error, SocketError => e
      logger.error "Insights POST failed with error: #{e}"
    end
  end

  private 

  def to_number(string)
    Integer(string) rescue Float(string) rescue string
  end
end
