# NetBox Platform

Infrastructure automation for deploying a self-hosted NetBox platform on Proxmox VE.

The project separates infrastructure provisioning, operating system configuration, and application deployment into independent layers.

## Architecture

* Proxmox VE provides the virtualization platform.
* OpenTofu creates the NetBox virtual machine by cloning an Ubuntu cloud-init template.
* Cloud-init configures the hostname, network, administrative user, and SSH key.
* Ansible configures the operating system and manages services inside the virtual machine.
* Docker Compose will run NetBox and its dependencies.

## Current Status

Implemented:

* pinned OpenTofu and Proxmox provider versions
* Proxmox API authentication through environment variables
* reusable VM configuration through input variables
* full cloning from an Ubuntu 24.04 cloud-init template
* CPU, memory, disk, network, VLAN, and cloud-init configuration
* QEMU Guest Agent channel managed by OpenTofu
* local Ansible inventory excluded from version control
* Ansible connectivity and privilege escalation
* idempotent QEMU Guest Agent installation and service management
* idempotent OpenTofu and Ansible execution

Planned:

* base operating system configuration
* Docker Engine deployment
* NetBox deployment with Docker Compose
* validation and linting
* continuous integration
* backup and monitoring integration

## Repository Structure

```text
netbox-platform/
├── ansible/
│   ├── inventory/
│   │   ├── hosts.example.ini
│   │   └── hosts.local.ini
│   └── playbooks/
│       └── bootstrap.yml
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

`hosts.local.ini` contains environment-specific connection data and is excluded from version control.

## Prerequisites

* Proxmox VE
* OpenTofu 1.10 or later
* `bpg/proxmox` provider 0.113.1
* Ansible Core
* Proxmox API token with permissions required to create and clone virtual machines
* Ubuntu 24.04 cloud-init template available on the target Proxmox node
* SSH public key for the administrative user

The Ubuntu template is prepared separately and referenced through `ubuntu_template_vm_id`. It must contain a bootable Ubuntu cloud image and a cloud-init drive.

Application packages and service configuration are deliberately excluded from the template and managed through Ansible.

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

Do not commit credentials, private keys, state files, saved plans, or real environment configuration.

## Ansible Configuration

Copy the inventory example:

```bash
cp \
  ansible/inventory/hosts.example.ini \
  ansible/inventory/hosts.local.ini
```

Set the target address, administrative user, and local SSH private key path in `hosts.local.ini`.

The local inventory is excluded from Git.

Verify Ansible connectivity:

```bash
ansible \
  netbox_servers \
  -m ansible.builtin.ping
```

Verify privilege escalation:

```bash
ansible \
  netbox_servers \
  --become \
  -m ansible.builtin.ping
```

## Usage

Initialize the OpenTofu working directory:

```bash
tofu -chdir=tofu init
```

Validate the infrastructure configuration:

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

Validate the Ansible playbook:

```bash
ansible-playbook \
  --syntax-check \
  ansible/playbooks/bootstrap.yml
```

Configure the virtual machine:

```bash
ansible-playbook \
  ansible/playbooks/bootstrap.yml
```

Repeat both OpenTofu and Ansible operations after changes to verify idempotency.

## Operational Notes

OpenTofu state is currently stored locally and must be protected as operational data. A remote state backend may be introduced later.

The Ubuntu cloud-init template is an infrastructure prerequisite. OpenTofu clones the template but does not modify its base operating system.

QEMU Guest Agent requires two coordinated layers:

* OpenTofu enables the Proxmox guest-agent channel.
* Ansible installs, enables, and starts `qemu-guest-agent` inside Ubuntu.

The provider may wait for the guest agent when the Proxmox channel is enabled before the package has been installed. The initial bootstrap therefore requires working SSH access independently of the guest agent.

## Security

* secrets remain outside the repository
* local inventory, variable files, state files, and saved plans are ignored
* SSH access uses public-key authentication
* Proxmox API permissions follow least-privilege principles
* infrastructure changes are reviewed through `tofu plan`
* configuration changes are applied through idempotent Ansible playbooks
