require 'redis'

class RedisClient
  TYPE = :redis

  def connect
    @client ||= Redis.new
  end
end