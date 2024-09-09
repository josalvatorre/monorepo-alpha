# Principles

@josalvatorre believes in strictly adhering to the following principles.
They lead to higher upfront costs but pay immense dividends that
make life easier for all contributors, especially those with less experience
and context.

## Optimize for the long term

Short-term optimization paves the road to despair.
We don't want to be in a situation where engineers constantly waste time
on unnecessary problems and are lost due to a lack of information.

It's easy and fast to skip writing tests, write low-quality code,
do things manually instead of automating them, skip documentation, etc.
Doing these will make you feel like a rock star in the short term.
They'll impress non-engineers and might even get you promoted early in your career.

However, done correctly, all of those best practices pay for themselves many times over in the long term.
Not only will they save you time, but they will also lead to higher-quality results.

## Automate everything

Anything that takes human effort is a source of wasted time and mistakes.
It's rare for automating something to be more time-consuming than doing it many times manually.

Human intervention should only be necessary in emergencies (because it might take too much time to automate the fix)
or as a final approval for sensitive cases like infrastructure deployments.

## Define everything in the code

Software engineers have made an uncountable number of tools to define things in code.
That includes infrastructure.

Defining everything in code allows for real-world changes to be tested, previewed, and deployed predictably.

Defining everything in code allows code to be a source of truth for everything.
When something goes wrong, we can trace real-world changes back to changes in code.

Defining everything in code allows readers and AI tools to find information easily.

## Containerize everything

Every difference between environments makes predictability, development, and debugging more difficult.
[OCI][1] Containers are the best tool for guaranteeing that the environment will be consistent and predictable.

Every commit in the main branch should map to a consistent set of publicly accessible container images we generate.
Requiring developers to create container images independently defeats the purpose of containers.

The only exception to containerization is if you're writing a program for a client that cannot run a container practicably
such as the browser, mobile device, or a resource-constrained device.

## Use Bazel as much as possible

[Bazel][2] is an open-source hermetic build system for arbitrary program types.
It doesn't guarantee universally consistent outputs but ensures that the same input produces the same output.
This guarantee also allows for aggressive caching and incremental builds, making it faster than other build systems.

There are similar tools, such as Buck and Pants. @josalvatorre chose Bazel based on its apparent popularity
and because his workplace uses it, so learning it would help him there.

[1]: https://opencontainers.org/
[2]: https://bazel.build/
