# Lambda For Stopping EC2

This code is to stop ec2 instances where an specific AMI is not used. An alert also integrated if any violation is found which is send to specific number.

## Installation

Use the page  [download](https://www.terraform.io/downloads.html) to install terraform.


## Usage

Create a `terraform.tfvars` file with following details and modify `default = "ami-0e342d72b12109f911"` from `vars.tf` to change AMI_ID

```bash
access_key="XXXXX"
secret_key="XXXXX"
bucket_name="XXXXX"
```
To apply changes, run

```bash
terraform apply
```

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.


