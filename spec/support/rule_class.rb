module Support
  module RuleClass
    def create_base_rule_class
      Class.new do
        include Seven::Abilities

        abilities do
          can 'read_topics'
          if current_user
            can :create_topic
            if current_user.id == target.user_id || current_user.role == :admin
              can :edit_topic, :destroy_topic
            end
          end
        end
      end
    end

    def create_role_rule_class
      Class.new do
        include Seven::Abilities

        abilities check: :role, in: [:reviewer, :editor] do
          can :edit_topic
        end

        abilities check: :role, equal: :admin do
          can_manage
        end

        abilities do
          can 'read_topics'
          if current_user
            can :create_topic
            can_manage if current_user.id == target.user_id
            cannot_manage if target.is_lock
          end
        end

        def can_manage
          can :edit_topic, :destroy_topic
        end

        def cannot_manage
          cannot :edit_topic, :destroy_topic
        end
      end
    end

    def create_proc_rule_class
      Class.new do
        include Seven::Abilities

        abilities pass: Proc.new{ current_user.role.to_sym == :admin } do
          can_manage
        end

        abilities pass: :my_filter do
          can :edit_topic
        end

        abilities do
          can 'read_topics'
          if current_user
            can :create_topic
            can_manage if current_user.id == target.user_id
            cannot_manage if target.is_lock
          end
        end

        def can_manage
          can :edit_topic, :destroy_topic
        end

        def cannot_manage
          cannot :edit_topic, :destroy_topic
        end

        def my_filter
          current_user.role.to_sym == :reviewer
        end
      end
    end

  end
end

