# Base Images for Abacus

This directory holds logic for pushing base images to a publicly-available
repository so that they can get picked up by Bazel.

## How do base images get used?

We use GitHub Actions to build and push the images to a publicly-available repository after every merge.
Only after an image gets pushed to that repository can it be referenced by Bazel.
That means that you need to merge two commits in order to use a new image: one to create the base image
and another to reference the new base image.

## Motivation

We mostly use [Bazel's rules_oci][1] to build images instead of Docker because of Bazel's strictness around hermeticity.
If you have a Dockerfile that calls `apt install ...`, then you're simply downloading the latest artifacts.
That goes against Bazel's hermetic philosophy where every 3rd-party artifact needs to have an exact-and-verified
version.

However, [Bazel's rules_oci][1] cannot create the base image.
We therefore need to create the base images in a non-hermetic non-Bazel way.

[1]: https://github.com/bazel-contrib/rules_oci
