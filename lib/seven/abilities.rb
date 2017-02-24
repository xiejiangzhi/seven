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

      self.class.rule_procs.each do |checker, rule_proc|
        next if checker && (current_user.nil? || !instance_eval(&checker))
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
      #
      #   or
      #
      #   proc
      def abilities(field = nil, scope = nil, &rule_proc)
        checker = case field
        when Proc
          field
        when Symbol, String
          raise Seven::ArgsError, 'Scope cannot be nil' if scope.nil?
          tmp_scope = scope.is_a?(Array) ? scope : [scope]
          Proc.new { tmp_scope.include?(current_user.public_send(field)) }
        when nil
          nil
        else
          raise Seven::ArgsError, "Invalid field '#{field}'" if scope.nil?
        end


        @rule_procs ||= []
        @rule_procs << [checker, rule_proc]
      end
    end
  end
end

