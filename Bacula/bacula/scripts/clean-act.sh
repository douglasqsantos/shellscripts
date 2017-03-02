#!/bin/bash

## Variables
RM="/bin/rm"
PATH="/backup4/SystemState/Actinio/*"

## Cleaning up the Path
${RM} -rf ${PATH}
