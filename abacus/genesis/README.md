# Genesis

Genesis manages our platform infrastructure. It automates the deployment of base images
for Bazel to consume and our Terraform-defined infrastructure.
GitHub Actions orchestrates these deployments.

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

### How Bazel builds container images

To build an OCI image with Bazel, you need a base image that is available locally
or through a remote repository. Only then can Bazel create new images with additional layers
on top of that base image.

@josalvatorre thinks this limitation of being unable to build base images is because
Bazel's hermeticity restriction would make it extremely difficult to cover
every use case that Dockerfile can cover. Dockerfiles can execute arbitrary code,
making them more powerful but non-hermetic and incompatible with Bazel.

You reference the base image using the ["oci pull" rule from `rules_oci`][4] at the monorepo root level.
The pulling process is secured by checksum validation, so it should be impossible for Bazel
to conume the wrong image.

## Design

### Requirements

We need a system to automatically create OCI images and upload them into a public ECR repository
for Bazel to consume. The ECR repository should be public so that anybody can run our code.

The system must also manage our [AWS organization][3] and auth for engineers.
Engineers should sign in and obtain credentials through the [AWS Identity Center][1].
Creating a new AWS account should be a matter of code changes.

Terraform code should define our infrastructure.
The deployment should happen in a predefined environment,
preferably in a container so that an engineer can develop locally.

### Workflows

Our GitHub Actions workflows should be able to do the following.

* Block PR merge if the base image fails to build.
* On merge, re-build and push the new OCI image to the public ECR repository.
* Deploy Terraform code to manage the AWS organization after pushing the image.

#### Testing

Testing the images isn't necessary because they will only get used once Bazel consumes them.
Our tests will run on any images that Bazel creates. That's out of the scope of Genesis.
We'll probably decide to deploy those Bazel-built images in a separate workflow system,
such as AWS CodePipeline.

Testing Terraform code would have some value, especially for auth, which is critical and could fail silently.
However, unit tests have limited value for testing Terraform,
and integration tests would take immense effort and (possibly) cost.
Genesis should handle very little Terraform code, making it easy to inspect manually.
We will inspect deployments manually for now.

#### Why not use AWS CodePipeline defined in Terraform?

We're already embracing Terraform and AWS, so implementing CI/CD using AWS CodePipeline would
absolve the need to add another technology (i.e., GitHub Actions) to our tech stack.

However, using AWS CodePipeline to make Terraform deployments to the AWS organization
would cause a circular dependency. If the pipeline breaks,
it may not be able to deploy a fix to itself. GitHub Actions doesn't have this problem
because GitHub is responsible for deploying changes to the workflow.

We can still use AWS CodePipeline for all other pipeline use cases.

### The AWS organization

An [AWS organization][3] is a set of AWS accounts. One of these is the root account.
Having an organization allows us to create new accounts dynamically using Terraform.
It also allows us to enforce policies and manage auth across accounts.

The organization will evolve based on our needs.
However, we only need the following simple structure to set up Genesis.

* @josalvatorre should be able to log into the different accounts through the identity center.
* We should have a dedicated AWS account for our public ECR repositories. This should **_not_**
be the same as the root account.

## Implementation plan

### Problem

We face a chicken-and-egg problem because we need to set up AWS auth
before Terraform can manage AWS resources, but we want Terraform to manage AWS resources (including auth).
We also want Terraform to run in a container, but Terraform needs to define the ECR repositories that host the container images.
We'll resolve this by first manually setting up auth and the first image and then come back to automate these
after Terraform deployments are automated.

### Plan

We'll perform the following steps in order.

- [x] AWS organization and root account are set up.
- [x] The public ECR repository is set up in a dedicated AWS account within the organization.
- [ ] The main branch has code for the Engineer to build the final image manually.
    * Codebase has a Dockerfile to build the first base image.
    * The engineer has to manually build and push the image to the public ECR repository.
    * Terraform code is in a Bazel package with GitHub-enforced linting.
        * Linting should happen before and after each merge to the main branch.
        * Terraform code can be trivial in this milestone.
    * Codebase has Bazel and Terraform code to build the final image.
- [ ] The main branch has code for an engineer to make a Terraform deployment manually.
    * Terraform code should define the AWS organization and AWS repository.
- [ ] GitHub Actions can automatically push new base images and make Terraform deployments.
    * We wanted to separate the automatic pushing of base images into its own milestone.
    * However, that requires authentication that we might want to set up with Terraform,
    so we'll likely need to do them together.

[1]: https://aws.amazon.com/iam/identity-center/
[2]: https://github.com/bazel-contrib/rules_oci
[3]: https://docs.aws.amazon.com/organizations/
[4]: https://github.com/bazel-contrib/rules_oci/blob/5ff4c792cab77011984ca2fe46d05c5d2f8caa47/docs/pull.md
[5]: https://www.terraform.io/
