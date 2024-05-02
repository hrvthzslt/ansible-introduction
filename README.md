# Ansible introduction

Introduction for writing and running an ansible playbook

## Set up environment

We will use docker containers to run ansible playbooks. We will have a container called `anton` which will run the playbook against the another containers called `target1` and `target2`.

### Access the anton container

Start a bash interactive shell in the anton container

```bash
docker compose exec anton bash
```

Ansible uses ssh to connect to the target machines. We can validate the ssh connection to the target machines by running the following command

```bash
ssh ansible@target1
```

The target user is `ansible` and the password is `password`, the ssh passpharse is `password` as well.

## Lessons

### Explore the envrionment

- Describe the containers
- Start the environment
- Enter anton container
- Ssh to target1

### Explain ansible

- Running task in a headless manner
- Running the ansible-playbook command

### Playbook

- Explain playbook
- Write the main.yml
```yaml
---
- name: Set up desktop environment
```

### Hosts

- Explain hosts files
- Write the hosts file

### Configuration

- Set up ansible.cfg default host

### Install ncal on targets

### Install apache on targets
