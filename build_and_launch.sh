#!/usr/bin/env bash
set -euo pipefail

# Ensure packer is installed (install once if missing)
if ! command -v packer >/dev/null 2>&1; then
	echo "packer not found; installing via brew..."
	brew install packer
fi

# Run Packer in machine-readable mode and save output for inspection
packer plugins install github.com/hashicorp/amazon
packer build -machine-readable packer-demo.json | tee packer-mr.log

# Extract the artifact field (last CSV field on the artifact line)
ARTIFACT=$(awk -F, '/artifact,0,id/ {print $NF; exit}' packer-mr.log || true)
if [ -z "${ARTIFACT:-}" ]; then
	echo "ERROR: no artifact line found in packer output. See packer-mr.log"
	tail -n 200 packer-mr.log
	exit 1
fi

# Parse AMI id (strip any region prefix like 'us-east-1:ami-...')
AMI_ID=${ARTIFACT##*:}
if [ -z "${AMI_ID}" ]; then
	echo "ERROR: parsed empty AMI_ID from artifact='$ARTIFACT'"
	exit 1
fi

# Write Terraform variable file
cat > amivar.tf <<EOF
variable "AMI_ID" { default = "${AMI_ID}" }
EOF

#Write to s3
AWS_REGION="us-east-1"
S3_BUCKET=`aws s3 ls --region $AWS_REGION |grep terraform-state |tail -n1 |cut -d ' ' -f3`
aws s3 cp amivar.tf s3://${S3_BUCKET}/amivar.tf
