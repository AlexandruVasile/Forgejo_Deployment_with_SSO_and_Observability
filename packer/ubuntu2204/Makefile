ubuntu-22.04.3-live-server-amd64.iso:
	wget -O $@ https://releases.ubuntu.com/22.04/ubuntu-22.04.3-live-server-amd64.iso

.PHONY: build-vmware
build-vmware: ubuntu-22.04.3-live-server-amd64.iso
	rm -rf build
	packer build vmware.pkr.hcl

.PHONY: build-qemu
build-qemu: ubuntu-22.04.3-live-server-amd64.iso
	rm -rf build
	packer build qemu.pkr.hcl

.PHONY: vagrant-add
vagrant-add:
	if [ -f build/libvirt-VCCubuntu2204.box ]; then \
		vagrant box add --force --name VCCubuntu22.04 build/libvirt-VCCubuntu2204.box; \
	fi
	if [ -f build/vmware-VCCubuntu2204.box ]; then \
		vagrant box add --force --name VCCubuntu22.04 build/vmware-VCCubuntu2204.box; \
	fi