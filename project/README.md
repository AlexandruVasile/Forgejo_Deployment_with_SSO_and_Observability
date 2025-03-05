# project Ansible playbook

This is the project's preconfigured Ansible playbook

## Commands

Those commands are to be run from the `VCC-control` VM

- `make requirements` installs the necessary Ansible modules
- `make ping` checks if every target is reachable
- `make setup-all` runs the _entire_ playbook starting from the beginning
- `make setup-services` runs the playbook part that builds images, templates configurations, and deploys the swarm services
- `make setup-services-reset` similar to before, but deletes existing directories and docker swarm deployments beforehand

If you are using ansible vault, add ` USEVAULT=1` to the commands above

## Usage of the swarm-services role

See its [dedicated README](roles/swarm-services/README.md)