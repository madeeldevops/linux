# Django Application Deployment with Ansible

This project provides an Ansible-based setup to automate the deployment of a Django application. It creates and manages systemd service and socket units for running the application and configures Nginx as a reverse proxy.

## Prerequisites

Before running the Ansible playbooks, ensure the following prerequisites are met:

1. **Ansible Installed**: Ensure you have Ansible installed on your local machine.
   - **Install Ansible**:
     ```bash
     sudo apt update
     sudo apt install ansible
     ```

2. **SSH Access**: SSH access to the target server where the Django application and Nginx will be installed.

3. **Django Application**: The Django app should be set up on the server, including the virtual environment and Gunicorn installed.

4. **Python**: The server must have Python 3 and virtualenv installed.

5. **System User**: Ensure a system user (`service_user`) is created on the target server, who has access to the Django app directory.

## Files

- `create-service.yml`: Creates systemd service and socket units for the Django application.
- `install-nginx.yml`: Installs and configures Nginx to serve the Django app through Gunicorn.
- `remove-service.yml`: Removes the systemd service and socket units.
- `vars.yml`: Stores the service-specific variables like the app name, user, and Gunicorn configuration.
  
## Templates

- `templates/socket.j2`: Jinja2 template for the systemd socket file.
- `templates/service.j2`: Jinja2 template for the systemd service file.
- `templates/nginx.j2`: Jinja2 template for the Nginx configuration file.

## Instructions

1. **Clone the Repository**: 
   ```bash
   git clone <your-repository-url>
   cd <repository-directory>

2. **Configure Variables**: Modify the vars.yml file to fit your application configuration, such as the service name, user, and Gunicorn setup. 

3. **Install Nginx**: Run the playbook to install and configure Nginx:
   ```bash
   ansible-playbook install-nginx.yml 

4. **Create and Start the Service**: Run the playbook to create the systemd service and socket units:
   ```bash
   ansible-playbook create-service.yml 

5. **Enable and Start the Service**: The playbook will enable and start the Django service and socket units automatically. Verify the service is running:
   ```bash
   sudo systemctl status <service_name>.service
 
6. **Remove the Service (Optional)**: To remove the service and socket units, run:
   ```bash
   ansible-playbook remove-service.yml -i 

## Customization
- **Service Configuration**: Customize the service_exec_start variable in vars.yml to modify the Gunicorn command used to start the Django application.

- **Nginx Configuration**: Modify the nginx.j2 template to adjust the Nginx settings for your application.

## License
This project is licensed under the MIT License.

```bash

This `README.md` includes an overview of the project, prerequisites, a brief description of the files, instructions to run the playbooks, and customization options.



