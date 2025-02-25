locals {
  sagemaker_bucket_arn = length(try(data.aws_s3_bucket.existing_sagemaker_bucket.id, "")) > 0 ? (
    "arn:aws:s3:::${data.aws_s3_bucket.existing_sagemaker_bucket.id}/*"
  ) : (
    "arn:aws:s3:::${module.sagemaker_bucket[0].bucket_id}/*"
  )
}

# Local variable for Data Science bucket ARN
locals {
  datascience_bucket_arn = length(try(data.aws_s3_bucket.existing_datascience_bucket.id, "")) > 0 ? (
    "arn:aws:s3:::${data.aws_s3_bucket.existing_datascience_bucket.id}/*"
  ) : (
    "arn:aws:s3:::${module.datascience_bucket[0].bucket_id}/*"
  )
}

# ✅ Creates policy document for SageMaker bucket
data "aws_iam_policy_document" "sagemaker_bucket_policy" {
  statement {
    sid       = "DenyUnEncryptedObjectTransfers"
    effect    = "Deny"
    resources = [local.sagemaker_bucket_arn]
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
    resources = [local.datascience_bucket_arn]
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
    resources = ["arn:aws:s3:::${module.service_catalog_bucket.bucket_id}/*"]
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
