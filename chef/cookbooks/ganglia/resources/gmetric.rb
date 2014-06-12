
actions :enable, :disable
default_action :enable

attribute :script_name, :kind_of => String, :name_attribute => true
attribute :options, :kind_of => Hash, :default => {}
