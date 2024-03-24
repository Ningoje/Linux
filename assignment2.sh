#!/bin/bash

# Function to display errors in a human-friendly way
display_error() {
    echo "Error: $1" >&2
}

# Function to check if a command executed successfully
check_success() {
    if [ $? -ne 0 ]; then
        display_error "$1"
        exit 1
    fi
}

# Function to update netplan configuration for 192.168.16 interface
update_netplan() {
    echo "Updating netplan configuration..."
    cat <<EOF > /etc/netplan/01-netcfg.yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens3:
      dhcp4: yes
    ens4:
      dhcp4: no
      addresses: [192.168.16.21/24]
      gateway4: 192.168.16.2
      nameservers:
        addresses: [192.168.16.2]
        search: [home.arpa, localdomain]
EOF
    netplan apply
}

# Function to update /etc/hosts file
update_hosts_file() {
    echo "Updating /etc/hosts file..."
    sed -i '/192.168.16.21/d' /etc/hosts
    echo "192.168.16.21 server1" >> /etc/hosts
}

# Function to install required software
install_software() {
    echo "Installing required software..."
    apt update
    apt install -y apache2 squid
}

# Function to configure firewall using ufw
configure_firewall() {
    echo "Configuring firewall using ufw..."
    ufw allow in on ens3 to any port 22
    ufw allow in on ens4 to any port 80
    ufw allow in on ens4 to any port 3128
    ufw --force enable
}

# Function to create user accounts and set up SSH keys
create_user_accounts() {
    echo "Creating user accounts and setting up SSH keys..."
    # Add user accounts
    users=("dennis" "aubrey" "captain" "snibbles" "brownie" "scooter" "sandy" "perrier" "cindy" "tiger" "yoda")
    for user in "${users[@]}"; do
        adduser --disabled-password --gecos "" "$user"
    done

    # Set default shell to bash
    chsh -s /bin/bash dennis

    # Set up SSH keys
    mkdir -p /home/dennis/.ssh
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/dennis/.ssh/authorized_keys
    # Add other SSH keys as needed

    # Give sudo access to dennis
    usermod -aG sudo dennis
}

# Main function
main() {
    # Call each function defined above
    update_netplan
    check_success "Failed to update netplan configuration"

    update_hosts_file
    check_success "Failed to update /etc/hosts file"

    install_software
    check_success "Failed to install required software"

    configure_firewall
    check_success "Failed to configure firewall"

    create_user_accounts
    check_success "Failed to create user accounts and set up SSH keys"

    echo "Configuration completed successfully."
}

# Call the main function
main
