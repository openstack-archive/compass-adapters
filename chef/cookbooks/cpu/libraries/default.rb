def findpid(pidOrFile)
  if ::File.file?(pidOrFile)
    if ::File.readable?(pidOrFile)
      pid = ::File.read(pidOrFile).to_i
    else
      Chef::Log.error("File #{pidOrFile} isn't readable")
    end
  else
    pid = pidOrFile.to_i
  end
  # Test if pid exist
  begin
    Process.getpgid( pid )
  rescue Errno::ESRCH
    Chef::Log.error("Pid #{pid} not found")
  end
  return pid
end
