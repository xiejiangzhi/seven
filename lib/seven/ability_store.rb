module Seven::AbilityStore
  DEFAULT_SCOPE = 'global'

  # support types:
  #   module, class
  #   ActiveRecord or instance that has #id method
  #   string or symbol
  #   nil
  def stringify_scope(target)
    if target.is_a?(Class) || target.is_a?(Module)
      target.name
    elsif target.respond_to?(:id) || (defined?(ActiveRecord) && target.is_a?(ActiveRecord::Base))
      "#{target.class.name}-#{target.id}"
    elsif target.is_a?(String) || target.is_a?(Symbol)
      "S-#{target}"
    elsif target.nil?
      'nil'
    else
      raise "Sorry, cannot convert `#{target.inspect}` to a scope"
    end
  end

  def get_stringify_scopes(target)
    scopes = [stringify_scope(DEFAULT_SCOPE)]
    # append abilities of class
    scopes << stringify_scope(target.class) unless target.is_a?(Class)
    # abilities of instance
    (target == DEFAULT_SCOPE) ? scopes : (scopes << stringify_scope(target))
  end
end
