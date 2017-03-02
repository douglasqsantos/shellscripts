#!/bin/bash

## Variables
RM="/bin/rm"
PATH="/backup2/SystemState/Citrix-XenApp15/*"

## Cleaning up the Path
${RM} -rf ${PATH}
