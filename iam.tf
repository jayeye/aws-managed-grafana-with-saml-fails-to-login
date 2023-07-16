data "aws_iam_policy_document" "assume-role" {
  statement {
    effect = "Allow"
    principals {
      type = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "this" {
  statement {
    effect = "Allow"
    actions = [
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeVpcs",
      "ec2:DescribeDhcpOptions",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups"
    ]
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateNetworkInterface",
    ]
    condition {
      test = "ForAllValues:StringEquals"
      variable = "aws:TagKeys"
      values = ["AmazonGrafanaManaged"]
    }
    resources = ["*"]
  }
  statement {
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
    ]
    resources = [
      "arn:aws:ec2:*:*:network-interface/*",
    ]
    condition {
      test = "StringEquals"
      variable = "ec2:CreateAction"
      values = ["CreateNetworkInterface"]
    }
    condition {
      test = "Null"
      variable = "aws:RequestTag/AmazonGrafanaManaged"
      values = ["false"]
    }
  }
  statement {
    actions = [
      "ec2:DeleteNetworkInterface",
    ]
    resources = ["*"]
    condition {
      test = "Null"
      variable = "ec2:ResourceTag/AmazonGrafanaManaged"
      values = ["false"]
    }
  }
  statement {
    actions = [
      // Cloudwatch data source
      "cloudwatch:DescribeAlarmsForMetric",
      "cloudwatch:DescribeAlarmHistory",
      "cloudwatch:DescribeAlarms",
      "cloudwatch:ListMetrics",
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:GetMetricData",

      "logs:DescribeLogGroups",
      "logs:GetLogGroupFields",
      "logs:StartQuery",
      "logs:StopQuery",
      "logs:GetQueryResults",
      "logs:GetLogEvents",

      "ec2:DescribeTags",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "tag:GetResources",

      // Prometheus data source

      "aps:ListWorkspaces",
      "aps:DescribeWorkspace",
      "aps:QueryMetrics",
      "aps:GetLabels",
      "aps:GetSeries",
      "aps:GetMetricMetadata",
    ]
    resources = ["*"]
  }
  // SNS topics must start with 'grafana'
  statement {
    actions = [
      "sns:Publish",
    ]
    resources = ["arn:aws:sns:*::grafana*"]
  }
  statement {
    actions = [
      "grafana:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "this" {
  name = "${local.namebase}-duplicate-of-system-grafana-role-policy"
  policy = data.aws_iam_policy_document.this.json
}

resource "aws_iam_role" "this" {
  name = "${local.namebase}-grafana-bis"
  path = "/docr/"
  description = "Super-role under which to run grafana"
  assume_role_policy = data.aws_iam_policy_document.assume-role.json
  managed_policy_arns = [
    aws_iam_policy.this.arn,
    "arn:aws:iam::aws:policy/AWSIoTSiteWiseReadOnlyAccess",
    # replicated this!"arn:aws:iam::aws:policy/AmazonGrafanaRedshiftAccess",
    "arn:aws:iam::aws:policy/AWSXrayReadOnlyAccess",
    "arn:aws:iam::aws:policy/AWSGrafanaWorkspacePermissionManagement",
    "arn:aws:iam::aws:policy/AWSGrafanaAccountAdministrator",
  ]
  force_detach_policies = true
}
