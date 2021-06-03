# configure the virtual machines network to use an already configured bridge.
# NB this must be used for connecting to the external switch.
$loki_bridge_name = 'br-rpi'
$loki_ip_address = '10.3.0.2'
$ubuntu_ip_address = '10.3.0.3'

# configure the virtual machines network to use a new private network that is
# only available inside the host.
# NB this must be used for NOT connecting to the external switch.
$loki_bridge_name = nil
$loki_ip_address = '10.11.12.2'
$ubuntu_ip_address = '10.11.12.3'

# to make sure the nodes are created sequentially, we
# have to force a --no-parallel execution.
ENV['VAGRANT_NO_PARALLEL'] = 'yes'

Vagrant.configure('2') do |config|
  config.vm.box = 'ubuntu-20.04-amd64'

  config.vm.provider :libvirt do |lv, config|
    lv.memory = 4*1024
    lv.cpus = 4
    lv.cpu_mode = 'host-passthrough'
    # lv.nested = true
    lv.keymap = 'pt'
    config.vm.synced_folder '.', '/vagrant', type: 'nfs', nfs_version: 4, nfs_udp: false
  end

  config.vm.define :loki do |config|
    config.vm.hostname = 'loki.test'
    if $loki_bridge_name
      config.vm.network :public_network,
        ip: $loki_ip_address,
        dev: $loki_bridge_name
    else
      config.vm.network :private_network,
        ip: $loki_ip_address,
        libvirt__dhcp_enabled: false,
        libvirt__forward_mode: 'none'
    end
    config.vm.provision :shell, path: 'provision-base.sh'
    config.vm.provision :shell, path: 'provision-docker.sh'
    config.vm.provision :shell, path: 'provision-docker-compose.sh'
    config.vm.provision :shell, path: 'provision-loki.sh'
    config.vm.provision :shell, path: 'provision-promtail.sh', args: [$loki_ip_address]
    config.vm.provision :shell, path: 'provision-grafana.sh'
  end

  config.vm.define :ubuntu do |config|
    config.vm.hostname = 'ubuntu.test'
    if $loki_bridge_name
      config.vm.network :public_network,
        ip: $ubuntu_ip_address,
        dev: $loki_bridge_name
    else
      config.vm.network :private_network,
        ip: $ubuntu_ip_address,
        libvirt__dhcp_enabled: false,
        libvirt__forward_mode: 'none'
    end
    config.vm.provider :libvirt do |lv, config|
      lv.memory = 2*1024
    end
    config.vm.provision :shell, path: 'provision-base.sh'
    config.vm.provision :shell, path: 'provision-docker.sh'
    config.vm.provision :shell, path: 'provision-loki-docker-driver.sh', args: [$loki_ip_address]
    config.vm.provision :shell, path: 'provision-promtail.sh', args: [$loki_ip_address]
  end

  config.trigger.before :up do |trigger|
    trigger.run = {
      inline: '''bash -euc \'
file_paths=(
~/.ssh/id_rsa.pub
)
for file_path in "${file_paths[@]}"; do
if [ -f $file_path ]; then
  mkdir -p tmp
  cp $file_path tmp
fi
done
\'
'''
    }
  end
end
