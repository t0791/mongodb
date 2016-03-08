#!/bin/bash

result=$(su - gaussdba -c "gsql -d WSO2CARBON_DB -U apimgtdb -W $userApimgtdbPassword -p 5432 -f /opt/gaussdb/user.sql" >> /dev/null 2>&1)
exit $?
