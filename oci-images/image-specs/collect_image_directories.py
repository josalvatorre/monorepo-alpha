#!/usr/bin/env python3
import argparse
import json
import pathlib
import typing


def _get_subdirectories_with_dockerfiles(image_specs_directory: pathlib.PosixPath) -> typing.Iterable[pathlib.PosixPath]:
    assert image_specs_directory.exists()

    first_level = next(image_specs_directory.walk(), None)
    if first_level is None:
        yield from []
        return

    root, dirs, _ = first_level
    for dir in dirs:
        if (root / dir / 'Dockerfile').exists():
            yield (root / dir).resolve(strict=True)

    return None


if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        prog='Collect image spec directories',
        description=(
            'Returns a json-parseable array of paths to the image spec directories.'
            ' This script is used by GitHub Actions workflows.'
        ),
    )
    parser.parse_args()
    assert pathlib.Path.cwd().name == 'monorepo-alpha', (
        f'Expected working directory to be repo root but was {pathlib.Path.cwd()} instead'
    )
    print(json.dumps(
        [
            {
                "name": path.name,
                "full_path": str(path),
            }
            for path in _get_subdirectories_with_dockerfiles(
                image_specs_directory=pathlib.PosixPath('./oci-images/image-specs'),
            )
        ],
        sort_keys=True,
        # We don't use indenting so that there's no multiline parsing required.
    ))
