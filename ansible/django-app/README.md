# Django Application Deployment with Ansible

This repository provides an Ansible-based solution to automate the deployment of a Django application. The playbook configures the necessary dependencies, sets up the Django application, Nginx, and systemd service files, ensuring a reliable, production-ready deployment.

## Table of Contents

- **Overview**
- **Configuration Files**
    - **deploy.yml**
    - **Inventory**
    - **Variables**
    - **Roles**
- **Usage**
- **Roles Breakdown**
    - **Django app**
    - **Nginx**
    - **Systemd Service**
- **Notes**

## Overview

This setup leverages Ansible roles to streamline and organize the deployment of a Django application. It includes roles for handling dependencies, configuration, and service management, making it an ideal solution for automated deployments in environments like LXC containers or other similar setups.

# Django Application Deployment with Ansible

This repository contains Ansible playbooks and configuration files to automate the deployment of a Django application on LXC containers. The deployment process is defined in `deploy.yml` and utilizes roles for modular and organized management.

## Configuration Files

### `deploy.yml`
This file is the main entry point for the deployment process. It orchestrates the setup and deployment of the Django application by defining necessary roles and importing global variables from `vars.yml`.

## Inventory

The inventory file defines the target hosts where the playbook will be executed. In this case, it includes the list of LXC containers on which the Django application and associated services will be deployed. Replace `<user>` and `<ip>` with the actual username and IP address of your target server.

## Global Variables - `vars.yml`

The `vars.yml` file contains global variables that are used across various roles in the deployment process. Defining variables in this file makes it easy to manage and update settings for the entire deployment.

## Usage

To deploy the Django application using this Ansible setup, follow these steps:

1. Update the inventory file with the target host details.

2. Update vars.yml with your project-specific settings.

3. Run the playbook:
```bash
ansible-playbook -i inventory deploy.yml
```
## Roles Breakdown

This deployment uses a structured approach with Ansible roles to ensure modular, organized, and reusable configurations. Here’s a detailed breakdown of each role:

### Django App (`django_app`)
The `django_app` role handles setting up the Django application environment, including Python dependencies, code cloning, and virtual environment configuration.

#### Key Tasks:
- **Install Python3, pip, and virtualenv**: Ensures the target system has all necessary Python tools for the Django app.
- **Clone the project from GitHub**: Uses the `repo_url` variable from `vars.yml` to clone the Django application code.
- **Create a virtual environment and install required packages**: Sets up an isolated Python environment and installs dependencies from `requirements.txt`.

### Nginx (`nginx`)
The `nginx` role installs and configures Nginx to act as a reverse proxy for the Django application, routing incoming HTTP requests to the Django application’s Unix socket.

#### Key Tasks:
- **Install Nginx**: Installs the Nginx web server on the target host.
- **Generate Nginx configuration**: Creates the Nginx configuration file from the `nginx.conf.j2` template, specifying the proxy settings for the Django application.
- **Enable the Nginx site and start the service**: Links the generated configuration to Nginx’s sites-enabled directory and ensures Nginx is running.

#### Handlers:
- **Reload Nginx**: This handler automatically reloads Nginx whenever the configuration file changes, applying the new settings without downtime.

### Systemd Service (`systemd_service`)
The `systemd_service` role sets up systemd to manage the Django application as a service, allowing it to start on boot and restart automatically on failure.

#### Key Tasks:
- **Create and enable `.service` and `.socket` files**: Generates systemd service and socket files from templates (`service.j2` and `socket.j2`) for managing the Django application.
- **Reload the systemd daemon**: Ensures systemd recognizes the new service and socket files.
- **Start and enable the application service and socket**: Starts the Django application as a service and enables it to automatically start on system boot.

Each role is designed to be independent and reusable, making it easy to customize or extend this setup for different environments.
## Notes

- **Ansible Installation**: Ensure that Ansible is installed on your local machine or control node. The target machine should also be configured to accept SSH connections from the control node to facilitate automated deployments.

- **SSH Access**: Verify that you can SSH into the target machine(s) specified in the `inventory` file. SSH access is essential for Ansible to execute commands on the remote hosts.

- **Customize `vars.yml`**: Before running the playbook, update the `vars.yml` file with your project-specific details:
  - **Repository URL**: Set the Git repository URL for your Django application.
  - **Project Directory**: Define the directory path on the target host where the project will be deployed.
  - **Required Packages**: List any additional packages or dependencies needed for your Django application in `requirements.txt`.

These preparatory steps ensure a smooth, error-free deployment process.

