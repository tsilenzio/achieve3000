Vagrant.configure("2") do |config|
    config.vm.box = "bento/ubuntu-18.04"
    config.vm.provision "shell", path: "scripts/provision.sh", privileged: true
    config.vm.provision "shell", path: "scripts/start.sh", run: "always", privileged: true
    config.vm.network :forwarded_port, guest: 80, host: 80

    if Vagrant.has_plugin?("vagrant-vbguest")
        config.vbguest.auto_update = false  
    end
end
