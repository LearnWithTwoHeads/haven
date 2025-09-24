resource "aws_security_group" "yke_worker_node_sg" {
  name   = "yke-worker-node-sg"
  vpc_id = aws_vpc.yke_vpc.id
}

# Allow BGP traffic from control plane to worker nodes
resource "aws_security_group_rule" "yke_worker_node_ingress_control_plane_bgp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_worker_node_sg.id
  source_security_group_id = aws_security_group.yke_control_plane_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
}

# Allow BGP traffic from other worker nodes
resource "aws_security_group_rule" "yke_worker_node_ingress_worker_bgp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_worker_node_sg.id
  source_security_group_id = aws_security_group.yke_worker_node_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
}

# Allow IP encapsulation traffic from control plane to worker nodes
resource "aws_security_group_rule" "yke_worker_node_ingress_control_plane_ip_encapsulation" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_worker_node_sg.id
  source_security_group_id = aws_security_group.yke_control_plane_sg.id
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
}

# Allow IP encapsulation traffic from other worker nodes
resource "aws_security_group_rule" "yke_worker_node_ingress_worker_ip_encapsulation" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_worker_node_sg.id
  source_security_group_id = aws_security_group.yke_worker_node_sg.id
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "yke_worker_node_talos" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_worker_node_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 50000
  to_port           = 50000
  protocol          = "tcp"
}

resource "aws_security_group_rule" "yke_worker_node_ingress_vpc_kubelet" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_worker_node_sg.id
  cidr_blocks       = [var.vpc_cidr_range]
  from_port         = 10250
  to_port           = 10250
  protocol          = "tcp"
}

resource "aws_security_group_rule" "yke_worker_node_ingress_vpc_kube_proxy" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_worker_node_sg.id
  cidr_blocks       = [var.vpc_cidr_range]
  from_port         = 10256
  to_port           = 10256
  protocol          = "tcp"
}

resource "aws_security_group_rule" "yke_worker_node_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.yke_worker_node_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = -1
  from_port         = 0
  to_port           = 0
}

resource "aws_security_group_rule" "yke_worker_node_ingress_traefik_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_worker_node_sg.id
  source_security_group_id = aws_security_group.yke_elb_traefik_ingress_security_group.id
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
}

resource "aws_security_group" "yke_control_plane_sg" {
  name   = "yke-control-plane-sg"
  vpc_id = aws_vpc.yke_vpc.id
}

# Allow BGP traffic from worker nodes to control plane
resource "aws_security_group_rule" "yke_control_plane_ingress_worker_bgp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_control_plane_sg.id
  source_security_group_id = aws_security_group.yke_worker_node_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
}

# Allow BGP traffic from other control plane nodes
resource "aws_security_group_rule" "yke_control_plane_ingress_control_plane_bgp" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_control_plane_sg.id
  source_security_group_id = aws_security_group.yke_control_plane_sg.id
  from_port                = 179
  to_port                  = 179
  protocol                 = "tcp"
}

# Allow IP encapsulation traffic from worker nodes to control plane
resource "aws_security_group_rule" "yke_control_plane_ingress_worker_ip_encapsulation" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_control_plane_sg.id
  source_security_group_id = aws_security_group.yke_worker_node_sg.id
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
}

# Allow IP encapsulation traffic from other control plane nodes
resource "aws_security_group_rule" "yke_control_plane_ingress_control_plane_ip_encapsulation" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_control_plane_sg.id
  source_security_group_id = aws_security_group.yke_control_plane_sg.id
  protocol                 = 4
  from_port                = 0
  to_port                  = 0
}

resource "aws_security_group_rule" "yke_control_plane_ingress_talos" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_control_plane_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 50000
  to_port           = 50000
  protocol          = "tcp"
}

resource "aws_security_group_rule" "yke_control_plane_ingress_elb_kube_api_server" {
  type                     = "ingress"
  security_group_id        = aws_security_group.yke_control_plane_sg.id
  source_security_group_id = aws_security_group.yke_elb_security_group.id
  from_port                = 6443
  to_port                  = 6443
  protocol                 = "tcp"
}

resource "aws_security_group_rule" "yke_control_plane_ingress_vpc_kube_api_server" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_control_plane_sg.id
  cidr_blocks       = [var.vpc_cidr_range]
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
}

resource "aws_security_group_rule" "yke_control_plane_ingress_vpc_needed_ports" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_control_plane_sg.id
  cidr_blocks       = [var.vpc_cidr_range]
  from_port         = 10248
  to_port           = 10260
  protocol          = "tcp"
}

resource "aws_security_group_rule" "yke_control_plane_ingress_vpc_etcd" {
  type              = "ingress"
  security_group_id = aws_security_group.yke_control_plane_sg.id
  cidr_blocks       = [var.vpc_cidr_range]
  from_port         = 2379
  to_port           = 2380
  protocol          = "tcp"
}

resource "aws_security_group_rule" "yke_control_plane_egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.yke_control_plane_sg.id
  cidr_blocks       = ["0.0.0.0/0"]
  protocol          = -1
  from_port         = 0
  to_port           = 0
}

data "aws_ami" "talos" {
  filter {
    name   = "name"
    values = ["talos-v1.11.0-us-east-1-amd64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "yke_control_plane" {
  ami = data.aws_ami.talos.id

  subnet_id = aws_subnet.yke_public_subnet[0].id

  instance_type = "t3.medium"

  vpc_security_group_ids = [aws_security_group.yke_control_plane_sg.id]

  tags = {
    Name      = "yke-control-plane-0"
    Component = "control-plane-node"
  }
}

resource "aws_instance" "yke_worker_node" {
  count = 2
  ami   = data.aws_ami.talos.id

  subnet_id = aws_subnet.yke_public_subnet[0].id

  instance_type = "t3.medium"

  iam_instance_profile = aws_iam_instance_profile.yke_ebs_csi_volume_instance_profile.name

  vpc_security_group_ids = [aws_security_group.yke_worker_node_sg.id]

  tags = {
    Name      = "yke-worker-${count.index}"
    Component = "worker-node"
  }
}
