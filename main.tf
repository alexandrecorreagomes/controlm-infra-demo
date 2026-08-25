terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0.0"
    }
  }
}

# Conecta ao motor do Docker local da VPS (onde o agente está rodando)
provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Cria uma rede isolada para o laboratório
resource "docker_network" "lab_net" {
  name = "controlm_net"
}

# 1. Nó de Aplicação (Target Node que o Ansible vai configurar)
resource "docker_container" "node_app" {
  name  = "node_app_01"
  image = "nginx:alpine"
  networks_advanced {
    name = docker_network.lab_net.name
  }
}

# 2. Servidor Ansible (Control Node)
resource "docker_container" "ansible_master" {
  name  = "ansible_master"
  image = "willhallonline/ansible:latest"
  
  # Mantém o contêiner rodando em background aguardando comandos do Control-M
  command = ["tail", "-f", "/dev/null"]

  # Mapeia o socket do Docker para conexão direta com os nodes
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }
  
  # Mapeia a pasta local da sua VPS onde colocaremos o Playbook depois
  volumes {
    host_path      = "/opt/playbooks"
    container_path = "/playbooks"
  }

  networks_advanced {
    name = docker_network.lab_net.name
  }
}