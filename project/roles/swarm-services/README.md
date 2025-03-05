swarm-services
==============

Configures docker swarm services

Role Variables
--------------

| **Name**                         | **Description**                                            | **Default value** |
| -------------------------------- | ---------------------------------------------------------- | ----------------- |
| `swarm_force_reset_all_services` | Enable the reset functionality                             | `true`            |
| `swarm_services_data_dirs`       | A list of directories to create inside of `/data/services` | `[]`              |

_please notice that_ `swarm_services_data_dirs` _is a list of objects_ so you should use

```yaml
swarm_services_data_dirs:
  - name: service
```

and not

```yaml
swarm_services_data_dirs:
  - service
```

Data directory creation
-----------------------

Every directory listed under `swarm_services_data_dirs` will be created under `/data/services/<item.name>`

_Please ensure all of your persistent volumes are mounted from that location_

Image build and upload
----------------------

Every directory found under `templates/configs/images` containing a `Dockerfile` will automatically be built and uploaded to the `registry.vcc.local` registry.

The image name will be `vcc-<name under images>` with tag `latest`.

Each run of this role will build, push, and force pull every image on _every_ node.

Configuration files templating
------------------------------

Every file or directory under `templates/configs` will be templated using `ansible.builtin.template` to `/data/configs`.

Please use this facility for your configuration files

Docker swarm file templating
----------------------------

The `docker-compose.yml` found under `templates` will be rendered using `ansible.builtin.template` and subsequentely deployed on each run
