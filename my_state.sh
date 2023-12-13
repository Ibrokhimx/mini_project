#!/bin/bash

# terraform state rm address
address=$(terraform state list)
for resource in "$address"; do
    echo "Removing Resource Address; $resource"
    terraform state rm $resource
    echo "_____DONE_____"
done
#echo "$address"
