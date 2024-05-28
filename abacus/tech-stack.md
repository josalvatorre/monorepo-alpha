# Abacus Tech Stack

This document covers the tools used for the Abacus project.

## CI/CD

### Bazel

Bazel is the open source version of Google's monorepo build tool.
It's not tied to any specific language and works with any toolchain you want.
It offers hermetic builds, which meant that the build output will only change if
the either the code or build tools change. This allows for stability, flexibility,
and speed.

### GitHub Actions

We only use GitHub Actions as a "first mover" workflow system. Our GitHub Actions workflows create
the "real" workflows defined in Terraform, which can't launch themselves.

We use Terraform as much as possible for reasons stated in the Terraform section.
We only use GitHub Actions because, unlike alternative first mover solutions,
GitHub Actions workflows can be defined declaratively in the codebase itself and require no
manual setup. GitHub Actions are also super-popular, so they're relatively easy to understand
and find.

### Terraform Cloud

We use Terraform Cloud for use cases that use plain Terraform as opposed to SST Ion.
Terraform Cloud handles security and manual intervention features that would otherwise be
a pain to implement ourselves.

## Infrastructure as Code

### Terraform

Terraform is a wonderful tool for defining infrastructure declaratively.
It's far more powerful than AWS's CloudFormation and CDK, which are tied to AWS and
mostly work within a single AWS region. Terraform also has a great config language that
is far more expressive than CloudFormation's YAML but still retains the safety of
a non-turing-complete config language.

We mostly use SST Ion for the app itself, but there are situations where SST isn't nedessary.
We use plain Terraform for those situations. SST Ion uses it under the hood (along with Pulumi),
so sticking with Terraform will not pollute our tech stack with much more complexity
than a completely different solution.

It's not clear that Terraform is better than Pulumi, but Terraform's config language seems
safer than Pulumi's embrace of turing-complete languages.
We also happen to have slightly more experience with Terraform than Pulumi,
and researching Pulumi didn't seem worthwhile.

## Containerization

### Docker

We mostly use Bazel to build images instead of Docker because of Bazel's strictness around hermeticity.
If you have a Dockerfile that calls `apt install ...`, then you're simply downloading the latest artifacts.
That's not as hermetic as Bazel's approach.

However, we sometimes use Docker as the container execution engine, especially for local development
where we want to take an image built by Bazel and add customizations such as source code volumes
that won't actually be deployed to a production environment. There are no Bazel rules today
that can supplement that use case easily.
