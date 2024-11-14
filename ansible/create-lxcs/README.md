
# LXC Container Creation and Configuration with Ansible
This Ansible playbook automates the process of creating and configuring LXC containers on a remote host. It starts the containers, sets up SSH access, and configures file permissions for the specified user.

## Requirements
- Ansible installed on your local machine.
- SSH access to the remote_host.
- The LXD daemon installed on the remote_host.
- Public SSH key available on the local machine to add to each container’s authorized keys.

## Inventory Configuration
Define the `remote_host` in the inventory file, specifying the `IP address` and `SSH user`.

## Variables Configuration
The `vars.yml` file contains the necessary variables for container setup. Customize the variables as needed.

## Playbook Breakdown
The `create-lxcs.yml` playbook performs the following tasks:

1. Create and Start Containers:
- Starts each container as specified in `vars.yml`.
- Pulls the OS image from the `remote_server` based on the `image_alias`.
2. Set Up SSH Directory and Permissions:
- Ensures the `.ssh` directory exists in each container and configures the correct ownership and permissions for the specified `container_user`.
3. Configure SSH Access:
- Reads the local public SSH key and appends it to the `authorized_keys` file inside each container.

## Running the Playbook
To execute the playbook:

- Clone this repository (if applicable).
- Navigate to the directory containing the playbook.
- Run the playbook using the following command:
```
ansible-playbook -i inventory create-lxcs.yml
```
This will create and configure each LXC container as defined in `vars.yml`.

## Notes
- Public Key: Ensure the `ssh_public_key_path` points to a valid SSH key on your local machine.
- LXD: The remote host must have LXD installed and configured with appropriate permissions to manage containers.
