module Seven
  class Manager
    attr_reader :rules, :store

    # Params:
    #   store: hash or your store, the store requires get(user_id) and set(user_id, ability, status) methods
    #           get(user_id) should return a hash of abilities {${ability}: ${true || false}}
    def initialize(store: {})
      @rules = []
      @store = fetch_store(store)
    end

    def define_rules(matcher, rule_class = nil, &rule_proc)
      rule_class ||= Seven::Abilities.wrap_proc(rule_proc)

      if valid_rule_class?(rule_class)
        @rules << [matcher, rule_class]
      else
        raise ArgsError, 'No valid rule_class or rule_proc'
      end
    end

    def can?(current_user, ability, target = nil)
      matched_rules = rules.select {|m, rc| m === target || m == target }
      return false if matched_rules.empty?

      # class A; end
      # class B < A; end
      # [A, B, Object].min # => B
      # find last class
      rule_class = matched_rules.min_by(&:first).last
      abilities = rule_class.new(current_user, target).abilities

      # dynamic abilities
      store.list(current_user).each do |new_ability, is_allowed|
        is_allowed ? (abilities << new_ability) : abilities.delete(new_ability)
      end
      abilities.include?(ability.to_sym)
    end


    private

    def valid_rule_class?(rule_class)
      return false unless rule_class && rule_class.is_a?(Class)
      rule_class.included_modules.include?(Seven::Abilities)
    end

    def fetch_store(store_options)
      unless store_options.is_a?(Hash) || store_options.nil?
        if store_options.respond_to?(:list)
          return store_options
        else
          raise "Invalid store: #{store_options.inspect}, a store should defined #list method"
        end
      end

      opts = (store_options || {}).symbolize_keys

      if opts[:redis]
        RedisStore.new(opts)
      else
        MemoryStore.new
      end
    end
  end
end

