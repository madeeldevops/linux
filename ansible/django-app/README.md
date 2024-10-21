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

5. **System User**: Ensure a system user (`project_user`) is created on the target server, who has access to the Django app directory.

## Files

- `create-django-app.yml`: Sets up the Django application environment, including creating directories and setting up virtual environments.
- `create-service.yml`: Creates systemd service and socket units for the Django application.
- `install-nginx.yml`: Installs and configures Nginx to serve the Django app through Gunicorn.
- `remove-service.yml`: Removes the systemd service and socket units.
- `vars.yml`: Stores the service-specific variables like the app name, user, and Gunicorn configuration.

## Templates

- `templates/socket.j2`: Jinja2 template for the systemd socket file.
- `templates/service.j2`: Jinja2 template for the systemd service file.
- `templates/nginx.j2`: Jinja2 template for the Nginx configuration file.

## Instructions

1. **Set Up Variables**: 
   Modify the `vars.yml` file to configure variables specific to your Django app, such as the service name, user, and Gunicorn settings.

2. **Update Inventory File (If Remote Host)**: 
   If working with a remote host over SSH, update the Ansible inventory file to include the target server. Ensure the host in your inventory file is explicitly mentioned in all your Ansible playbooks.

3. **Run the Playbooks**:

   - **Create Django App Environment**: Run the playbook to set up the Django application environment:
     ```bash
     ansible-playbook create-django-app.yml
     ```

   - **Install Nginx (if not already installed)**: Run the playbook to install and configure Nginx:
     ```bash
     ansible-playbook install-nginx.yml
     ```
     If Nginx is already installed, skip this step.

   - **Create and Start the Service**: Run the playbook to create the systemd service and socket units:
     ```bash
     ansible-playbook create-service.yml
     ```

4. **Verify the Service**: 
   Ensure the Django application service is running by checking the systemd status:
   ```bash
   sudo systemctl status <project_name>.service

5. **Remove the Service (Optional)**

To remove the service and socket units, run:
   ```bash
   sudo systemctl status <project_name>.service
   ```

## Customization

- **Service Configuration**: Customize the `project_exec_start` variable in `vars.yml` to modify the Gunicorn command used to start the Django application.

- **Nginx Configuration**: Modify the `nginx.j2` template to adjust the Nginx settings for your application.

## License

This project is licensed under the MIT License.
