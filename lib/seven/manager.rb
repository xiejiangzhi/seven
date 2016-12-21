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
      _matcher, rule_class = rules.find {|m, rc| m === target }
      return false unless rule_class
      rule_class.new(current_user, target).abilities.include?(ability.to_sym)
    end


    private

    def valid_rule_class?(rule_class)
      return false unless rule_class && rule_class.is_a?(Class)
      rule_class.included_modules.include?(Seven::Abilities)
    end
  end
end

