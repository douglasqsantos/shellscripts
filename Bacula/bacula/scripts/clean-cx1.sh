#!/bin/bash

## Variables
RM="/bin/rm"
PATH="/backup4/SystemState/Citrix-XenApp1/*"

## Cleaning up the Path
${RM} -rf ${PATH}
