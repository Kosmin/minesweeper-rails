module RedisClient
  def get(key)
    instance.get(key)
  end

  def set(key, value)
    instance.set(key, value)
  end

  private
  def instance
    @instance ||= Redis.new(url: ENV['REDIS_URL'])
  end
end
