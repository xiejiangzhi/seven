module Seven
  module Abilities
    class << self
      def warp_proc(rule_proc)
        return unless rule_proc

        Class.new do
          include Seven::Abilities
          abilities(&rule_proc)
        end
      end

      def included(cls)
        cls.extend(ClassMethods)
      end
    end


    attr_reader :current_user, :target

    def initialize(current_user, target)
      @current_user = current_user
      @target = target
      @abilities = nil
    end

    def abilities
      return @abilities if @abilities
      @abilities = []

      self.class.rule_procs.each do |field, scope, rule_proc|
        if field
          next if current_user.nil? || !scope.include?(current_user.public_send(field))
        end
        instance_eval(&rule_proc)
      end

      @abilities
    end

    def can(*some_abilities)
      @abilities.push(*some_abilities.map(&:to_sym))
    end

    def cannot(*some_abilities)
      syn_abilities = some_abilities.map(&:to_sym)
      @abilities.delete_if {|ability| syn_abilities.include?(ability) }
    end


    module ClassMethods
      attr_reader :rule_procs

      # Params:
      #   field: current_user method
      #   scope: run rule proc if Array(scope).include?(current_user#{field})
      def abilities(field = nil, scope = nil, &rule_proc)
        if field
          raise Seven::ArgsError, 'Scope cannot be nil' unless scope
          formatted_scope = scope.is_a?(Array) ? scope : [scope]
        end

        @rule_procs ||= []
        @rule_procs << [field ? field.to_sym : nil, formatted_scope, rule_proc]
      end
    end
  end
end

