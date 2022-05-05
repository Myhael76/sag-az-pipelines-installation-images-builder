# Software AG Product and Fixes Images Builder On Azure Pipelines

Use Azure Pipelines to build the product and fix images of chosen SUIF templates.

- [Software AG Product and Fixes Images Builder On Azure Pipelines](#software-ag-product-and-fixes-images-builder-on-azure-pipelines)
  - [Prerequisites](#prerequisites)
  - [Plan](#plan)
  - [Steps to Setup your DevOps Project](#steps-to-setup-your-devops-project)
    - [Setup Azure Cloud Resources](#setup-azure-cloud-resources)

## Prerequisites

- A working [azure devops account](https://dev.azure.com/)
- A working GitHub account
- An azure subscription where we can run the agents as a virtual machine scale set (VMSS)
  - The agents run on linux, but images may be created for other platforms too.
- A Service principal that allows Azure Pipelines to connect to the VMSS
- Empower credentials having permissions to download the chosen templates products and fixes

## Plan

The Pipelines will run manually, but the idea is to schedule them periodically (e.g. each Sunday) or when new fixes are published by Software AG.

Currently, there is no automated event that can trigger an Azure Pipeline in case new fixes are published.

On the Azure Dev project, the user will keep the Empower credentials as a secure file and the list of the templates for which the images are needed. The produced images will be considered as artifacts and stored in the project artifacts. We need to use the Universal Packages due to the potential file sized of Software AG image files.

## Steps to Setup your DevOps Project

### Setup Azure Cloud Resources

Execute the scripts from the [prerequisites project](https://github.com/Myhael76/sag-builder-az-prerequisites).
