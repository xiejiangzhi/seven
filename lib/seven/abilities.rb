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
      #   options:
      #     {check: :role, equal: 'admin'}  current_user.role == 'admin'
      #     {check: :role, in: %w{admin editor}}  %w{admin editor}.include?(current_user.role)
      #     {pass: :my_filter} call my_filter method
      #     {pass: Proc.new { ... }} proc.call
      def abilities(options = nil, &rule_proc)
        filter = build_seven_abilities_filter(options)
        @rule_procs ||= []
        @rule_procs << [filter, rule_proc]
      end

      def build_seven_abilities_filter(options)
        return if options.nil?
        opts = options.symbolize_keys

        if val = opts[:pass]
          if val.is_a?(Proc)
            val
          else
            Proc.new { send val }
          end
        elsif attr = opts[:check]
          if list = opts[:in]
            Proc.new { list.include?(current_user.public_send(attr)) }
          elsif val = opts[:equal]
            Proc.new { current_user.public_send(attr) == val }
          else
            raise Seven::ArgsError, 'Invalid check definition'
          end
        else
          raise Seven::ArgsError, 'Invalid check definition'
        end
      end
    end
  end
end

