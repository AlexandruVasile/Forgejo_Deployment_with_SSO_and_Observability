### configuration parameters ###
NUM_TARGET = 2

# VMWare: see NAT network
# VirtualBox: see VirtualBox Host-Only Ethernet Adapter (remember to disable Windows Firewall)
MYNET = "192.168.88"

CPUS = 2
RAM = 4096

LOCAL_BOX = false
DEFAULT_PROVIDER = 'vmware'

KEY_FILE_PATH = nil

### calculate config ###
if LOCAL_BOX
  VM_IMAGE = "VCCubuntu22.04"
  VM_IMAGE_VER = "0"
else
  VM_IMAGE = "enricorusso/VCCubuntu"
  VM_IMAGE_VER = "22.04.3"
end


for path in [
  File.join(ENV['HOME'], ".ssh", "id_rsa.pub"),
  File.join(ENV['HOME'], ".ssh", "id_ecdsa.pub"),
  File.join(ENV['HOME'], ".ssh", "id_ed25519.pub"),
  File.expand_path("~/.ssh/id_rsa.pub"),
  File.expand_path("~/.ssh/id_ecdsa.pub"),
  File.expand_path("~/.ssh/id_ed25519.pub"),
]
  if File.exist?(path)
    KEY_FILE_PATH = path
    break 
  end
end


Vagrant.configure("2") do |config|
  (1..NUM_TARGET+1).reverse_each do |i|
    # Specialize settings
    management_eth = "eth0"
    storage_eth = "eth1"

    management_ip = "#{MYNET}.#{i+9}"
    management_mac = "00:0c:29:8b:0a:7#{i}"

    storage_ip = "10.255.255.#{i+9}"
    storage_mac = "00:0c:29:8b:0b:7#{i}"

    if i == 1 then
      name = "VCC-control"
      hostname = "control"
    else
      target_i = i - 1
      name = "VCC-target#{target_i}"
      hostname = "target#{target_i}"
    end

    # Prepare VM
    config.vm.define name do |node|
      node.vm.box = "#{VM_IMAGE}"
      node.vm.box_version = "#{VM_IMAGE_VER}"

      node.vm.hostname = hostname
      node.vm.network :forwarded_port, guest: 22, host: "220#{i}", id: 'ssh' 

      #
      # Libvirt exclusive provider configuration
      #
      if ENV['VAGRANT_PROVIDER'] == 'libvirt' || DEFAULT_PROVIDER == 'libvirt'
        node.vm.provider :libvirt do |libvirt|
          libvirt.title = i == 1 ? "VCC-control" : "VCC-target#{i-1}"
          libvirt.cpus = CPUS
          libvirt.memory = RAM

          libvirt.random :model => 'random'

          libvirt.management_network_name = "vcc-controlnet"
          libvirt.management_network_address = "#{MYNET}.0/24"
          libvirt.management_network_mode = "nat"
          libvirt.management_network_mac = management_mac
        end

        if i != 1
          node.vm.network :private_network,
            :libvirt__dhcp_enabled => false,
            :libvirt__network_name => "vcc-internal",
            :libvirt__mac => storage_mac,
            :libvirt__forward_mode => "none",
            :libvirt__adapter => 1
        end
      elsif ENV['VAGRANT_PROVIDER'] == 'vmware' || DEFAULT_PROVIDER == 'vmware'
        node.vm.base_mac = management_mac
        node.vm.base_address = management_ip

        node.vm.provider :vmware_workstation do |v|
          v.gui = true
          v.vmx["displayname"] = i == 1 ? "VCC-control" : "VCC-target#{i-1}"
          v.vmx["memsize"] = "#{RAM}"
          v.vmx["numvcpus"] = "#{CPUS}"
        
          # ethernet0
          v.vmx["ethernet1.present"] = "TRUE"
          v.vmx["ethernet1.addresstype"] = "static"
          v.vmx["ethernet1.address"] = management_mac
          v.vmx["ethernet1.connectiontype"] = "NAT"
  
          # ethernet1
          v.vmx["ethernet0.present"] = "TRUE"
          v.vmx["ethernet0.addresstype"] = "static"
          v.vmx["ethernet0.address"] = storage_mac
          v.vmx["ethernet0.connectiontype"] = "custom"
          v.vmx["ethernet0.vnet"] = "VMnet1"
        end
      elsif ENV['VAGRANT_PROVIDER'] == 'virtualbox' || DEFAULT_PROVIDER == 'virtualbox'
          management_eth = "eth2"
          storage_eth = "eth1"

          # remove the following two lines if it errors out on boot complaining about a conflict
          node.vm.network "private_network", :type => 'dhcp'
          node.vm.network "private_network", :type => 'dhcp'

          node.vm.provider :virtualbox do |virtualbox|
            virtualbox.name = i == 1 ? "VCC-control" : "VCC-target#{i-1}"

            virtualbox.memory = "#{RAM}"
            virtualbox.cpus = "#{CPUS}"

            # ethernet2
            virtualbox.customize ["modifyvm", :id, "--macaddress3", management_mac.tr(':', '') ]
            virtualbox.customize ["modifyvm", :id, "--nic3", "hostonly", "--hostonlyadapter3", "VirtualBox Host-Only Ethernet Adapter"]
            # ethernet1
            virtualbox.customize ["modifyvm", :id, "--nic2", "hostonly", "--hostonlyadapter2", "VirtualBox Host-Only Ethernet Adapter #2"]
            virtualbox.customize ["modifyvm", :id, "--macaddress2", storage_mac.tr(':', '') ]
        end
      end

      # copy ssh key
      if KEY_FILE_PATH != nil
        ssh_pub_key = File.readlines(KEY_FILE_PATH).first.strip
        node.vm.provision :shell, :inline => <<-SHELL
          echo #{ssh_pub_key} >> /home/vagrant/.ssh/authorized_keys
          chown -R vagrant:vagrant /home/vagrant/.ssh/authorized_keys
          chmod 0644 /home/vagrant/.ssh/authorized_keys

          echo #{ssh_pub_key} >> /root/.ssh/authorized_keys
          chown -R root:root /root/.ssh/authorized_keys
          chmod 0644 /root/.ssh/authorized_keys
        SHELL
      end

      # configure netplan and SSH dir
      $script = <<-EOS
        chown -R vagrant:vagrant /home/vagrant/.ssh
        chmod 0700 /home/vagrant/.ssh
        echo -en '---
        network:
          version: 2
          renderer: networkd
          ethernets:
            #{management_eth}:
              match:
                macaddress: "#{management_mac}"
              dhcp4: true
              addresses:
                - #{management_ip}/24
              nameservers:
                search: [ "vcc.local" ]
            #{storage_eth}:
              match:
                macaddress: "#{storage_mac}"
              dhcp4: false
              addresses:
                - #{storage_ip}/24
              nameservers:
                search: [ "vcc.local" ]' > /etc/netplan/99-vcc.yaml
        chmod 0700 /etc/netplan
        chmod -R 0600 /etc/netplan/*
        ip addr flush dev #{management_eth}
        ip addr flush dev #{storage_eth}
        netplan apply
      EOS
      node.vm.provision :shell, :inline => $script

      # disable default sync
      config.vm.synced_folder '.', '/vagrant', disabled: true

      # configuration common to all nodes
      (1..NUM_TARGET+1).each do |j|
        # add host alias
        name = j == 1 ? 'controlnode' : "target#{j-1}"
        node.vm.provision :shell, :privileged => true, :inline => <<-SHELL
          if ! grep #{MYNET}.#{j+9} /etc/hosts; then
            echo '#{MYNET}.#{j+9} #{name}.vcc.local' >> /etc/hosts
          fi
        SHELL
      end

      # first node specific configuration
      if i == 1
        # sync ansible shared folder
        if DEFAULT_PROVIDER == 'vmware'
          config.vm.synced_folder "./project", "/vagrant"
        elsif DEFAULT_PROVIDER == 'libvirt'
          config.vm.synced_folder "./project", "/vagrant", type: "sshfs"
        elsif DEFAULT_PROVIDER == 'virtualbox'
          config.vm.synced_folder "./project", "/vagrant", type: "virtualbox"
        else
          config.vm.synced_folder "./project", "/vagrant", type: "rsync", rsync__exclude: [ ".git/", "packer" ]
        end

        # install ansible
        node.vm.provision :shell, :privileged => true, :inline => <<-SHELL
          if (! [ -x "$(command -v ansible)" ]); then
            apt-get update
            apt-get install -y ansible make sshpass
          fi
        SHELL

        # create SSH key
        node.vm.provision :shell, :privileged => false, :inline => <<-SHELL
          ls -la /home/vagrant/.ssh
          test -f /home/vagrant/.ssh/id_rsa || ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -q -P ""
        SHELL

        # add ssh key to other nodes
        (2..NUM_TARGET+1).each do |j|
          node.vm.provision :shell, :privileged => false, :inline => <<-SHELL
            sshpass -p vagrant ssh-copy-id -o StrictHostKeyChecking=accept-new vagrant@target#{j-1}.vcc.local
          SHELL
        end

        # configure ansible
        node.vm.provision :shell, :privileged => false, :inline => <<-SHELL
          echo -e '[defaults]\npipelining = True\nhost_key_checking = False' > ~/.ansible.cfg
        SHELL
      end
    end
  end
end
