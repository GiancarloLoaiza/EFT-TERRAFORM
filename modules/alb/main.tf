variable "project_name" {}
variable "vpc_id" {}
variable "subnet_ids" { type = list(string) }
variable "app_name" { description = "Nombre de la aplicación (app1 o app2)" }
variable "instance_ids" { 
    description = "Lista de IDs de instancias para conectar"
    type = list(string) 
    }

# 1. Security Group del ALB (Abierto a Internet)
resource "aws_security_group" "alb_sg" {
  name        = "${var.project_name}-${var.app_name}-alb-sg"
  description = "Permite HTTP desde internet"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.app_name}-alb-sg" }
}

# 2. El Balanceador de Carga (ALB)
resource "aws_lb" "this" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids

  tags = { Name = "${var.project_name}-${var.app_name}-alb" }
}

# 3. Target Group (Grupo de Destino)
resource "aws_lb_target_group" "this" {
  name     = "${var.project_name}-${var.app_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/" # Revisa si la raiz responde
    healthy_threshold   = 2
    unhealthy_threshold = 3 # Si falla 3 veces, marca error
    timeout             = 5
    interval            = 10
  }
}

# 4. Listener (El oído del ALB)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# 5. Attachment (Conectar las instancias al grupo)
# Aquí usamos la lista de IDs que recibimos del módulo compute
resource "aws_lb_target_group_attachment" "attach" {
  count            = length(var.instance_ids)
  target_group_arn = aws_lb_target_group.this.arn
  target_id        = var.instance_ids[count.index]
  port             = 80
}

# Output para ver la URL
output "dns_name" {
  value = aws_lb.this.dns_name
}