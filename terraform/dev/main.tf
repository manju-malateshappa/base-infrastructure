terraform {
  backend "s3" {
    bucket         = "terraform-state-${local.aws_region}-${local.account_id}"
    key            = "mlops-terraform-dev.state"
    region         = "${local.aws_region}"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

# S3 Buckets
# Create the buckets directly with AWS provider resources
resource "aws_s3_bucket" "sagemaker_bucket" {
  bucket = local.expected_sagemaker_bucket_name
  force_destroy = false
  
  # This will prevent errors if the bucket already exists
  lifecycle {
    ignore_changes = all
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "sagemaker_bucket_versioning" {
  bucket = aws_s3_bucket.sagemaker_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "sagemaker_bucket_policy" {
  bucket = aws_s3_bucket.sagemaker_bucket.id
  policy = data.aws_iam_policy_document.sagemaker_bucket_policy.json
}

resource "aws_s3_bucket" "datascience_bucket" {
  bucket = local.expected_datascience_bucket_name
  force_destroy = false
  
  # This will prevent errors if the bucket already exists
  lifecycle {
    ignore_changes = all
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "datascience_bucket_versioning" {
  bucket = aws_s3_bucket.datascience_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "datascience_bucket_policy" {
  bucket = aws_s3_bucket.datascience_bucket.id
  policy = data.aws_iam_policy_document.datascience_bucket_policy.json
}


# Creates service catalog bucket with versioning enabled
module "service_catalog_bucket" {
  source                  = "../modules/s3"
  s3_bucket_name          = local.expected_service_catalog_bucket_name
  s3_bucket_force_destroy = "false"
  versioning              = "Enabled"
  s3_bucket_policy        = data.aws_iam_policy_document.service_catalog_bucket_policy.json
}

# KMS
module "kms" {
  source                              = "../modules/kms"
  trusted_accounts_for_decrypt_access = [var.preprod_account_number, var.prod_account_number]
  account_id                          = local.account_id
}

# Networking ressources (VPC, endpoints)
module "networking" {
  source = "../modules/networking"
  region = var.region
}

# SageMaker roles
module "sagemaker_roles" {
  source           = "../modules/sagemaker_roles"
  s3_bucket_prefix = var.s3_bucket_prefix
}

# SageMaker domain
module "sagemaker" {
  source                                 = "../modules/sagemaker"
  vpc_id                                 = module.networking.vpc_id
  sg_id                                  = module.networking.sg_id
  private_subnet_id                      = module.networking.private_subnet_id
  private_subnet_id_2                    = module.networking.private_subnet_2_id
  sm_studio_role_arn                     = module.sagemaker_roles.sagemaker_studio_role_arn
  data_scientist_execution_role_arn      = module.sagemaker_roles.data_scientist_role_arn
  lead_data_scientist_execution_role_arn = module.sagemaker_roles.lead_data_scientist_role_arn
}

# Service Catalog
module "service_catalog" {
  source                                 = "../modules/service_catalog"
  environment                            = var.environment
  bucket_id                              = module.service_catalog_bucket.bucket_id
  bucket_domain_name                     = module.service_catalog_bucket.s3_bucket_domain_name
  lead_data_scientist_execution_role_arn = module.sagemaker_roles.lead_data_scientist_role_arn
  launch_role                            = aws_iam_role.launch_constraint_iam_role.arn
  templates = {
    template1 = {
      name : "MLOps template for model building, training, and deployment",
      file : "sagemaker_project_train_and_deploy",
      description : "Use this template to automate the entire model lifecycle that includes both model building and deployment workflows. Suited for continuous integration and continuous deployment (CI/CD) of ML models. Process data, extract features, train and test models, and register them in the model registry. The template provisions a GitHub repository for checking in and managing code versions. Kick off the model deployment workflow by approving the model registered in the model registry for deployment either manually or automatically. You can customize the seed code and the configuration files to suit your requirements. GitHub Actions is used to orchestrate the model deployment. Model building pipeline: SageMaker Pipelines Code repository and Orchestration: GitHub"
    },
    template2 = {
      name : "MLOps template for model building and training",
      file : "sagemaker_project_train",
      description : "Use this template to automate the entire model lifecycle that includes both model building and deployment workflows. Suited for continuous integration and continuous deployment (CI/CD) of ML models. Process data, extract features, train and test models, and register them in the model registry. The template provisions a GitHub repository for checking in and managing code versions. Kick off the model deployment workflow by approving the model registered in the model registry for deployment either manually or automatically. You can customize the seed code and the configuration files to suit your requirements. GitHub Actions is used to orchestrate the model deployment. Model building pipeline: SageMaker Pipelines Code repository and Orchestration: GitHub"
    },
    template3 = {
      name : "MLOps template for workflow promotion",
      file : "sagemaker_project_workflow",
      description : "Use this template to automate the model building workflow. Process data, extract features, train and test models, and register them in the model registry. The template provisions a GitHub repository for checking in and managing code versions. You can customize the seed code and the configuration files to suit your requirements."
    },
    template4 = {
      name : "MLOps template for LLM training and evaluation",
      file : "sagemaker_project_llm_train",
      description : "Use this template to train and evaluate LLM. It creates a pipeline implementations that automates different steps of an evaluation process such as data preprocess, model deploy, model evaluation, best model selection, resources cleanup."
    }
  }

}
