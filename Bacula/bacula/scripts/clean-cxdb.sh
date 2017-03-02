#!/bin/bash

## Variables
RM="/bin/rm"
PATH="/backup4/SystemState/Citrix-XenApp-DB/*"

## Cleaning up the Path
${RM} -rf ${PATH}
