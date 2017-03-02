#!/bin/bash

## Variables
RM="/bin/rm"
PATH="/backup2/SystemState/Citrix-XenApp5/*"

## Cleaning up the Path
${RM} -rf ${PATH}
