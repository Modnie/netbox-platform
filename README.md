# NetBox Platform

Infrastructure automation for deploying a self-hosted NetBox platform on Proxmox VE.

The project separates infrastructure provisioning, operating system configuration, and application deployment into independent layers.

## Architecture

* Proxmox VE provides the virtualization platform.
* OpenTofu creates the NetBox virtual machine by cloning an Ubuntu cloud-init template.
* Cloud-init configures the hostname, network, administrative user, and SSH key.
* Ansible configures the operating system and installs Docker Engine.
* Docker Compose will run NetBox and its dependencies.

## Current Status

Implemented:

* pinned OpenTofu and Proxmox provider versions
* Proxmox API authentication through environment variables
* reusable VM configuration through input variables
* full cloning from an Ubuntu 24.04 cloud-init template
* CPU, memory, disk, network, VLAN, and cloud-init configuration
* QEMU Guest Agent installation and integration
* Ansible inventory and project configuration
* reusable base system role
* timezone and base package configuration
* official Docker APT repository configuration
* Docker Engine and Docker Compose plugin installation
* Docker service management
* administrative user access to Docker
* idempotent OpenTofu and Ansible execution

Planned:

* NetBox deployment with Docker Compose
* persistent storage and secret management
* application health checks
* validation and linting
* continuous integration
* backup and monitoring integration

## Repository Structure

```text
netbox-platform/
├── ansible/
│   ├── inventory/
│   │   └── hosts.example.ini
│   ├── playbooks/
│   │   └── bootstrap.yml
│   ├── roles/
│   │   ├── base/
│   │   │   ├── defaults/
│   │   │   │   └── main.yml
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   └── docker/
│   │       ├── defaults/
│   │       │   └── main.yml
│   │       └── tasks/
│   │           └── main.yml
│   └── requirements.yml
├── tofu/
│   ├── data.tf
│   ├── providers.tf
│   ├── terraform.example.tfvars
│   ├── variables.tf
│   ├── versions.tf
│   └── vm.tf
├── ansible.cfg
├── .gitignore
└── README.md
```

Local inventory, credentials, OpenTofu state, plan files, installed Ansible collections, and environment-specific variables are excluded from Git.

## Prerequisites

### Infrastructure provisioning

* Proxmox VE
* OpenTofu 1.10 or later
* `bpg/proxmox` provider 0.113.1
* Proxmox API token with permissions required to clone and manage virtual machines
* Ubuntu 24.04 cloud-init template available on the target Proxmox node
* SSH public key for the administrative user

The Ubuntu template is prepared separately and referenced through `ubuntu_template_vm_id`. It contains a bootable Ubuntu cloud image and a cloud-init drive.

### Operating system configuration

* Ansible Core 2.16 or later
* SSH access to the provisioned virtual machine
* passwordless privilege escalation for the Ansible user
* access to Ubuntu and Docker package repositories

## OpenTofu Configuration

Copy the public example file:

```bash
cp tofu/terraform.example.tfvars tofu/terraform.tfvars
```

Set environment-specific values in `tofu/terraform.tfvars`. This file is excluded from Git.

Provider credentials are supplied through environment variables:

```bash
export PROXMOX_VE_ENDPOINT="https://proxmox.example.invalid:8006/"
export PROXMOX_VE_API_TOKEN="user@realm!token=secret"
export PROXMOX_VE_INSECURE="false"
```

Do not commit credentials, private keys, state files, plan files, or real environment configuration.

## Infrastructure Deployment

Initialize the OpenTofu working directory:

```bash
tofu -chdir=tofu init
```

Format and validate the configuration:

```bash
tofu -chdir=tofu fmt -check
tofu -chdir=tofu validate
```

Review the proposed infrastructure changes:

```bash
tofu -chdir=tofu plan
```

Apply an approved plan:

```bash
tofu -chdir=tofu plan -out=deployment.tfplan
tofu -chdir=tofu apply deployment.tfplan
```

## Ansible Configuration

Install the required Ansible collections:

```bash
ansible-galaxy collection install \
  -r ansible/requirements.yml \
  -p ansible/collections
```

Create the local inventory:

```bash
cp \
  ansible/inventory/hosts.example.ini \
  ansible/inventory/hosts.local.ini
```

Edit `ansible/inventory/hosts.local.ini` and set the real server address, SSH user, and private key path.

Verify inventory resolution:

```bash
ansible-inventory --graph
```

Test connectivity:

```bash
ansible netbox_servers -m ansible.builtin.ping
```

## Server Bootstrap

Check the playbook syntax:

```bash
ansible-playbook \
  --syntax-check \
  ansible/playbooks/bootstrap.yml
```

Preview the configuration:

```bash
ansible-playbook \
  --check \
  ansible/playbooks/bootstrap.yml
```

Apply the base system and Docker configuration:

```bash
ansible-playbook ansible/playbooks/bootstrap.yml
```

The bootstrap playbook currently:

* installs common system packages
* configures the system timezone
* installs and starts QEMU Guest Agent
* configures the official Docker APT repository
* installs Docker Engine and Docker Compose
* enables and starts the Docker service
* adds authorized users to the `docker` group

A new login session may be required after Docker group membership is changed.

## Validation

Check that the infrastructure configuration remains idempotent:

```bash
tofu -chdir=tofu plan
```

Check that the server configuration remains idempotent:

```bash
ansible-playbook ansible/playbooks/bootstrap.yml
```

A fully converged environment should produce no OpenTofu changes and an Ansible recap with `changed=0` and `failed=0`.

Verify Docker on the managed server:

```bash
docker version
docker compose version
systemctl is-active docker
```

## Operational Notes

OpenTofu state is currently stored locally and must be protected as operational data. A remote state backend may be introduced later.

The base Ubuntu template is an infrastructure prerequisite. Application packages and service configuration do not belong in the template and are managed through Ansible.

The Docker role uses Docker's official Ubuntu repository instead of distribution-provided Docker packages.

## Security

* secrets remain outside the repository
* local inventory and variable files are ignored
* state and plan files are ignored
* installed Ansible collections are not committed
* SSH access uses public-key authentication
* Proxmox API permissions should follow least-privilege principles
* infrastructure changes must be reviewed through `tofu plan`
* configuration changes should be reviewed through Ansible check mode
