#!/bin/sh

# author: CX
# last edited: 2025-01-16

###########################################################################################################
#
# NOTICE: 
# This script has been tested on Ubuntu 22.04 LTS, it is not guaranteed to work on other systems.
#
############################################################################################################

# if any command inside script returns error, exit and return that error
set -e

install_proxy(){
	# Install the necessary dependencies
	# Check if there is a existing proxy
	if [ clash -v ]; then
		echo "No proxy detected. Installing."
		sudo apt-get update
		sudo apt-get -y install curl wget jq
		cd /tmp \
		&& rm -f clash* || true \
		&& wget https://github.com/Kuingsmile/clash-core/releases/download/1.18/clash-linux-amd64-v1.18.0.gz || true \
		&& gzip -d clash* \
		&& mv clash* clash \
		&& chmod +x clash \
		&& sudo mv clash /usr/local/bin/clash
		if [clash -v]; then
			echo "Proxy installed successfully."
			return 0
		else
			echo "Proxy installation failed."
			echo "Please download the proxy util manually at https://www.socketpro.info/zh/download/clash-linux-amd64 and put it at ~/usr/local/bin/clash"
			echo "Then run the script again."
			return 1
		fi
	else
		echo "Proxy detected. Skipping."
		return 0
	fi
}
run_proxy(){
	mkdir -p ~/.config/clash
	wget https://raw.githubusercontent.com/Iachryphagy/Image_server/refs/heads/main/config.yaml -O ~/.config/clash/config.yaml
	if [-e ~/.config/clash/config.yaml]; then
		echo "Proxy Config file downloaded successfully."
	else
		echo "Failed to download proxy config file."
		echo "Please download the proxy util manually at https://raw.githubusercontent.com/Iachryphagy/Image_server/refs/heads/main/config.yaml and put it at ~/.config/clash/config.yaml"
		echo "Then run the script again."
		return 1
	fi
	# Run the proxy
	if [clash &]; then
		curl -s -X PUT http://127.0.0.1:9090/proxies/Proxy --data "{\"name\":\"hongkong\"}"
		echo "Proxy is running."
	else
		echo "Proxy is not installed."
		echo "Please check messages above."
	fi
	if [ping -c 1 google.com]; then
		echo "Proxy is working."
	else
		echo "Please prepare your network environment properly."
		return 1
	fi
}
##########################################################################
# References:
#
# https://docs.docker.com/engine/install/ubuntu/
#
##########################################################################

install_docker() {
	# Check if there is any conflict package
	for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done
	if [ docker ]; then
		echo "Docker has been installed. Skipping."
		return 0
	else
		# Add Docker's official GPG key:
		sudo apt-get update
		sudo apt-get install ca-certificates curl
		sudo install -m 0755 -d /etc/apt/keyrings
		sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
		sudo chmod a+r /etc/apt/keyrings/docker.asc

		# Add the repository to Apt sources:
		echo \
		"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
		$(. /etc/os-release && echo "$UBUNTU_CODENAME") stable" | \
		sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
		sudo apt-get update

		# Install the latest version of Docker:
		sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
		# Verify that Docker is installed correctly by running the hello-world image:
		if sudo docker run hello-world; then
			echo "Docker installed successfully."
		else
			# May fail, if fail due to network error:
			sudo mkdir -p /etc/docker
			# Write the mirror to the docker config file
			sudo tee /etc/docker/daemon.json <<-'EOF'
			{
				"registry-mirrors": [
					"https://docker-0.unsee.tech",
					"https://docker-cf.registry.cyou",
					"https://docker.1panel.live"
				]
			}
			EOF
			# reboot docker
			sudo systemctl daemon-reload && sudo systemctl restart docker

		fi
	fi
}

##########################################################################
# References:
#
# https://docs.sylabs.io/guides/3.9/admin-guide/installation.html#install-from-provided-rpm-deb-packages
#
##########################################################################

install_singularity() {

	# Install the Singularity dependencies:
	sudo apt-get update && sudo apt-get install -y build-essential uuid-dev libgpgme-dev squashfs-tools libseccomp-dev wget pkg-config git cryptsetup-bin

	# Configure and Install the Go support:

	# Notice：
	# there may be a problem connecting to the download link under the domain "google.com",
	# you can download it manually and put it in the same directory as the script.
	export VERSION=1.17.6 OS=linux ARCH=amd64 && \
    wget https://dl.google.com/go/go$VERSION.$OS-$ARCH.tar.gz && \
    sudo tar -C /usr/local -xzvf go$VERSION.$OS-$ARCH.tar.gz && \
    rm go$VERSION.$OS-$ARCH.tar.gz
	# Setup environment variables
	if [ -z "$GOPATH" ]; then
		echo 'export GOPATH=${HOME}/go' >> ~/.bashrc && \
    	echo 'export PATH=/usr/local/go/bin:${PATH}:${GOPATH}/bin' >> ~/.bashrc && \
    	source ~/.bashrc
	fi

	# Install Singularity
	export VERSION=3.9.2 && # adjust this as necessary \
    wget https://github.com/sylabs/singularity/releases/download/v${VERSION}/singularity-ce-${VERSION}.tar.gz && \
    tar -xzf singularity-ce-${VERSION}.tar.gz && \
    cd singularity-ce-${VERSION}
	# SingularityCE uses a custom build system called makeit. mconfig is called to generate a Makefile and then make is used to compile and install.
	# The --prefix flag is used to specify the installation directory. The default is /usr/local.
	./mconfig --prefix=//usr/local && \ 
    make -C ./builddir && \
    sudo make -C ./builddir install
}



##########################################################################
#
# References:
# https://github.com/eflows4hpc/image_creation
#
###########################################################################

install_source_service() {
	# Install python dependencies.
	wget https://github.com/eflows4hpc/image_creation/requirements.txt
	pip install -r ./requirements.txt
	git clone https://github.com/eflows4hpc/software-catalog.git
	cd image_creation
	gedit ./configuration.py
}

main(){
	install_proxy
	run_proxy
	install_docker
	install_singularity
	install_source_service
}

main

