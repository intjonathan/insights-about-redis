module RedisInsights
  def self.to_number(string)
    Integer(string) rescue Float(string) rescue string
  end

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

end
