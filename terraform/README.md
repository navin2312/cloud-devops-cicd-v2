# Terraform AWS EC2 Starter

Creates an Amazon Linux 2023 EC2 instance in `ap-south-1`, configures a security
group, installs Docker with EC2 user data, and serves a simple Apache page on
HTTP port 80. This version does not use GHCR.

## Prerequisites

- Terraform 1.5 or later
- AWS CLI profile named `devops-project`
- AWS permissions to describe AMIs and create/manage EC2 instances and security groups

## Check AWS credentials first

```powershell
aws sts get-caller-identity --profile devops-project
```

## Run from this directory

```powershell
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Review the plan, account, and possible AWS charges before typing `yes`.

After apply, open the `application_url` output. Initial startup may take several minutes.

## Destroy resources when finished

```powershell
terraform destroy
```

Review the destroy plan before confirming.

## Notes

- HTTP on port 80 is publicly reachable.
- SSH is closed by default. To enable it, set `allowed_ssh_cidr` in
  `terraform.tfvars` to your own public IPv4 address with `/32`.
- Public IPv4 addresses and EC2 usage may incur charges; verify your account's
  current pricing and free-tier eligibility.
