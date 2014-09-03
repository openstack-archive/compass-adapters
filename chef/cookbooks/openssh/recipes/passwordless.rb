openssh_key "SSH login without password" do
  role node['openssh']['passwordless']['role']
  action :create
end
