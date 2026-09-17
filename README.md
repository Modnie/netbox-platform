# NetBox Platform

Infrastructure automation for deploying a self-hosted NetBox platform on Proxmox VE.

The project separates infrastructure provisioning, operating system configuration, and application deployment into independent layers.

## Architecture

* Proxmox VE provides the virtualization platform.
* OpenTofu creates the NetBox virtual machine by cloning an Ubuntu cloud-init template.
* Cloud-init configures the hostname, network, administrative user, and SSH key.
* Ansible will configure the operating system and install the required platform components.
* Docker Compose will run NetBox and its dependencies.

## Current Status

Implemented:

* pinned OpenTofu and Proxmox provider versions
* Proxmox API authentication through environment variables
* reusable VM configuration through input variables
* full cloning from an Ubuntu 24.04 cloud-init template
* CPU, memory, disk, network, VLAN, and cloud-init configuration
* idempotent infrastructure plans

Planned:

* operating system configuration with Ansible
* QEMU Guest Agent installation
* Docker Engine deployment
* NetBox deployment with Docker Compose
* validation and linting
* continuous integration
* backup and monitoring integration

## Repository Structure

```text
netbox-platform/
├── tofu/
│   ├── data.tf
│   ├── providers.tf
│   ├── terraform.example.tfvars
│   ├── variables.tf
│   ├── versions.tf
│   └── vm.tf
├── .gitignore
└── README.md
```

## Prerequisites

* Proxmox VE
* OpenTofu 1.10 or later
* `bpg/proxmox` provider 0.113.1
* Proxmox API token with permissions required to create and clone virtual machines
* Ubuntu 24.04 cloud-init template available on the target Proxmox node
* SSH public key for the administrative user

The Ubuntu template is prepared separately and referenced through `ubuntu_template_vm_id`. It must contain a bootable Ubuntu cloud image and a cloud-init drive.

## Configuration

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

Do not commit credentials, private keys, state files, or real environment configuration.

## Usage

Initialize the working directory:

```bash
tofu -chdir=tofu init
```

Validate the configuration:

```bash
tofu -chdir=tofu fmt -check
tofu -chdir=tofu validate
```

Review the proposed changes:

```bash
tofu -chdir=tofu plan
```

Apply an approved plan:

```bash
tofu -chdir=tofu plan -out=deployment.tfplan
tofu -chdir=tofu apply deployment.tfplan
```

## Operational Notes

OpenTofu state is currently stored locally and must be protected as operational data. A remote state backend may be introduced later.

The base Ubuntu template is an infrastructure prerequisite. Application packages and service configuration do not belong in the template and will be managed through Ansible.

QEMU Guest Agent is intentionally installed after the first VM deployment. Initial provisioning therefore does not depend on the agent being available.

## Security

* secrets remain outside the repository
* local variable files and state files are ignored
* SSH access uses public-key authentication
* Proxmox API permissions should follow least-privilege principles
* infrastructure changes must be reviewed through `tofu plan`
