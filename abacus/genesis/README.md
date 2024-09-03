# Genesis

Genesis is our "first mover" CI/CD system. It automates the deployment of base images
for Bazel to consume and the Terraform deployment for our infrasructure.
The automation is orchestrated using GitHub Actions.

## Design

Everything in our project should be automated. Human intervention should only be necessary
for fixes and for final approval for sensitive cases like infrastructure deployments.

Abacus should have its own AWS organization. We should be able to manage its child accounts through Terraform deployments.
Engineers should sign in through the [AWS Identity Center][1].

After we slash the manual steps, GitHub Actions should be able to do the following.

* Block PR merge if an OCI image cannot be built.
* On merge, build and push the new OCI image to the public ECR repository.
* Deploy Terraform code to manage the AWS organization after pushing the image.

Docker needs to build the OCI image, not Bazel. This is because Bazel's [rules_oci][2]
cannot create base images. This is presumably because Dockerfiles allow you to run arbitrary commands,
and so they are not hermetic.

### Why not use AWS CodePipeline defined in Terraform?

We're already embracing Terraform and AWS, so implementing CI/CD using AWS CodePipeline would
absolve the need to add another technology (i.e. GitHub Actions) to our tech stack.

However, if we use AWS CodePipeline to make Terraform deployments to the AWS organization,
that would be a soft circular dependency. If something goes wrong with the pipeline,
the pipeline might not be able to deploy the fix. We therefore think it's better to let
GitHub Actions be the first mover. We'll use AWS CodePipeline for all other downstream pipelines.

## Plan for implementing Continuous Integratino and Continuous Delivery

### Problem

We have the following requirements.

* Code changes should automatically lead to building and pushing images to
a publicly-accessible repository so that they be referenced by Bazel.
* We should automate this using Terraform inside a container whose image we control.
    * Controlling the image allows us to offer a stable environment for development, execution, and debugging.
* This should be a secure process.
    * Only we should have write access to that repository, and excessive reads should be throttled.

There's unfortunately a chicken-and-egg problem where AWS auth needs to be set up before Terraform
can manage AWS resources but we want AWS resources (including auth) to be managed by Terraform.
We resolve this by first setting up auth manually and then coming back to automate it after
Terraform is set up.

### Plan

We'll perform the following steps in order.

- [x] AWS organization and root account are set up.
- [x] Public ECR repository is set up in a dedicated AWS account under the organization.
- [ ] Codebase has a Dockerfile that can build an image containing the Terraform CLI.
- [ ] Public ECR repository has at least one image manually uploaded by an engineer.
- [ ] Engineer can manually deploy Terraform code to manage the AWS organization.
- [ ] GitHub Actions can automatically push new oci images and make Terraform deployments.

[1]: https://aws.amazon.com/iam/identity-center/
[2]: https://github.com/bazel-contrib/rules_oci
