#!/usr/bin/env bash

STACK_NAME="ks-5-ec2"
TEMPLATE_FILE="$(pwd)/ec2-template.yaml"

[[ -f "$HOME/.aliases" ]] && source "$HOME/.aliases"
shopt -s expand_aliases

[[ ! -f "$TEMPLATE_FILE" ]] && echo "ERROR: $TEMPLATE_FILE not found" >&2 && exit 1

container_file="$(basename "$TEMPLATE_FILE")"

aws cloudformation create-stack --stack-name $STACK_NAME --template-body file:///aws/$container_file

[[ "$?" -eq 0 ]] && {
    echo "Waiting for stack completion..."
    aws cloudformation wait stack-create-complete --stack-name $STACK_NAME
    ret="$?"
} || {
    echo "ERROR: problem with launching your stack" >&2
    ret=1
}

aws cloudformation describe-stacks --stack-name $STACK_NAME | yq eval -P
aws ec2 describe-instances --filters \
    Name=tag:Name,Values=ubuntu-01,msws-01 \
    Name=instance-state-name,Values=running,pending | yq eval -P

aws cloudformation describe-stack-events --stack-name $STACK_NAME

exit 0
