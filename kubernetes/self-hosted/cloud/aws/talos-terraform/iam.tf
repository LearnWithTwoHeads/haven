# EBS CSI Volume Policy Document
data "aws_iam_policy_document" "yke_ebs_csi_volume_policy" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:AttachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteTags",
      "ec2:DeleteVolume",
      "ec2:DescribeInstances",
      "ec2:DescribeSnapshots",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeVolumesModifications",
      "ec2:DetachVolume",
      "ec2:ModifyVolume"
    ]
    resources = ["*"]
  }
}

# EBS CSI Volume IAM Policy
resource "aws_iam_policy" "yke_ebs_csi_volume_policy" {
  name        = "EBSCSIVolumePolicy"
  description = "Policy for EBS CSI Volume operations"
  policy      = data.aws_iam_policy_document.yke_ebs_csi_volume_policy.json

  tags = {
    Name = "yke-ebs-csi-volume-policy"
  }
}

# Assume Role Policy for EC2 Service
data "aws_iam_policy_document" "yke_ebs_csi_volume_assume_role_policy" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# EBS CSI Volume IAM Role
resource "aws_iam_role" "yke_ebs_csi_volume_role" {
  name               = "EBSCSIVolume"
  assume_role_policy = data.aws_iam_policy_document.yke_ebs_csi_volume_assume_role_policy.json

  tags = {
    Name = "yke-ebs-csi-volume-role"
  }
}

# Attach Policy to Role
resource "aws_iam_role_policy_attachment" "yke_ebs_csi_volume_policy_attachment" {
  role       = aws_iam_role.yke_ebs_csi_volume_role.name
  policy_arn = aws_iam_policy.yke_ebs_csi_volume_policy.arn
}

# Instance Profile for EC2 instances to use the role
resource "aws_iam_instance_profile" "yke_ebs_csi_volume_instance_profile" {
  name = "EBSCSIVolumeInstanceProfile"
  role = aws_iam_role.yke_ebs_csi_volume_role.name

  tags = {
    Name = "yke-ebs-csi-volume-instance-profile"
  }
}
