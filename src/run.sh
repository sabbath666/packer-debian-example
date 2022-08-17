#!/usr/bin/env bash
export packer_username=packer@pve
export packer_password=JVMwh3Gly8LC1uaofW0M
envsubst < vars.pkr.hcl.template > vars.pkr.hcl
packer build .