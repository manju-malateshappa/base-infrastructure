data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  # Common local variables
  aws_region = data.aws_region.current.name
  account_id = data.aws_caller_identity.current.account_id
  
  # Bucket naming conventions
  expected_sagemaker_bucket_name = "sagemaker-${local.aws_region}-${local.account_id}"
  expected_datascience_bucket_name = "${var.s3_bucket_prefix}-ds-${local.aws_region}-${local.account_id}"
  expected_service_catalog_bucket_name = "service-catalog-${local.aws_region}-${local.account_id}"
}
