module Seven
  class Manager
    attr_reader :rules

    def initialize
      @rules = []
    end

    def define_rules(matcher, rule_class = nil, &rule_proc)
      rule_class ||= Seven::Abilities.warp_proc(rule_proc)

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
      rule_class.new(current_user, target).abilities.include?(ability.to_sym)
    end


    private

    def valid_rule_class?(rule_class)
      return false unless rule_class && rule_class.is_a?(Class)
      rule_class.included_modules.include?(Seven::Abilities)
    end
  end
end

