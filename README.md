# Software AG Product and Fixes Images Builder On Azure Pipelines

Use Azure Pipelines to build the product and fix images of chosen SUIF templates.

- [Software AG Product and Fixes Images Builder On Azure Pipelines](#software-ag-product-and-fixes-images-builder-on-azure-pipelines)
  - [Prerequisites](#prerequisites)
  - [Plan](#plan)
  - [Steps to Setup your DevOps Project](#steps-to-setup-your-devops-project)
    - [Setup Azure Cloud Resources](#setup-azure-cloud-resources)
    - [Create a New DevOps Project](#create-a-new-devops-project)
    - [Create an Agent Pool Using the Created VMSS](#create-an-agent-pool-using-the-created-vmss)
    - [Create a New Pipeline](#create-a-new-pipeline)

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

- Execute the scripts from the [prerequisites project](https://github.com/Myhael76/sag-builder-az-prerequisites).
- Ensure your principal has `Contributor` role to the used subscription
  - TODO: Research the minimum permissions requirements

### Create a New DevOps Project

Version control is `Git`, Work item process `basic`.

- Go to Project Settings -> Service Connection and add a new connection to your GitHub Account
- Go to Project Settings -> GitHub Connections and add a new connection to your GitHub configured service, allowing Azure to interact with your project(s) of choice
- Go to Project Settings -> Service Connection and add a new connection to your subscription that will hold the pipeline agents
  - Type is Azure Resource Manager
  - Mind the permissions your company is granting
  - When using a service principal manually, use the GUId as id, not the name
  - Enable the check "Grant access permission to all pipelines"
- Create a VM scale set in your subscription
  - [Why VMSS?](https://dev.to/n3wt0n/everything-about-the-azure-pipelines-scale-set-agents-vmss-cp2?msclkid=5c9e876ca94311ec9e2dbb940011c680)
    - because building wm images may require more resources and we do not want to be on the internet.
  - note: [agents in containers](https://www.youtube.com/watch?v=rO-VKProMp8&ab_channel=CoderDave)

### Create an Agent Pool Using the Created VMSS

- Go to Project Settings -> Agent Pools
- Add Pool -> New -> Type = Azure virtual machine scale set
- Select your Azure subscription and click Authorize

### Create a New Pipeline

- Choose GitHub
- Choose this project (or a clone)
- (To verify) the yaml should appear automatically.
