require "seven/version"

require "seven/error"

require "active_support"
require "active_support/core_ext"

module Seven
  autoload :Manager, 'seven/manager'
  autoload :Abilities, 'seven/abilities'
  autoload :Rails, 'seven/rails'

  autoload :MemoryStore, 'seven/memory_store'
  autoload :RedisStore, 'seven/redis_store'
end

