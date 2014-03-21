actions :set

default_action :set

attribute :pid, :kind_of => [String, Integer], :name_attribute => true
attribute :priority, :kind_of => Integer, :required => true

# Covers 0.10.8 and earlier
def initialize(*args)
  super
  @action = :set
end
