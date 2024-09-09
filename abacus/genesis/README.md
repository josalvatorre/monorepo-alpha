# Genesis

Genesis manages our platform infrastructure. It automates the deployment of base images
for Bazel to consume and our Terraform-defined infrasructure.
The automation is orchestrated using GitHub Actions.

## Background

### Platform infrasructure vs app infrasructure

We can divide infrasructure into two parts: platform and app. Genesis handles platform infrastructure.

App infrastructure includes all of the resources (mostly AWS resources such as databases and servers)
required to run the app in a single stage (e.g. production). We'll define it in SST v3 Ion.

Platform infrastructure is the cross-stage infrastructure. It includes AWS account definitions,
CI/CD pipelines for deploying the app infrastructure, and container images for Bazel to consume.

### How Bazel builds container images

To build an OCI image with Bazel, you need a base image already available locally or a remote repository.
You reference that base image using the ["oci pull" rule from `rules_oci`][4].
This is secured through checksum validation. It shouldn't be possible for Bazel to conume the wrong image.
After doing that, you can freely build on top of it using other `rules_oci` rules.

## Design

### Requirements

We need a system to automatically create OCI images and upload them into a public ECR repository
for Bazel to consume. The ECR repository is public so that anybody with access to the code can
use its images.

The system also needs to manage our [AWS organization][3] and engineer auth.
Engineers should sign in through the [AWS Identity Center][1].
Creating a new AWS account should be a matter of code changes.

Infrastructure should be defined in Terraform code. The deployment should happen in a predefined environment,
preferably in a container so that an engineer can develop locally.

### Workflows

Our GitHub Actions workflows should be able to do the following.

* Block PR merge if an OCI image cannot be built.
* On merge, re-build and push the new OCI image to the public ECR repository.
* Deploy Terraform code to manage the AWS organization after pushing the image.

Docker builds the OCI image, not Bazel, because Bazel's [rules_oci][2]
cannot create base images. This is presumably because Dockerfiles allow you to run arbitrary commands,
rendering them non-hermetic, making them incompatible with Bazel.

#### Testing

Testing the images isn't necessary because they won't get used until Bazel consumes them.
Our tests will run on any images that Bazel consumes. That's out of scope for Genesis.
We'll probably decide to deploy those Bazel-built images in a separate workflow system such as
AWS CodePipeline.

Testing Terraform code would have some value, especially for auth, which is high-stakes and could fail silently.
However, unit tests have limited value for testing Terraform, and integration tests would take immense effort and (possibly) cost.
Genesis should handle very little Terraform code, makin it easy to inspect manually.
We will inspect deployments manually for now.

#### Why not use AWS CodePipeline defined in Terraform?

We're already embracing Terraform and AWS, so implementing CI/CD using AWS CodePipeline would
absolve the need to add another technology (i.e. GitHub Actions) to our tech stack.

However, if we use AWS CodePipeline to make Terraform deployments to the AWS organization,
that would be a soft circular dependency. If something goes wrong with the pipeline,
the pipeline might not be able to deploy the fix to itself. It's therefore better to let
GitHub Actions be the first mover given that GitHub automatically updates them.
We can still use AWS CodePipeline for all other pipeline use cases.

### The AWS organization

An [AWS organization][3] is a set of AWS accounts. One of these is the root account.
Having an organization allows us to dynamically create new ones using Terraform.
It also allows us to set common policies and manage auth across accounts.

The organization will evolve based on our needs. To introduce Genesis, we will have the following simple structure.

* @josalvatorre should be able to log into the different accounts through the identity center.
* We should have a dedicated AWS account for our publicly-available ECR repositories. This should **_not_**
be the same as the root account.

## Implementation plan

### Problem

There's unfortunately a chicken-and-egg problem where AWS auth needs to be set up before Terraform
can manage AWS resources but we want AWS resources (including auth) to be managed by Terraform.
We also want Terraform to run in a container, but Terraform needs to define the ECR repositories that host the container images.
We resolve this by first manually set up auth and the first image, and then come back to automate these
after Terraform deployments are automated.

### Plan

We'll perform the following steps in order.

- [x] AWS organization and root account are set up.
- [x] Public ECR repository is set up in a dedicated AWS account under the organization.
- [ ] Main branch has code for Engineer to manually build the final image.
    * Codebase has a Dockerfile to build the first base image.
    * Engineer has to manually build and puth the image to the public ECR repository.
    * Terraform code is in a Bazel package with GitHub-enforced linting.
        * Linting should happen before and after each merge to the main branch.
        * Terraform code can be trivial in this milestone.
    * Codebase has Bazel and Terraform code to build final image.
- [ ] Main branch has code for an engineer to manually make a Terraform deployment.
    * Terraform code should define the AWS organization and AWS repository.
- [ ] GitHub Actions can automatically push new base images and make Terraform deployments.
    * We wanted to separate the automatic pushing of base images into its own milestone.
    * However, that requires authentication that we might want to set up with Terraform,
    so we'll likely need to do them together.

[1]: https://aws.amazon.com/iam/identity-center/
[2]: https://github.com/bazel-contrib/rules_oci
[3]: https://docs.aws.amazon.com/organizations/
[4]: https://github.com/bazel-contrib/rules_oci/blob/5ff4c792cab77011984ca2fe46d05c5d2f8caa47/docs/pull.md
