module Seven
  class MemoryStore
    include Seven::AbilityStore

    def initialize
      @data = {}
    end

    def set(user, ability, allowed, scope = DEFAULT_SCOPE)
      user_data = @data[user.id.to_s] ||= {}
      (user_data[stringify_scope(scope)] ||= {}).merge!(ability.to_s.to_sym => !!allowed)
    end

    def del(user, ability, scope = DEFAULT_SCOPE)
      user_data = @data[user.id.to_s] || {}
      str_scope = stringify_scope(scope)
      user_data[str_scope].delete(ability.to_s.to_sym) if user_data && user_data[str_scope]
    end

    def list(user, scope = DEFAULT_SCOPE)
      get_stringify_scopes(scope).each_with_object({}) do |str_scope, r|
        user_data = @data[user.id.to_s] || {}
        r.merge!(user_data[str_scope] || {})
      end
    end

    def clear(user, scope = DEFAULT_SCOPE)
      user_data = @data[user.id.to_s]
      user_data.delete(stringify_scope(scope)) if user_data
    end

    def clear_user_all(user)
      @data.delete(user.id.to_s)
    end

    def clear_all!
      @data.clear
    end
  end
end
