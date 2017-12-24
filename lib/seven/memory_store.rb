class Seven::MemoryStore
  def initialize
    @data = {}
  end

  def set(user, ability, allowed)
    (@data[user.id.to_s] ||= {}).merge!(ability.to_s.to_sym => !!allowed)
  end

  def del(user, ability)
    (@data[user.id.to_s] ||= {}).delete(ability.to_s.to_sym)
  end

  def list(user)
    @data[user.id.to_s] || {}
  end

  def clear(user)
    @data.delete(user.id.to_s)
  end

  def clear_all!
    @data.clear
  end
end
