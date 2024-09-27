# Genesis

Genesis manages our platform infrastructure. It consists of Terraform code
deployed using [HCP Terraform's VCS-driven workflow option][6].

## Background

### Platform infrastructure vs app infrastructure

We can divide infrastructure into two parts: platform and app.
Genesis handles platform infrastructure.

App infrastructure includes all of the resources (mainly AWS resources such as databases and servers)
required to run the app in a single stage (e.g., production). We'll define it in SST v3 Ion,
which has powerful features for development such as live reloading.

Platform infrastructure is the cross-stage infrastructure.
It includes AWS account definitions, CI/CD pipelines for deploying the app infrastructure,
and container images for Bazel to consume. We'll define it in [Terraform][5],
which is simpler than SST and uses a simpler declarative language than SST.

## Design

### Requirements

The system must manage our [AWS organization][3] and auth access for engineers.
Engineers should sign in and obtain credentials through the [AWS Identity Center][1].
Creating a new AWS account should involve code changes.
Manual steps should only be necessary for approving changes.

Terraform code should define our infrastructure.

We should offer guardrails to prevent bad PR's from getting merged.
This should ideally be a "dry run" that gives authors a preview of what their code change will do.

### Workflows

GitHub Actions should implement the build guardrails. It's not immediately clear what options we have for this,
so let's defer that for later. TODO @josalvatorre

We'll leverage HCP Terraform's [VCS-driven workflow option][4]. This allows us to easily trigger deployments based on
code changes and human review. It also makes it easy to trigger "speculative plans" to preview changes before merging them.

#### Why not the CLI-driven workflow option? 

We originally wanted this option for the local development benefit. We planned to use a container image and GitHub Actions
to trigger Terraform deployments. The container image would've made it easy to test locally.

This turned out to have several serious downsides.

* Long-lived credentials.
    * The CLI-driven workflow option required long-lived credentials to access HCP Terraform. This is inherently less secure.
* Chicken-and-egg auth hell.
    * Setting this up would've required solving several circular dependencies.
        * We need to set up AWS auth before Terraform can manage AWS resources,
        but we want Terraform to manage AWS resources (including auth).
        * We want Terraform to run in a container,
        but we want Terraform to define the ECR repositories that host the container images.
    * These are solvable by doing some things manually and coming back to automate them,
    but it would've been quite painful.
* Multiple container images.
    * We would've needed 2+ different images.
        * 1+ images to run the Terraform deployment.
            * One image for each command.
            * These would use Google's distroless images.
        * 1 image for debugging.
            * The distroless images don't come with basic debugging tools like a shell.
        * 1 image for development.
            * If you want to run Neovim, you'd be better off with an Ubuntu base image.
* Setting up AWS auth for GitHub Actions.
    * GitHub Actions was the best option for the CLI-driven workflow option because it would avoid a circular dependency
    between the workflow and the Terraform deployment.
        * For example, if we used a Terraform-deployed AWS CodePipeline, and we accidentally broke that pipeline,
        then how would we fix the pipeline without manual intervention?
    * Setting up auth would've been annoying.
        * The most secure option would've been to set up [OIDC between AWS and GitHub Actions][7].
        * It wouldn't have been that hard, but the VCS approach completely eliminates the need for this.

### The AWS organization

An [AWS organization][3] is a set of AWS accounts. One of these is the root account.
Having an organization allows us to create new accounts dynamically using Terraform.
It also allows us to enforce policies and manage auth across accounts.

The organization will evolve based on our needs.
The only requirements we need to start out are the following.

* Engineers (just @josalvatorre for now) should be able to log into the identity center.
* Access should be controlled in the Terraform code.

## Implementation plan

We'll perform the following steps in order.

- [x] AWS organization and root account are set up.
- [x] VCS-driven workflow is set up for HCP Terraform to make deployments and preview changes.
    * Terraform code can be trivial in this stage. No need to control any AWS resources.
    * [PR's should be blocked if the Terraform code is bad.][9]
    * Merges to the main branch should trigger a deployment with required human approval.
    * [There's a small line in the docs saying that the first run in a fresh workspace must be manual.][10]
- [ ] Terraform must have access to AWS.
    * [We'll probably set up OIDC between AWS and Terraform.][8]
- [ ] Terraform should import the AWS organization.
    * The Terraform code should define the AWS organization.

[1]: https://aws.amazon.com/iam/identity-center/
[3]: https://docs.aws.amazon.com/organizations/
[4]: https://github.com/bazel-contrib/rules_oci/blob/5ff4c792cab77011984ca2fe46d05c5d2f8caa47/docs/pull.md
[5]: https://www.terraform.io/
[6]: https://developer.hashicorp.com/terraform/tutorials/cloud-get-started/cloud-vcs-change
[7]: https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/configuring-openid-connect-in-amazon-web-services
[8]: https://developer.hashicorp.com/terraform/enterprise/workspaces/dynamic-provider-credentials/aws-configuration
[9]: https://developer.hashicorp.com/terraform/cloud-docs/run/ui#speculative-plans-on-pull-requests
[10]: https://developer.hashicorp.com/terraform/cloud-docs/run/ui#manually-starting-runs
