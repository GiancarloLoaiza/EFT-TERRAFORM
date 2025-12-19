variable "project_name" {}
variable "vpc_id" {}
variable "subnet_id" { description = "ID de la subred donde se alojarán" }
variable "security_group_ids" { type = list(string) }

# Variables de Lógica
variable "os_type" {
  description = "Sistema Operativo: 'linux' o 'windows'"
  type        = string
}

variable "instance_count" {
  description = "Cantidad de instancias a crear (Requisito: count)"
  type        = number
}

# --- 1. Lógica de Selección de AMI (Imagen) ---

# Buscar AMI de Amazon Linux 2 (Solo si os_type es linux)
data "aws_ami" "linux" {
  count       = var.os_type == "linux" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# Buscar AMI de Windows Server 2019 (Solo si os_type es windows)
data "aws_ami" "windows" {
  count       = var.os_type == "windows" ? 1 : 0
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base-*"]
  }
}

# Variable Local para decidir cuál ID usar
locals {
  # 1. Selección de la ID de la Imagen (AMI)
  ami_id = var.os_type == "linux" ? data.aws_ami.linux[0].id : data.aws_ami.windows[0].id

  # 2. Definimos el script de Linux por separado
  user_data_linux = <<-EOF
    #!/bin/bash
    yum update -y
    yum install httpd -y
    service httpd start
    echo "Hola desde Linux App 1 (Host: $(hostname))" > /var/www/html/index.html
  EOF

  # 3. Definimos el script de Windows por separado
  user_data_windows = <<-EOF
    <powershell>
    Install-WindowsFeature -name Web-Server -IncludeManagementTools
    Set-Content -Path "C:\inetpub\wwwroot\iisstart.htm" -Value "Hola desde Windows App 2"
    </powershell>
  EOF

  # 4. Selección Final: ¿Cuál script usamos?
  # Aquí el ternario es limpio y simple, sin bloques de texto que confundan al editor.
  user_data = var.os_type == "linux" ? local.user_data_linux : local.user_data_windows
}

# --- 2. Creación de Instancias (Requisito: count) ---

resource "aws_instance" "server" {
  count = var.instance_count # Uso obligatorio de count

  ami           = local.ami_id
  instance_type = "t2.micro" # O t3.micro. IMPORTANTE: t2.medium consume mucho crédito.
  subnet_id     = var.subnet_id
  
  vpc_security_group_ids = var.security_group_ids
  
  user_data = local.user_data

  # --- Requisito: Uso de funciones built-in ---
  tags = {
    # upper() transforma a mayúsculas
    Name = "${upper(var.project_name)}-${upper(var.os_type)}-SRV-${count.index + 1}"
    Environment = upper("lab")
    OS_Type     = var.os_type
  }
}

# Output para ver las IPs
output "instance_ips" {
  value = aws_instance.server[*].public_ip
}