#!/bin/bash

## Variables
RM="/bin/rm"
PATH="/backup4/SystemState/Profile/*"

## Cleaning up the Path
${RM} -rf ${PATH}
