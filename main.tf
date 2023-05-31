terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 0.12.9"
}

provider "aws" {
  region = "sa-east-1"
  access_key = ""
  secret_key = ""
}



resource "aws_vpc" "VPCTEST" {
  cidr_block           = "10.0.0.0/16"  // Reemplaza con el rango de direcciones IP deseado para tu VPC
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPCTEST"
  }
}

resource "aws_subnet" "test_subnet" {
  vpc_id                  =  aws_vpc.VPCTEST.id
  availability_zone       = "sa-east-1"
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "MySubnet"
  }
}

resource "aws_internet_gateway" "igtwy" {
  vpc_id = aws_vpc.VPCTEST.id

  tags = {
    Name = "MyInternetGateway"
  }
}

resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.VPCTEST.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igtwy.id
  }

  tags = {
    Name = "MyRouteTable"
  }
}


resource "aws_security_group" "test_sg" {
  name        = "test_sg"


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
}


resource "aws_route_table_association" "example" {
  subnet_id      = aws_subnet.test_subnet.id
  route_table_id = aws_route_table.routetable.id
}


resource "aws_lb" "test_alb" {
  name               = "test-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.test_sg.id]
  subnets            = [aws_subnet.test_subnet.id]
  
  tags = {
    Name = "test-alb"
  }
}



resource "aws_db_instance" "Master-Database" {
  identifier                = "my-db-instance"
  engine                    = "postgres"
  engine_version            = "12.5"
  instance_class            = "db.t2.micro"
  allocated_storage         = 20
  storage_type              = "gp2"
  publicly_accessible       = false
  multi_az                  = false
  db_subnet_group_name      = aws_db_subnet_group.dbsubnet.name
  vpc_security_group_ids    = [aws_security_group.test_sg.id]
  parameter_group_name      = "default.postgres12"
  backup_retention_period   = 7
  maintenance_window        = "Mon:03:00-Mon:04:00"
  skip_final_snapshot       = true
  allow_major_version_upgrade = false

  # Configuración de la contraseña maestra (cambia por tu propia contraseña)
  username = "admin"
  password = "HNEzrgPx"

  # Opciones de seguridad adicionales (opcional, agrega según tus necesidades)
  tags = {
    Name = "MyDBInstance"
  }
 db_name = "Master Database"
}

resource "aws_db_instance" "Standby-Database" {
  identifier                = "my-db-instance-standby"
  engine                    = "postgres"
  engine_version            = "12.5"
  instance_class            = "db.t2.micro"
  allocated_storage         = 20
  storage_type              = "gp2"
  publicly_accessible       = false
  multi_az                  = false
  db_subnet_group_name      = aws_db_subnet_group.dbsubnet.name
  vpc_security_group_ids    = [aws_security_group.test_sg.id]
  parameter_group_name      = "default.postgres12"
  backup_retention_period   = 7
  maintenance_window        = "Mon:03:00-Mon:04:00"
  skip_final_snapshot       = true
  allow_major_version_upgrade = false

  # Configuración de la contraseña maestra (cambia por tu propia contraseña)
  username = "admin"
  password = "HNEzrgPx"

  # Opciones de seguridad adicionales (opcional, agrega según tus necesidades)
  tags = {
    Name = "MyDBInstance"
  }
 db_name = "Standby Database"
}

resource "aws_db_subnet_group" "dbsubnet" {
  name       = "my-db-subnet-group"
  subnet_ids = ["test_subnet"]  // Reemplaza con los IDs de tus subredes de la VPC
}


resource "aws_route53_zone" "gooogle" {
  name = "gooogle.com"  // Reemplaza con el nombre de tu dominio
}

resource "aws_route53_record" "alias" {
  zone_id = aws_route53_zone.gooogle.zone_id
  name    = "www.gooogle.com"  // Reemplaza con el nombre del subdominio que deseas configurar
  type    = "A"

  alias {
    name                   = aws_lb.test_alb.dns_name
    zone_id                = aws_lb.test_alb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_efs_file_system" "test_efs" {
  creation_token = "efs-file-system"
  performance_mode = "generalPurpose"
  encrypted = true
  kms_key_id = "arn:aws:kms:sa-east-1:123456789012:key/abcd1234-abcd-1234-abcd-1234abcd1234"  // Reemplaza con el ARN de tu clave de KMS (opcional)

  tags = {
    Name = "MyEFSFileSystem"
  }
}

resource "aws_efs_mount_target" "efsmount" {
  file_system_id  = aws_efs_file_system.test_efs.id
  subnet_id       = "test_subnet" 
  security_groups = [aws_security_group.test_sg.id]
}