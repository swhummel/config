#! /bin/bash
root="$(git rev-parse --show-toplevel)"; vi $(git -C "$root" show --name-only --pretty="" --diff-filter=AMR HEAD | sed "s|^|$root/|")
