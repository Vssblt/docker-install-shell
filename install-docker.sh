#!/bin/bash

if [ ! -z `sudo which apt | grep "/apt"` ]; then
	sudo apt update
	sudo apt-get install -y lsb-release
elif [ -z `sudo which yum | grep "/yum"` ]; then
	sudo yum install -y redhat-lsb
fi

is_ubuntu=`lsb_release -a | grep ubuntu -i`
is_centos=`lsb_release -a | grep centos -i`

if [ ! -z "$is_ubuntu" ]; then
	is_docker_exist=`dpkg -l | grep docker -i`
elif [ ! -z "$is_centos" ]; then
	is_docker_exist=`rpm -qa | grep docker`
else
	echo "Error: Current Linux release version is not supported, please use either centos or ubuntu. "
	exit
fi

if [ ! -z "$is_docker_exist" ]; then
	echo "Error: Please remove old version docker first. "
	exit
fi

function ubuntu_install()
{
	#Install docker
	sudo apt update
	sudo apt install -y apt-transport-https ca-certificates software-properties-common curl
	curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -
	sudo add-apt-repository "deb https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable"
	sudo apt update
	sudo apt install docker-ce -y
	sudo systemctl enable docker.service
	sudo systemctl start docker
	is_docker_success=`sudo docker run hello-world | grep -i "Hello from Docker"`
	if [ -z $is_docker_success ]; then
		echo "Error: Docker installation Failed."
		exit
	fi
	
	#Install nvidia docker
	curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
	sudo apt-get update
	sudo apt-get install -y nvidia-docker2
	sudo systemctl restart docker
	is_nvidia_docker_success=`sudo docker run --runtime=nvidia --rm nvidia/cuda:9.0-base nvidia-smi | grep GPU -i`
	if [ -z $is_nvidia_docker_success ]; then
		echo "Error: Nvidia docker installation failed."
		exit
	fi
	echo "Docker has been installed successfully."
}

function centos_install()
{
	#Install docker
	sudo yum install -y yum-utils device-mapper-persistent-data lvm2
	sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
	sudo yum install docker-ce-18.09.2 docker-ce-cli-18.09.2 containerd.io
	sudo systemctl enable docker.service
	sudo systemctl start docker
	is_docker_success=`sudo docker run hello-world | grep -i "Hello from Docker"`
	if [ -z $is_docker_success ]; then
		echo "Error: Docker installation Failed."
		exit
	fi

	#Install nvidia docker
	distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
	curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.repo | sudo tee /etc/yum.repos.d/nvidia-docker.repo
	sudo yum install -y nvidia-docker2
	sudo systemctl restart docker
	is_nvidia_docker_success=`sudo docker run --runtime=nvidia --rm nvidia/cuda:9.0-base nvidia-smi | grep GPU -i`
	if [ -z $is_nvidia_docker_success ]; then
		echo "Error: Nvidia docker installation failed."
		exit
	fi
	echo "Docker has been installed successfully."
}

if [ ! -z "$is_ubuntu" ]; then
	ubuntu_install
elif [ ! -z "$is_centos" ]; then
	centos_install
fi
