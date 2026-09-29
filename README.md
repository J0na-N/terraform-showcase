# Basic Terraform & AWS Deployment :D

This project deploys two types of web servers on AWS:
- A **single EC2 instance** (simple web server)
- A **cluster of EC2 instances** behind a load balancer, running inside a custom VPC (scalable web servers)

## Repository Layout

```
.
├── main.tf                 # Root config: calls the modules, stores its state in S3
├── variables.tf
├── outputs.tf
├── bootstrap/              # Run-once layer: creates the S3 state bucket and the
│                           # shared config secret. Uses COMMITTED local state
│                           # (see "How Bootstrapping Works" below).
└── modules/
    └── services/
        ├── vpc/            # Custom VPC: public + private subnets, NAT gateway
        ├── webserver-cluster/   # ALB (public subnets) + ASG (private subnets)
        └── webserver-instance/  # Single EC2 instance
```

## How Bootstrapping Works

There are **two separate Terraform states**:

1. **The `bootstrap/` layer** creates the shared prerequisites: the S3 bucket that
   holds all other state, and a Secrets Manager secret for custom config. It can't
   store its own state in that bucket (the bucket doesn't exist yet), so it uses
   **local state committed to the repo** (`bootstrap/terraform.tfstate`). You run it
   once; its state is intentionally checked in so those shared resources are never
   accidentally recreated. `.gitignore` ignores all state files *except* this one.
2. **The root module** stores its state **remotely** in the S3 bucket created by the
   `bootstrap/` layer, configured via the `backend "s3"` block in `main.tf`.

### Config secret

The bootstrap layer creates a Secrets Manager secret holding a JSON object of
custom variable values. Terraform creates the secret **container** and seeds a
placeholder value (`{}`); the real value is set **out-of-band** (AWS console or
CLI), so nothing sensitive is committed. Terraform ignores future changes to the
secret value, so updating it does not cause drift.

The CI pipeline reads this secret and exposes each JSON key as a `TF_VAR_<key>`
environment variable, which overrides `terraform.tfvars`. The JSON keys must match
root variable names, for example:

```json
{
  "server_text": "Hello from Secrets Manager",
  "cluster_instance_type": "t3.small",
  "environment": "prod"
}
```

Set the secret value once:

```bash
aws secretsmanager put-secret-value \
  --secret-id "$(cd bootstrap && terraform output -raw config_secret_name)" \
  --secret-string '{"server_text":"Hello from Secrets Manager"}'
```

Then set the repository variable `CONFIG_SECRET_NAME` to that secret's name so the
pipeline knows which secret to read.

## Prerequisites

1. **AWS Account** - Sign up at [aws.amazon.com](https://aws.amazon.com)
2. **AWS CLI** - Install and configure with your credentials
3. **Terraform** - Install from [terraform.io](https://terraform.io)

## Credentials

AWS deployment credentials are **stored as CI secrets** (`AWS_ACCESS_KEY_ID` and
`AWS_SECRET_ACCESS_KEY`) and consumed by the GitHub Actions pipeline. They are
never committed to the repo. For local runs, configure the AWS CLI (`aws
configure`) or export the same environment variables in your shell.

## Step 1: Bootstrap (Run Once)

This creates the S3 state bucket and the shared config secret.

```bash
# Navigate to the bootstrap layer
cd bootstrap

# Initialize Terraform (local state)
terraform init

# Create the shared resources
terraform apply
```

**Important**: Note the `s3_bucket_name` and `config_secret_name` outputs — you'll
need the bucket name in Step 3, and the secret name for `CONFIG_SECRET_NAME`.

After this runs, commit the generated `bootstrap/terraform.tfstate` file. It is
intentionally tracked so these shared resources are never recreated (all other
state files remain gitignored).

## Step 2: Configure Your Main Project

```bash
# Go back to the main directory
cd ..

# Edit terraform.tfvars with your preferences (optional)
nano terraform.tfvars
```

## Step 3: Configure Remote State

1. Open `main.tf`
2. Replace `your-terraform-state-bucket-name` with the S3 bucket name from Step 1
3. Save the file

Example:
```hcl
backend "s3" {
  bucket  = "my-terraform-state-a1b2c3d4"  # Use your actual bucket name
  key     = "webservers/terraform.tfstate"
  region  = "us-east-2"
  encrypt = true
}
```

## Step 4: Deploy Your Infrastructure

```bash
# Initialize Terraform (this will configure the remote backend)
terraform init

# See what will be created
terraform plan

# Create the infrastructure
terraform apply
```

## Step 5: Test Your Web Servers

After deployment, get the server URLs:

```bash
# Get the load balancer URL
terraform output cluster_alb_dns_name

# Get the single instance IP
terraform output single_instance_public_ip
```

Then visit:
- **Cluster**: `http://<load-balancer-dns>` (port 80)
- **Single Instance**: `http://<instance-ip>:8080` (port 8080)

Both will show "Hello, World!" 

## Step 6: Clean Up (When Done)

```bash
# Destroy the web servers (from the repo root)
terraform destroy

# Optionally, destroy the bootstrap resources (state bucket + config secret).
# Note: the bucket has prevent_destroy = true and must be emptied first.
cd bootstrap
terraform destroy
```

## What Gets Created

### VPC Module (`modules/services/vpc`)
- Custom VPC with public and private subnets across two availability zones
- Internet gateway (public egress) and a NAT gateway (private egress)
- Route tables and VPC flow logs
- Hardened default security group and network ACL

### Cluster Module (`modules/services/webserver-cluster`)
- Application Load Balancer in the **public** subnets (internet-facing)
- Auto Scaling Group in the **private** subnets (no public IPs)
- Instance security group that only accepts traffic from the ALB
- Health checks and optional scheduled auto-scaling

### Single Instance Module (`modules/services/webserver-instance`)
- 1 EC2 instance (t2.micro)
- Security group allowing HTTP traffic on port 8080
- Simple "Hello World" web server

## Costs

With default settings (t2.micro instances) the compute is inexpensive, but the
custom VPC runs a **NAT gateway (~$32/month plus data)** that bills while it
exists. Run `terraform destroy` when you're done experimenting to avoid ongoing
charges.

## Next Steps

- Modify `terraform.tfvars` to customize your deployment
- Explore the module code in `modules/services/`
- Try enabling auto-scaling by setting `enable_autoscaling = true`