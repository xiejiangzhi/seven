RSpec.describe Seven::MemoryStore do
  include_examples 'store describe', Seven::MemoryStore.new
end
