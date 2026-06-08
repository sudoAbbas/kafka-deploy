resource "aws_iam_role" "kafka" {
  name = "kafka-role"

  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

resource "aws_iam_instance_profile" "kafka" {
  name = "kafka-profile"
  role = aws_iam_role.kafka.name
}


resource "aws_iam_role_policy" "kafka_policy_attachment" {
  name   = "kafka-s3-policy"
  role   = aws_iam_role.kafka.id
  policy = data.aws_iam_policy_document.kafka_policy.json
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "kafka_policy" {
  statement {
    effect = "Allow"

    actions = [
      "s3:*"
    ]

    resources = [
      "*"
    ]
  }
}
