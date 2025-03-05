[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-24ddc0f5d75046c5622901739e7c5dd533143b0c8e959d652212380cedb1ea36.svg)](https://classroom.github.com/a/wVIqdTGN)
# VCC Project 2023-2024

Hello and welcome to the VCC Project 2023-2024 repository.

Support [Giacomo](mailto:giacomo.longo@dibris.unige.it)

Look for **TODO** tags in the repository to find out which tasks are to be performed

## Usage

Use

- `vagrant up` to boot the vagrant VMs
- `vagrant destroy -f` to stop them
- `vagrant ssh VCC-control` to access the shell of the VCC control node
  - You will find the playbook inside of the `/vagrant` directory
- `vagrant ssh VCC-target1` to access the shell of the VCC first node
- `vagrant ssh VCC-target2` to access the shell of the VCC second node

## DNS names

Within the scenario machines, `controlnode.vcc.local`, `target1.vcc.local`, and `target2.vcc.local` resolve to the machines IP addresses.

On `target1` and `target2`, `registry.vcc.local` resolves to `127.0.0.1` (the loopback address).

**Remember that in order to access the project websites from your own browser you need to add host aliases pointed to one of the nodes ON YOUR HOST**
