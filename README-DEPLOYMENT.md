# Deployment to Gcloud

- [Prerequisite:](#prerequisite-)
  * [1. Authenticate with google:](#1-authenticate-with-google-)
    + [1. Use gcloud sdk](#1-use-gcloud-sdk)
    + [2. Use service account](#2-use-service-account)
    + [3. Install packer and terraform](#3-install-packer-and-terraform)
  * [2. Setup environment:](#2-setup-environment-)
- [Packing the application](#packing-the-application)
- [Deploying the application](#deploying-the-application)

## Prerequisite:

### 1. Authenticate with google:

#### 1. Use gcloud sdk
```sh
gcloud auth application-default login
```

`Note:` [Install](https://cloud.google.com/sdk/docs/install) gcloud sdk if you haven't done before

#### 2. Use service account
- Create new service account with required permission and download the json key file

- Export file path like below in root directory
```sh
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/json/key/file.json
```

#### 3. Install packer and terraform
Use official documentation for installing

### 2. Setup environment:

```sh
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/sa.json
# Skip above if using glcoud based authentication
export PKR_VAR_project_id=<project-id>
export PKR_VAR_zone=<project-zone>
export PKR_VAR_postgres_user_password=petclinic
export TF_VAR_project=<project-id>
export TF_VAR_zone=<project-zone>
export TF_VAR_region=<project-region>
```

## Packing the application

Refer the make commands below
```yaml
pack-postgres                  Pack postgres image
pack-backend                   Pack backend image
pack-frontend                  Pack frontend image
pack                           Pack all the images
```

## Deploying the application

Refer the make commands below
```yaml
stack-setup                    Setup Stack using terraform
stack-plan                     Plan stack
stack-apply                    Apply stack
stack-all                      Create stack in one go (with approval step)
stack-all-auto-approve         Create stack in one go
```