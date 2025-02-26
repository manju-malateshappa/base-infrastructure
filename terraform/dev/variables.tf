variable "environment" {
  description = "Environment"
  type        = string
}
variable "region" {
  description = "AWS Region"
  type        = string
}
variable "preprod_account_number" {
  description = "Prepod account number"
  type        = string
}
variable "prod_account_number" {
  description = "Prod account number"
  type        = string
}
variable "s3_bucket_prefix" {
  description = "S3 bucket where data are stored"
  type        = string
}
variable "prefix" {
  description = "Lambda function name prefix for Lambda functions"
}

variable "pat_github" {
  description = "Github Personal access token"
  sensitive   = true
}

variable "github_organization" {
  description = "Name Github Organization"
  type        = string
}


variable "use_existing_sagemaker_bucket" {
  description = "Whether to use an existing SageMaker bucket"
  type        = bool
  default     = false
}

variable "existing_sagemaker_bucket_name" {
  description = "Name of the existing SageMaker bucket to use"
  type        = string
  default     = ""
}

variable "use_existing_datascience_bucket" {
  description = "Whether to use an existing Data Science bucket"
  type        = bool
  default     = false
}

variable "existing_datascience_bucket_name" {
  description = "Name of the existing Data Science bucket to use"
  type        = string
  default     = ""
}
