actions :create, :allow, :copy

attribute :role,             :kind_of => String, :name_attribute => true
attribute :username,         :kind_of => String, :default => `whoami`.delete("\n")
attribute :home,             :kind_of => String, :default => `eval echo ~${SUDO_USER}`.delete("\n")
attribute :port,             :kind_of => Integer, :default => 22
attribute :private_key,      :kind_of => String, :default => `eval echo ~${SUDO_USER}`.delete("\n") + "/.ssh/id_rsa"
attribute :public_key,       :kind_of => String, :default => `eval echo ~${SUDO_USER}`.delete("\n") + "/.ssh/id_rsa.pub"
attribute :authorized_key,  :kind_of => String, :default => `eval echo ~${SUDO_USER}`.delete("\n") + "/.ssh/authorized_keys"

def initialize(*args)
  super
  @action = :create
end
