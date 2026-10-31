#!/usr/bin/env python3
"""Extract all direct/sidecar/init-container image references from Helm-rendered K8s YAML."""
import sys
import yaml

source, dest = sys.argv[1:]
images = set()

def walk(node):
    if isinstance(node, dict):
        for k, v in node.items():
            if k == 'image' and isinstance(v, str) and v.strip():
                images.add(v.strip())
            walk(v)
    elif isinstance(node, list):
        for x in node:
            walk(x)

with open(source) as f:
    for document in yaml.safe_load_all(f):
        walk(document)
if not images:
    raise SystemExit('ERROR: rendered chart contains no container images')
with open(dest, 'w') as f:
    for img in sorted(images):
        f.write(img + '\n')
print('Images:', len(images))
