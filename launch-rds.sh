#!/bin/bash


mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

if [ ${#dbInstanceARR[@]} -gt 0 ]
   then
   # echo "Deleting existing RDS database-instances"
   LENGTH=${#dbInstanceARR[@]}

      for (( i=0; i<${LENGTH}; i++));
      do
      if [ ${dbInstanceARR[i]} == "lsl-db" ] 
     then 
      echo "db exists"
     else
     aws rds create-db-instance --db-instance-identifier lsl-db --db-instance-class db.t1.micro --engine MySQL --master-username controller --master-user-password ilovebunnies --allocated-storage 5
      fi  
     done
fi


