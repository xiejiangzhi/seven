module Seven
  module Rails
    module ControllerHelpers
      # reuqire methods
      #   current_user
      #   abilities_manager
      #   ability_check_callback

      def self.included(cls)
        cls.extend(ClassMethods)
      end

      def can?(ability, target = nil)
        abilities_manager.can?(current_user, ability, target)
      end

      def seven_ability_check_filter
        current_action_name = action_name.to_sym
        action_checker = self.class.seven_ability_checker[current_action_name]

        if action_checker
          target = seven_fetch_target(action_checker[:target])

          result = can?(action_checker[:ability], target)
          ability_check_callback(result, action_checker[:ability], target)
        else
          ability_check_callback(false, nil, nil)
        end
      end

      def seven_fetch_target(target_list)
        return if target_list.empty?

        target_list.each do |t|
          case t
          when Symbol, String
            instance = instance_variable_defined?(t) ? instance_variable_get(t) : nil
            return instance if instance
          when Proc
            result = instance_eval(&t)
            return result if result
          else
            return t
          end
        end
      end


      module ClassMethods
        attr_reader :seven_ability_checker

        # Examples:
        #   ability_check :@topic
        #   ability_check [:@topic, Topic]
        #   ability_check [:@topic, Topic], show: {ability: :read_t, target: [:user]}
        #   ability_check show: {ability: :read_t, target: [:user]}
        #   ability_check action1: {something_opts}, action2: {someting_opts}
        #   ability_check [:@topic, Topic], nil, resource_name: :comments
        def seven_ability_check(default_target, custom_checker = nil, opts = {})
          @seven_ability_checker = seven_generate_controller_checker(
            default_target, custom_checker, opts
          )

          before_action :seven_ability_check_filter
        end


        private

        def seven_generate_controller_checker(default_target, custom_checker, opts)
          if default_target.is_a?(Hash)
            raise Seven::ArgsError, 'Invalid arguments' if custom_checker
            seven_format_ability_checker(default_target)
          else
            controller_checker = seven_generate_default_ability_checker(
              default_target, opts[:resource_name] || opts['resource_name']
            )

            if custom_checker.is_a?(Hash)
              controller_checker.merge(seven_format_ability_checker(custom_checker))
            elsif custom_checker.nil?
              controller_checker
            else
              raise Seven::ArgsError, 'Invalid arguments'
            end
          end
        end

        def seven_generate_default_ability_checker(target, resource_name)
          resource_name ||= name.demodulize.sub(/Controller$/, '').underscore
          pluralize_name = resource_name.to_s.pluralize
          singularize_name = resource_name.to_s.singularize

          [
            [:index, :read, pluralize_name],
            [:show, :read, singularize_name],
            [:new, :create, singularize_name],
            [:edit, :edit, singularize_name],
            [:create, :create, singularize_name],
            [:update, :edit, singularize_name],
            [:destroy, :delete, singularize_name]
          ].each_with_object({}) do |data, result|
            action_name, opt, resource_name = data
            result[action_name] = {ability: "#{opt}_#{resource_name}".to_sym, target: target}
          end
        end

        def seven_format_ability_checker(checker)
          checker.each_with_object({}) do |data, result|
            action_name, action_checker = data
            tmp = result[action_name.to_sym] = action_checker.symbolize_keys

            unless tmp[:ability] && tmp[:target]
              raise Seven::ArgsError, "Invalid checker #{action_name}: #{action_checker}"
            end
          end
        end
      end
    end
  end
end

