

default['stackforge']['rally']['vars'] = {
  'virtualenv_dir' => '/opt/rally',
  'rally_src_zip' => 'https://github.com/stackforge/rally/archive/master.zip'
}

default['compass']['hc'] = {
  'user' => 'admin',
  'password' => 'admin',
  'url' => 'http://127.0.0.1:5000/v2.0',
  'tenant' => 'admin'
}

case node['platform_family']
when 'rhel'
  default['stackforge']['rally']['required_packages'] =
    [ 'wget', 'gcc', 'git', 'libffi-devel', 'python-devel', 'openssl-devel',
      'gmp-devel', 'libxml2-devel', 'libxslt-devel', 'MySQL-python' ]
when 'debian'
  default['stackforge']['rally']['required_packages'] =
    [ 'wget', 'build-essential', 'git', 'libssl-dev', 'libffi-dev',
      'python-dev', 'libxml2-dev', 'libxslt-dev', 'python-mysqldb' ]
end
