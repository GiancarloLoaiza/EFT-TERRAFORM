# Obtenemos la lista de Zonas de Disponibilidad (AZ) en la región actual
# Esto nos permite crear subredes en diferentes AZs (buena práctica)
data "aws_availability_zones" "available" {
  state = "available"
}

# 1. Crear la VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# 2. Crear el Internet Gateway (para darle salida a Internet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# 3. Crear una Tabla de Rutas (para definir cómo sale el tráfico)
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Esta ruta envía todo el tráfico desconocido (0.0.0.0/0) al Internet Gateway
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

# 4. Crear las Subredes Públicas (usamos count para crear varias)
resource "aws_subnet" "public" {
  # count.index tomará los valores 0, 1, 2...
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  # Asigna el primer CIDR (índice 0) a la primera subred, el segundo (índice 1) a la segunda
  cidr_block              = var.public_subnet_cidrs[count.index]
  # Asigna la primera AZ a la primera subred, la segunda a la segunda
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  # Hace que las instancias en esta subred obtengan IP pública automáticamente
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-${count.index + 1}"
  }
}

# 5. Asociar la Tabla de Rutas con las Subredes
# Esto "activa" la ruta a internet para nuestras subredes
resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}