# Securely consuming secrets in Azure Container Apps

This repository holds the files for the demo held in the above talk.

## Using the sandbox
For the most part, these are just Terraform files, so they can be run by any user who has access to the Azure subscription. However, for the purpose of testing, there is a [Dockerfile](./Dockerfile) included in the repo, which builds a sort of "sandbox" image with the `az cli` and `terraform` executables.

The image can be built in the usual way:

```
docker build -t testbox:latest .
```

Afterwards, the sandbox can be run with this command. Make sure to replace **YOUR_AZURE_SUBSCRIPTION_ID** with the correct value for your environment (this is a Terraform requirement, more info [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/4.0-upgrade-guide#specifying-subscription-id-is-now-mandatory)):

```
docker run --rm -it -v $(pwd):/code -e ARM_SUBSCRIPTION_ID=YOUR_AZURE_SUBSCRIPTION_ID testbox
```

## Running Terraform
Once inside the sandbox, the first step is logging into Azure: 

```
az login
```

You should now be in the `terraform` directory, so it is time to initialize the repository:

```
terraform init
```

Perform a plan to see what will be created:

```
terraform plan -refresh=true -out=terraform.tfplan
```

If you are satisfied with the changes being presented, you can commit them with `terraform apply`:

```
terraform apply terraform.tfplan
```
