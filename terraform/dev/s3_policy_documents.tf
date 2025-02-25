# s3_policy_documents.tf

# Define locals for expected bucket names based on your naming convention
locals {
  expected_sagemaker_bucket_name = "sagemaker-${local.aws_region}-${local.account_id}"
  expected_datascience_bucket_name = "${var.s3_bucket_prefix}-ds-${local.aws_region}-${local.account_id}"
}

# ✅ Creates policy document for SageMaker bucket
data "aws_iam_policy_document" "sagemaker_bucket_policy" {
  statement {
    sid       = "DenyUnEncryptedObjectTransfers"
    effect    = "Deny"
    resources = ["arn:aws:s3:::${local.expected_sagemaker_bucket_name}/*"]
    actions   = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# ✅ Creates policy document for Data Science bucket
data "aws_iam_policy_document" "datascience_bucket_policy" {
  statement {
    sid       = "DenyUnEncryptedObjectTransfers"
    effect    = "Deny"
    resources = ["arn:aws:s3:::${local.expected_datascience_bucket_name}/*"]
    actions   = ["s3:*"]

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# Creates policy document for service catalog bucket
data "aws_iam_policy_document" "service_catalog_bucket_policy" {
  statement {
    sid       = "DenyUnEncryptedObjectTransfers"
    effect    = "Deny"
    resources = ["arn:aws:s3:::service-catalog-${local.aws_region}-${local.account_id}/*"]
    actions   = ["s3:*"]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

# Creates policy document for kms key
data "aws_iam_policy_document" "sagemaker_key_policy" {
  statement {
    sid       = "Allow access for Key Administrators"
    effect    = "Allow"
    actions   = ["kms:*"]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:root",
      ]
    }
  }

  statement {
    sid    = "Allow use of the key"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
      "kms:RevokeGrant"
    ]
    resources = ["*"]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:root",
        "${module.sagemaker_roles.data_scientist_role_arn}",
        "${module.sagemaker_roles.lead_data_scientist_role_arn}"
      ]
    }
  }
}
