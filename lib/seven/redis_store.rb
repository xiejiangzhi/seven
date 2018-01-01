module Seven
  class RedisStore
    include Seven::AbilityStore

    NAMESPACE = 'Seven'

    def initialize(redis_opts)
      opts = redis_opts.symbolize_keys
      @redis = opts[:redis]
    end

    def set(user, ability, allowed, scope = DEFAULT_SCOPE)
      @redis.hset(get_user_key(user.id, scope), ability, allowed ? '1' : '0')
    end

    def del(user, ability, scope = DEFAULT_SCOPE)
      @redis.hdel(get_user_key(user.id, scope), ability)
    end

    def list(user, scope = DEFAULT_SCOPE)
      get_stringify_scopes(scope).each_with_object({}) do |new_scope, r|
        hash_abs = @redis.hgetall(get_user_key(user.id, new_scope, true)).symbolize_keys.tap do |abilities|
          abilities.each { |k, v| abilities[k] = v == '1' ? true : false }
        end
        r.merge!(hash_abs)
      end
    end

    def clear(user, scope = DEFAULT_SCOPE)
      @redis.del(get_user_key(user.id, scope))
    end

    def clear_user_all(user)
      delete_keys!("#{NAMESPACE}/#{user.id}/*")
    end

    def clear_all!
      delete_keys!("#{NAMESPACE}/*")
    end

    private

    def get_user_key(user_id, scope, stringy = false)
      "#{NAMESPACE}/#{user_id}/#{stringy ? scope : stringify_scope(scope)}"
    end

    def delete_keys!(pattern)
      @redis.eval(
        "local keys = redis.call('keys', '#{pattern}')\n" +
        "for i = 1, #keys,5000 do\n" +
        "  redis.call('del', unpack(keys, i, math.min(i+4999, #keys)))\n" +
        "end\n" +
        "return #keys"
      )
    end
  end
end
