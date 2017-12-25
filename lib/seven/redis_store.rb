class Seven::RedisStore
  def initialize(redis_opts)
    opts = redis_opts.symbolize_keys
    @redis = opts[:redis]
  end

  def set(user, ability, allowed)
    @redis.hset(get_user_key(user.id), ability, allowed ? '1' : '0')
  end

  def del(user, ability)
    @redis.hdel(get_user_key(user.id), ability)
  end

  def list(user)
    @redis.hgetall(get_user_key(user.id)).symbolize_keys.tap do |abilities|
      abilities.each { |k, v| abilities[k] = v == '1' ? true : false }
    end
  end

  def clear(user)
    @redis.del(get_user_key(user.id))
  end

  def clear_all!
    @redis.eval(
      "local keys = redis.call('keys', 'seven_abilities/*')\n" +
      "for i = 1, #keys,5000 do\n" +
      "  redis.call('del', unpack(keys, i, math.min(i+4999, #keys)))\n" +
      "end\n" +
      "return #keys"
    )
  end

  private

  def get_user_key(user_id)
    "seven_abilities/#{user_id}"
  end
end
