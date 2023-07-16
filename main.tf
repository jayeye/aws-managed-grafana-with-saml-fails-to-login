locals {
  namebase = "scratch"
}

resource "aws_grafana_workspace" "this" {
  name = local.namebase
  description = "POC"
  account_access_type = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type = "SERVICE_MANAGED"
  data_sources = [
    "CLOUDWATCH",
    "PROMETHEUS",
    "REDSHIFT",
    "XRAY",
  ]
  grafana_version = "9.4"
  notification_destinations = ["SNS"]
  role_arn = aws_iam_role.this.arn
  configuration = jsonencode({
    unifiedAlerting = {
      enabled = true
    }
  })
  vpc_configuration {
    subnet_ids = data.terraform_remote_state.setup.outputs.subnets-natted[*].id
    security_group_ids = [data.terraform_remote_state.setup.outputs.security-groups["local"].id]
  }
}

resource "aws_grafana_workspace_saml_configuration" "this" {
  workspace_id = aws_grafana_workspace.this.id
  idp_metadata_url = "https://login.microsoftonline.com/XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX/federationmetadata/2007-06/federationmetadata.xml?appid=YYYYYYYY-YYYY-YYYY-YYYY-YYYYYYYYYYYY"
  admin_role_values = ["admin"]
  editor_role_values = ["editor"]
  email_assertion = "mail"
  groups_assertion = "groups"
  login_assertion = "mail"
  name_assertion = "displayName"
  org_assertion = "org"
  role_assertion = "role"
}

