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

We only use GitHub Actions as a "first mover". Our GitHub Actions workflows create
the "real" workflows defined in Terraform, which can't launch themselves.

We use Terraform as much as possible for reasons stated in the Terraform section.
We only use GitHub Actions because, unlike alternative first mover solutions,
GitHub Actions workflows can be defined declaratively in the codebase itself and require no
manual setup. GitHub Actions are also super-popular, so they're relatively easy to understand
and find.

### Tools we did *not* end up using

### Terraform Cloud

This was tempting given our embrace of Terraform. However, we're also using SST Ion.
SST Ion admittedly uses Terraform (and Pulumi) under the hood, but Terraform Cloud
doesn't support managed deployments to our knowledge. Therefore, instead of adding yet
another tool to our tech stack that only serves some of our use case,
we'll adopt the same non-managed strategy across the board.
