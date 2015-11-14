#!/usr/local/bin/bash
#./launch.sh ami-d05e75b8 3 t2.micro sg-bf9a15d9 subnet-1a25d66c itmo544-fall2015 itmo544-role1
./cleanup.sh

#declare an array in bash 
declare -a instanceARR


mapfile -t instanceARR < <(aws ec2 run-instances --image-id $1 --count $2 --instance-type $3 --security-group-ids $4 --subnet-id $5 --key-name $6 --associate-public-ip-address --iam-instance-profile Name=$7 --user-data file://../itmo544-env/install-webserver.sh --output table | grep InstanceId | sed "s/|//g" | tr -d ' ' | sed "s/InstanceId//g")
echo ${instanceARR[@]}

aws ec2 wait instance-running --instance-ids ${instanceARR[@]}
echo "instances are running"

ELBURL=(`aws elb create-load-balancer --load-balancer-name itmo544-lsl-elb --listeners Protocol=HTTP,LoadBalancerPort=80,InstanceProtocol=HTTP,InstancePort=80 --security-groups $4 --subnets $5 --output=text`)
echo $ELBURL

echo -e "\nFinished launching ELB and sleeping 20 seconds"
for i in {0..20}; do echo -ne '.'; sleep 1;done
echo -e "\n"



aws elb register-instances-with-load-balancer --load-balancer-name itmo544-lsl-elb --instances ${instanceARR[@]}



aws elb configure-health-check --load-balancer-name itmo544-lsl-elb --health-check Target=HTTP:80/index.html,Interval=30,UnhealthyThreshold=2,HealthyThreshold=2,Timeout=3



echo -e "\nWaiting an additional 20 seconds - before opening the ELB in a webbrowser"
for i in {0..20}; do echo -ne '.'; sleep 1;done



echo -e "\n-create launch-configuration"
aws autoscaling create-launch-configuration --launch-configuration-name itmo544-launch-config --image-id $1 --key-name $6 --security-groups $4 --instance-type $3 --user-data file://../itmo544-env/install-webserver.sh --iam-instance-profile $7




echo -e "\n-create auto-scaling-group"
aws autoscaling create-auto-scaling-group --auto-scaling-group-name itmo-544-extended-auto-scaling-group-2 --launch-configuration-name itmo544-launch-config --load-balancer-names itmo544-lsl-elb --health-check-type ELB --min-size 3 --max-size 6 --desired-capacity 3 --default-cooldown 600 --health-check-grace-period 120 --vpc-zone-identifier $5



echo -e "\n-create db"
aws rds create-db-subnet-group --db-subnet-group-name itmo544 --db-subnet-group-description "itmo544" --subnet-ids $5 subnet-f32912d8

mapfile -t dbInstanceARR < <(aws rds describe-db-instances --output json | grep "\"DBInstanceIdentifier" | sed "s/[\"\:\, ]//g" | sed "s/DBInstanceIdentifier//g" )

   
   LENGTH=${#dbInstanceARR[@]}
       for (( i=0; i<=${LENGTH}; i++));
      do
      if [[ ${dbInstanceARR[i]} == "lsl-db" ]]
     then 
      echo "db exists"
     else
     aws rds create-db-instance --db-name itmo544mp1 --db-instance-identifier lsl-db --db-instance-class db.t1.micro --engine MySQL --master-username lisiling --master-user-password ilovebunnies --allocated-storage 5 --db-subnet-group-name itmo544 --publicly-accessible
      fi  
      aws rds wait db-instance-available --db-instance-identifier lsl-db
     done  
#fi

#php ./setup.php