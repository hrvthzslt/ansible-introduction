# A Very Aggressively Simple Introduction to Ansible

In this tutorial you will have a chance to trying out the automation of very simple web servers with ansible. All operations will be executed in docker containers.

## Disclaimer

When you finish this tutorial, you will not know all the basics of ansible. This tutorial is a very simple introduction to ansible. It is not a comprehensive guide.

The goal is to get a feel of what is the **point** of ansible.

## More disclaimer

In this tutorial, the containers are connected trough ssh with passwords. Although ssh is not exposed, this is not a good practice. In a real world scenario you would use ssh keys. This is just for the sake of simplicity.

## What you will need

- Docker / docker compose
- A terminal emulator
- A text editor

Follow the instructions in the lessons, and you should be alright. There is a branch called `finished` where you can check the intended final state of the project. I did not make branches per lessons, because the complexity of the project is not that high.

## Lesson 0: Introduction

### What is Ansible?

Ansible is an open-source automation tool used for IT tasks such as configuration management, application deployment.

### Building Blocks of Ansible

- **Playbook**: A file where you can write a set of instructions for Ansible to execute.
- **Inventory**: A list of hosts that Ansible manages.
- **Task**: A single procedure that you want to execute.
- **Role**: A way of organizing tasks and related files.
- **Module**: A reusable, standalone script that Ansible runs on your behalf.

So we will use an ansible **playbook** to execute a set of **tasks** arranged in **roles** on a list of hosts defined in an **inventory**.

### What is Our Main Objective?

We will set up two machines as apache web servers called `target1` and `target2`. We will use a machine called `anton` to run the ansible playbook.

These machines will be created by docker, defined in a `docker-compose.yml` file.

## Lesson 1: Environment setup

We will use docker containers to run ansible playbooks. We have a container called `anton` which will run the playbook against the another containers called `target1` and `target2`.

The contents of this repository are the volume of the `anton` container, this means that the **files and their changes** in the repository are accessible in the `anton` container.

- [ ] run `docker compose up -d` to start the environment

### Anton

`anton` represents the machine that will run the ansible playbook. In our example it is a docker container with a `root` user. It has ansible installed already.

- [ ] Access the anton with the following command

```bash
docker compose exec anton bash
```

Now you have an interactive shell in the anton container.

- [ ] Validate that ansible is available by running the following command

```bash
ansible --version
```

### Installing ansible

If you want to install ansible in your local machine, you can install it as a python package, or it could be in your distro's package manager. For example locally (and in the container) I installed it with apt.

### Targets

The target machines are the machines that will be managed by ansible. In our example we have two target machines, `target1` and `target2`. They are also docker containers with a user called `ansible` which has a password `password`. They have ssh server installed and running.

Ansible runs tasks on the target machines using ssh.

- [ ] We can validate the ssh connection to the target machines by running the following command

```bash
ssh ansible@target1
```

Again, `target1` and `target2` are accessable with the following credentials:

- user: `ansible`
- password: `password`

## Lesson 2: Discover the problem

The playbook will be the list of our tasks, but before we set up apache, we will try installing a program called `htop`.

### Install htop manually

- [ ] Access `target2` from `anton` using ssh
- [ ] Install `htop` with `sudo apt install htop`
- [ ] Run `htop` to check if it is installed

### Emulate the breakdown of our system

Now we have htop on `target2`, we should do this manually to the other targets, or all targets if our system breaks down.

Thanks to docker, we can emulate this breakdown by stopping the container of `target2`.

- [ ] Stop the container of `target2` using `docker compose down target2`
- [ ] Restart with `docker compose up -d target2`
- [ ] Enter `target2` from `anton` using ssh
- [ ] Run `htop` to check if it is installed

So we have a problem, we need to install `htop` on all targets, and we need to do it every time the system breaks down, or a new machine is added. We can automate this with ansible.

## Lesson 3: Create a playbook

- [ ] Create `main.yml` file with the following content in the root directory of the project:

```yml
---
- name: Set up apache webserver
  hosts: all
```

The `name` describes the purpose of the playbook.

The `hosts` is a list of hosts that the playbook will run on. The `all` keyword means that the playbook will run on all hosts.

- [ ] Enter the `anton` container and run the following command:

```bash
ansible-playbook main.yml
```

## Adding hosts

So we run the playbook on all hosts, but we don't have any hosts yet. Let's add some hosts.

- [ ] Create a file called `hosts` with the following content:

```ini
[webservers:vars]
ansible_connection=ssh
ansible_user=ansible

[webservers]
target1
target2
```

In this example the host file format is ini, you can use yaml as well.

The `webservers` is a group of hosts. These can be urls or ip addresses.

The `webservers:vars` section contains variables that apply to all hosts in the group.

- [ ] Enter the `anton` container and run the following command:

```bash
ansible-playbook main.yml -i hosts
```

We define the host to be targeted. We should get a permission denied error.

- [ ] Enter the `anton` container and run the following command:

```bash
ansible-playbook main.yml -i hosts --ask-pass
```

This way it will ask the password for the user `ansible`.

The playbook itself doesn't do anything but we can see that it can access the hosts.

## Lesson 4: Create a role

We will create a role for installing htop. In this case we separate roles by the installed software or service.

- [ ] You need to make te following filetree in the root of this project:

```bash
└── roles
    └── htop
        └── tasks
            └── main.yml
```

This structure will be recognized by ansible as a role. It will automatically run the tasks in the main.yml file.

- [ ] Add the role to the playbook

```yaml
---
- name: Set up apache webserver
  hosts: all
  roles:
    - htop
```

If we would run this playbook, it still would not do anything. Lets add a task to the main.yml file.

- [ ] Add the following task to the main.yml file:

```yaml
---
- name: install
  ansible.builtin.apt:
    name: htop
    state: present
  become: yes
  tags:
    - htop
```

Lets break down the task:

- The `name` defines what the task is doing.
- The `ansible.builtin.apt` is the module that is used to install the package with apt.
- The `name` under the apt module is the package that will be installed.
- The `state` under the apt module is the state of the package. In this case it is `present`, which means that the package will be installed if it is not already installed.
- The `become` is used to run the task as root.
- The `tags` are used to run only the tasks with the specified tag. We will try this later.

In essence this task means: `sudo apt install htop`.

The verbose nature of these task are important because the module will run the task by its properties in an idempotent manner, which means every run will yield the same result. This is one of the **biggest** advantages of ansible.

- [ ] Run the playbook

```bash
ansible-playbook main.yml -i hosts --ask-pass
```

We will get an error `Missing sudo password` because we are not running the playbook with sudo.

## Lesson 5: Variables and configuration

To successfully run the playbook we need to provide the sudo password.

- [ ] Run the playbook with the following command in the `anton` container:

```bash
ansible-playbook main.yml -i hosts --ask-pass --ask-become
```

- `--ask-pass` will ask for the ssh password
- `--ask-become` will ask for the sudo password

In our case, it is the same `password`, but we have to type it twice.

- [ ] Connect from `anton` to `target1` and run the following command:

```bash
htop
```

Now we can see information about the system. Nice!

### Variables

In more nuanced circumstances we would use ssh keys, but for our convenience we will add that password as a **variable** to the hosts file.

- [ ] Add the password to the hosts file (keep in mind not the best practice):

```ini
[webservers:vars]
ansible_connection=ssh
ansible_user=ansible
ansible_password=password
```

- [ ] Run the following command from the `anton` container:

```bash
ansible-playbook main.yml -i hosts --ask-become
```

Now we only have to provide the sudo password.

### Configuration

We can make the ansible command shorter by configuring the default source of hosts.

- [ ] Create a file called `ansible.cfg` with the following content:

```ini
[defaults]
inventory = hosts
```

- [ ] Run the following command from the `anton` container:

```bash
ansible-playbook main.yml --ask-become
```

Now we don't have to provide the inventory file as an option anymore.

## Lesson 6: Install apache

### Add the role

First we need to create a role for the web server. We will call it `apache`.

- [ ] Create the following filetree in the root of this project, with the following content:

```bash
└── roles
    └── apache
        └── tasks
            └── main.yml
```

```yaml
---
- name: Set up apache webserver
  hosts: all
  roles:
    - htop
    - apache
```

- [ ] Add the role to the playbook - `main.yml` in the root of the project:

Now the playbook will can run both tasks contained by the roles.

### Install apache

- [ ] Add the following task to the `main.yml` file in the `apache` role:

```yaml
---
- name: apache setup
  tags:
    - apache
  block:
    - name: install
      ansible.builtin.apt:
        name: apache2
      become: yes
```

This will install `apache` just like we did with `htop`, but there is two important differences:

- In this case the `state` is not defined, which means that the default state is `present`.
- The `block` is used to group tasks. This way when we add more tasks to the role, tags will apply to the block and we don't have to add them to every task.

Again this task is equal to `sudo apt install apache2`.

- [ ] Run the playbook on `anton`

- [ ] Access `target1` with ssh from `anton` and check if apache is installed:

```bash
which apache2
```

## Lesson 7: Setting up a web server

### Running apache as a service

- [ ] Access `target1` through ssh from `anton` and set up apache as a service:

```bash
sudo systemctl enable apache2
sudo systemctl start apache2
```

- [ ] Check if apache is running:

```bash
systemctl status apache2
```

If we visit `localhost:8001` we will get the apache default page. But visiting `localhost:8002` will not work because we did not set up apache on `target2`. Let's automate this process.

### Adding apache to systemd

- [ ] Add the following task to the `main.yml` file in the `apache` role:

```yaml
---
- name: apache setup
  tags:
    - apache
  block:
    - name: install
      ansible.builtin.apt:
        name: apache2
      become: yes
    - name: enable and start apache
      ansible.builtin.systemd:
        enabled: true
        name: apache2
        state: started
      become: true
```

- [ ] Run the playbook on `anton`.

Now `localhost:8001` and `localhost:8002` will both show the apache default page.

## Lesson 8: Serving a html page

### Adding a html page

Roles can also contain files. We will add a simple html page to the `apache` role.

- [ ] Add a files directory to the `apache` role and create a file called `index.html` in it. The file tree should look like this:

```bash
└── roles
    └── apache
        ├── files
        │   └── index.html
        └── tasks
            └── main.yml
```

- [ ] Add the following content to the `index.html` file:

```html
<h1>Hello World</h1>
```

The most inspiring html page ever innit.

### Copying the html page

- [ ] Add a task to the block in the `main.yml` file in the `apache` role to copy the `index.html` file to the apache root directory:

```yaml
- name: copy index.html
  ansible.builtin.copy:
    src: "{{ role_path }}/files/index.html"
    dest: "/var/www/html/index.html"
  become: yes
```

The `role_path` variable is a special variable that points to the directory of the role. This way we can copy the file from the role directory to the target machine.

- [ ] Run the playbook on `anton`.

Now if we visit `localhost:8001` and `localhost:8002` we will see the `Hello World` page.

### Running or skipping tasks by tags

We can run or skip tasks by tags. This is useful when we want to run only a specific task or group of tasks.

- [ ] Run the playbook on `anton` with the `apache` tag:

```bash
ansible-playbook main.yml --ask-become --tags apache
```

This way only the tasks with the `apache` tag will run.

## Summary

We have set up two apache web servers with a simple html page. We have used roles to organize our tasks and files.

This was your first ansible playbook. At this point you should understand the point of it, but not all the essential features.

You can go deep dive into the documentations, trying to automate you local environment, or changing apache to nginx in this repository. The possibilities are endless.

Thank you for reading this tutorial.
