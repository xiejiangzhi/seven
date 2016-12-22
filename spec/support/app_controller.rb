module Support
  class AppController
    class << self
      attr_reader :filter

      def before_action(filter_name = nil, &filter_proc)
        @filter = filter_name ? Proc.new { send(filter_name) } : filter_proc
      end
    end

    include Seven::Rails::ControllerHelpers

    attr_accessor :abilities_manager

    def controller_name
      @controller_name
    end

    def action_name
      @action_name
    end

    def run(cname, aname)
      @controller_name = cname
      @action_name = aname

      instance_eval(&self.class.filter)
    end

    def current_user
      @user ||= User.new(role: :normal)
    end

    def abilities_manager
      @abilities_manager ||= Seven::Manager.new
    end

    def ability_check_callback(allowed, ability, target)
    end
  end
end

