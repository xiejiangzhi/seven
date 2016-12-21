class User
  attr_accessor :id, :role

  def initialize(role: 'normal')
    @@id_counter ||= 0
    @@id_counter += 1

    @id = @@id_counter
    @role = role
  end
end

class Topic
  attr_accessor :id, :user_id, :is_lock

  def initialize(user_id: 1, is_lock: false)
    @@id_counter ||= 0
    @@id_counter += 1

    @id = @@id_counter
    @user_id = user_id
    @is_lock = is_lock
  end
end

