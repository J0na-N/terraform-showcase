provider "aws" {
  region = "us-east-2"
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-${random_string.bucket_suffix.result}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# ---------------------------------------------------------------------------
# Shared config secret.
#
# Holds a JSON blob of custom values that the CI pipeline reads and feeds into
# the root module as TF_VAR_* inputs. Terraform creates the secret CONTAINER
# and seeds a harmless placeholder value; the real value is set out-of-band
# (AWS console/CLI) so nothing sensitive ever lands in the committed state.
#
# ignore_changes on secret_string means updating the value out-of-band does
# NOT show up as drift on future bootstrap runs.
# ---------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "tf_config" {
  name        = "terraform-config-${random_string.bucket_suffix.result}"
  description = "Custom Terraform variable config consumed by CI (JSON of TF_VAR_* keys)"
}

resource "aws_secretsmanager_secret_version" "tf_config" {
  secret_id     = aws_secretsmanager_secret.tf_config.id
  secret_string = jsonencode({})

  lifecycle {
    # The real value is managed out-of-band; ignore future changes so updates
    # to the secret value do not cause drift.
    ignore_changes = [secret_string]
  }
}
