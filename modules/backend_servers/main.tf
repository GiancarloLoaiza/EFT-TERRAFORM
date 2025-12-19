# ---------------------------------------------------------------
# DATOS
# ---------------------------------------------------------------
# Obtener la última AMI de Amazon Linux 2
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# ---------------------------------------------------------------
# PARTE 1: BACKEND (ALB + 3 EC2 CON DOCKER)
# ---------------------------------------------------------------

# --- 1.1 Seguridad del Load Balancer (ALB) ---
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-alb-sg"
  description = "Permite trafico HTTP al ALB"
  vpc_id      = var.vpc_id

  # Permite HTTP (puerto 80) desde cualquier IP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite toda la salida
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-alb-sg" }
}

# --- 1.2 Seguridad de las Instancias EC2 del Backend ---
resource "aws_security_group" "backend_ec2_sg" {
  name        = "${var.project_name}-backend-ec2-sg"
  description = "Permite trafico solo desde el ALB"
  vpc_id      = var.vpc_id

  # Permite tráfico en el puerto 80 (donde escucha el Docker)
  # SÓLO desde el Security Group del ALB (¡Buena práctica!)
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  # Permite toda la salida (para yum, docker pull, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-backend-ec2-sg" }
}

# --- 1.3 Application Load Balancer (ALB) ---
resource "aws_lb" "backend_alb" {
  name               = "${var.project_name}-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids # El ALB debe estar en subredes públicas

  tags = { Name = "${var.project_name}-backend-alb" }
}

# --- 1.4 Grupo de Destino (Target Group) ---
# El ALB enviará tráfico a este grupo
resource "aws_lb_target_group" "backend_tg" {
  name     = "${var.project_name}-backend-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  # Verificación de salud
  health_check {
    path                = "/" # Pide la página raíz
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }
}

# --- 1.5 Listener del ALB ---
# Escucha en el puerto 80 y reenvía al Target Group
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.backend_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
}

# --- 1.6 Las 3 Instancias EC2 del Backend ---
resource "aws_instance" "backend_server" {
  count = 3 # <-- Indicador 2: Creación iterativa

  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  # Distribuye las 3 instancias entre las subredes públicas
  subnet_id = var.public_subnet_ids[count.index % length(var.public_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.backend_ec2_sg.id]

  # Script de usuario para instalar Docker y correr un contenedor
  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    amazon-linux-extras install docker -y
    service docker start
    usermod -a -G docker ec2-user
    chkconfig docker on

    # Corre un contenedor "hello world" que muestra su ID
    # para que veamos el balanceo de carga
    docker run -d -p 80:80 --rm nginxdemos/hello
  EOF

  tags = {
    Name = "${var.project_name}-backend-server-${count.index + 1}"
  }
}

# --- 1.7 Conexión de las EC2 al Target Group ---
resource "aws_lb_target_group_attachment" "backend_attach" {
  count = 3 # Debe coincidir con el count de las instancias

  target_group_arn = aws_lb_target_group.backend_tg.arn
  target_id        = aws_instance.backend_server[count.index].id
  port             = 80
}

# ---------------------------------------------------------------
# PARTE 2: FRONTEND (1 EC2 EMULADOR DE CDN)
# ---------------------------------------------------------------

# --- 2.1 Seguridad del Servidor Web Frontend ---
resource "aws_security_group" "frontend_sg" {
  name        = "${var.project_name}-frontend-sg"
  description = "Permite trafico HTTP al servidor web"
  vpc_id      = var.vpc_id

  # Permite HTTP (puerto 80) desde cualquier IP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Permite toda la salida (para yum, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-frontend-sg" }
}

# --- 2.2 Instancia EC2 del Servidor Web Frontend ---
resource "aws_instance" "frontend_server" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t2.micro"
  subnet_id     = var.public_subnet_ids[0] # Solo necesitamos una, la ponemos en la primera subred
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]

  # Usamos la plantilla de script de usuario que creamos
  user_data = templatefile("${path.module}/frontend_userdata.sh.tpl", {
    s3_website_url = var.s3_website_url
    s3_image_name  = var.s3_image_name
  })

  tags = {
    Name = "${var.project_name}-frontend-server"
  }
}