# NetBox Platform

Infrastructure automation for deploying a self-hosted NetBox platform on
Proxmox VE.

The project separates infrastructure provisioning, operating system
configuration, container runtime management, and application deployment into
independent layers.

## Architecture

* Proxmox VE provides the virtualization platform.
* OpenTofu creates the NetBox virtual machine by cloning an Ubuntu 24.04
  cloud-init template.
* Cloud-init configures the hostname, network, administrative user, and SSH
  key.
* Ansible configures the operating system, QEMU Guest Agent, and Docker Engine.
* Docker Compose runs NetBox, PostgreSQL, Valkey, and the NetBox background
  worker.
* Ansible Vault protects application credentials and cryptographic secrets.
* GitHub Actions validates infrastructure and configuration changes.

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
* pinned project-local Ansible collections
* NetBox deployment with Docker Compose
* PostgreSQL and Valkey deployment
* persistent Docker volumes
* application and dependency health checks
* encrypted secret management with Ansible Vault
* automated NetBox superuser creation
* idempotent OpenTofu and Ansible execution
* pinned local quality-tool versions
* YAML, Ansible, Shell, Markdown, and OpenTofu validation
* unified local quality-check script
* continuous integration with GitHub Actions

Planned:

* remote OpenTofu state storage
* application and database backups
* monitoring integration
* reverse proxy and TLS termination
* dedicated NetBox API service account

## Repository Structure

```text
netbox-platform/
├── .github/
│   └── workflows/
│       └── quality.yml
├── ansible/
│   ├── inventory/
│   │   ├── group_vars/
│   │   │   └── netbox_servers/
│   │   │       ├── main.yml
│   │   │       └── vault.example.yml
│   │   └── hosts.example.ini
│   ├── playbooks/
│   │   └── bootstrap.yml
│   ├── roles/
│   │   ├── base/
│   │   │   ├── defaults/
│   │   │   │   └── main.yml
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   ├── docker/
│   │   │   ├── defaults/
│   │   │   │   └── main.yml
│   │   │   └── tasks/
│   │   │       └── main.yml
│   │   └── netbox/
│   │       ├── defaults/
│   │       │   └── main.yml
│   │       ├── tasks/
│   │       │   └── main.yml
│   │       └── templates/
│   │           ├── compose.yml.j2
│   │           ├── netbox.env.j2
│   │           ├── postgres.env.j2
│   │           ├── redis-cache.env.j2
│   │           └── redis.env.j2
│   └── requirements.yml
├── scripts/
│   └── check.sh
├── tofu/
│   ├── data.tf
│   ├── providers.tf
│   ├── terraform.example.tfvars
│   ├── variables.tf
│   ├── versions.tf
│   └── vm.tf
├── .ansible-lint
├── .gitignore
├── .markdownlint-cli2.jsonc
├── .yamllint.yml
├── ansible.cfg
├── package-lock.json
├── package.json
├── requirements-dev.txt
└── README.md
```

Local inventory, encrypted environment secrets, OpenTofu state, plan files,
installed Ansible collections, Node.js dependencies, and environment-specific
variables are excluded from Git.

## Prerequisites

### Infrastructure provisioning

* Proxmox VE
* OpenTofu 1.10 or later
* `bpg/proxmox` provider 0.113.1
* Proxmox API token with permissions required to clone and manage virtual
  machines
* Ubuntu 24.04 cloud-init template available on the target Proxmox node
* SSH public key for the administrative user

The Ubuntu template is prepared separately and referenced through
`ubuntu_template_vm_id`. It contains a bootable Ubuntu cloud image and a
cloud-init drive.

### Operating system and application configuration

* Ansible Core 2.16 or later
* SSH access to the provisioned virtual machine
* passwordless privilege escalation for the Ansible user
* access to Ubuntu, Docker, and container image repositories
* Ansible Vault password for environment secrets

The required Ansible collection versions are pinned in
`ansible/requirements.yml`.

### Local quality checks

* Python 3.12
* Node.js 18 or later
* npm
* ShellCheck
* OpenTofu

Python quality-tool versions are pinned in `requirements-dev.txt`. Markdown
tooling is pinned through `package.json` and `package-lock.json`.

## OpenTofu Configuration

Copy the public example file:

```bash
cp tofu/terraform.example.tfvars tofu/terraform.tfvars
```

Set environment-specific values in `tofu/terraform.tfvars`. This file is
excluded from Git.

Provider credentials are supplied through environment variables:

```bash
export PROXMOX_VE_ENDPOINT="https://proxmox.example.invalid:8006/"
export PROXMOX_VE_API_TOKEN="user@realm!token=secret"
export PROXMOX_VE_INSECURE="false"
```

Do not commit credentials, private keys, state files, plan files, or real
environment configuration.

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

Install the pinned Ansible collections:

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

Edit `ansible/inventory/hosts.local.ini` and set the server address, SSH user,
and private key path.

Verify inventory resolution:

```bash
ansible-inventory --graph
```

Test connectivity:

```bash
ansible netbox_servers -m ansible.builtin.ping
```

## Secret Configuration

Create the local Vault file from the public example:

```bash
cp \
  ansible/inventory/group_vars/netbox_servers/vault.example.yml \
  ansible/inventory/group_vars/netbox_servers/vault.yml
```

Encrypt the local file:

```bash
ansible-vault encrypt \
  ansible/inventory/group_vars/netbox_servers/vault.yml
```

Edit the encrypted variables:

```bash
ansible-vault edit \
  ansible/inventory/group_vars/netbox_servers/vault.yml
```

Replace every `CHANGE_ME` value with a strong, unique secret.

The local Vault file contains:

* PostgreSQL password
* primary Valkey password
* cache Valkey password
* NetBox secret key
* NetBox API token pepper
* initial NetBox superuser password

The encrypted `vault.yml` file is environment-specific and excluded from Git.
The tracked `vault.example.yml` file documents only the required variable
names.

## Platform Deployment

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
  --ask-vault-pass \
  ansible/playbooks/bootstrap.yml
```

Apply the complete platform configuration:

```bash
ansible-playbook \
  --ask-vault-pass \
  ansible/playbooks/bootstrap.yml
```

The bootstrap playbook:

* installs common system packages
* configures the system timezone
* installs and starts QEMU Guest Agent
* configures the official Docker APT repository
* installs Docker Engine and Docker Compose
* enables and starts the Docker service
* adds authorized users to the `docker` group
* deploys the NetBox Compose configuration
* renders protected application environment files
* starts PostgreSQL and Valkey
* starts the NetBox web application and background worker
* waits for the NetBox web interface to become available
* creates the initial NetBox superuser when it does not already exist

A new login session may be required after Docker group membership is changed.

## Application Stack

The Docker Compose project contains the following services:

| Service | Purpose |
| --- | --- |
| `netbox` | NetBox web application |
| `netbox-worker` | NetBox background job worker |
| `postgres` | PostgreSQL database |
| `redis` | Persistent Valkey queue backend |
| `redis-cache` | Valkey cache backend |

Application data is stored in named Docker volumes for PostgreSQL, Valkey,
NetBox media, reports, and custom scripts.

The web interface is exposed on the configured `netbox_http_port`, which
defaults to port `8000`:

```text
http://SERVER_ADDRESS:8000/
```

## Validation

Run the complete local quality gate:

```bash
./scripts/check.sh
```

The script performs:

* Git whitespace validation
* ShellCheck analysis
* YAML linting
* Ansible linting with the production profile
* Markdown linting
* OpenTofu formatting validation
* OpenTofu configuration validation

A successful run finishes with:

```text
All checks passed.
```

The same checks run automatically through GitHub Actions on every push to
`main` and on every pull request.

Check that the infrastructure remains converged:

```bash
tofu -chdir=tofu plan
```

A converged infrastructure should produce:

```text
No changes. Your infrastructure matches the configuration.
```

Check that the server and application configuration remain idempotent:

```bash
ansible-playbook \
  --ask-vault-pass \
  ansible/playbooks/bootstrap.yml
```

A fully converged environment should finish with `changed=0` and `failed=0`.

Verify Docker on the managed server:

```bash
docker version
docker compose version
systemctl is-active docker
```

Verify the application stack:

```bash
cd /opt/netbox
docker compose ps
```

All application services with configured health checks should report
`healthy`.

## Operational Notes

OpenTofu state is currently stored locally and must be protected as operational
data. A remote state backend may be introduced later.

The base Ubuntu template is an infrastructure prerequisite. Application
packages and service configuration do not belong in the template and are
managed through Ansible.

The Docker role uses Docker's official Ubuntu repository instead of
distribution-provided Docker packages.

The initial NetBox superuser is created only when the configured username does
not already exist. Repeated playbook runs do not reset its password.

The NetBox API token pepper is configured, but a superuser API token is
intentionally not created. API automation should use a dedicated service
account with the minimum required permissions.

## Security

* secrets are encrypted with Ansible Vault
* the environment-specific Vault file is excluded from Git
* rendered application environment files are owned by `root` with mode `0600`
* local inventory and OpenTofu variable files are excluded from Git
* state and plan files are excluded from Git
* installed Ansible collections are not committed
* Node.js dependencies are not committed
* SSH access uses public-key authentication
* Proxmox API permissions should follow least-privilege principles
* infrastructure changes must be reviewed through `tofu plan`
* configuration changes should be reviewed through Ansible check mode
* application API access should use dedicated least-privilege accounts
* repository changes are validated through GitHub Actions
