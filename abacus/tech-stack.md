# Abacus Tech Stack

This document covers the tools used for the Abacus project.

## Building

### Bazel

Bazel is the open source version of Google's monorepo build tool.
It's not tied to any specific language and works with any toolchain you want.
It offers hermetic builds, which meant that the build output will only change if
the either the code or build tools change. This allows for stability, flexibility,
and speed.

## CI/CD

### GitHub Actions

We only use GitHub Actions as a "first mover" workflow system. Our GitHub Actions workflows create
the "real" workflows defined in Terraform, which can't launch themselves.

We use Terraform as much as possible for reasons stated in the Terraform section.
We only use GitHub Actions because, unlike alternative first mover solutions,
GitHub Actions workflows can be defined declaratively in the codebase itself and require minimal
manual setup. GitHub Actions are also super-popular, so they're relatively easy to understand
and find.

## Containerization

### Docker

We mostly use Bazel to build images instead of Docker because of Bazel's strictness around hermeticity.
If you have a Dockerfile that calls `apt install ...`, then you're simply downloading the latest artifacts.
That's not as hermetic as Bazel's approach.

However, [Bazel's rules_oci][1] mostly assume that the base image already exists,
and Dockerfiles are just much more flexible for creating the base image.
We therefore use plain Docker to create the base images.

[1]: https://github.com/bazel-contrib/rules_oci
