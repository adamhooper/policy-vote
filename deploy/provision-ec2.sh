#!/bin/bash

# Set AWS_KEYPAIR_NAME, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_DEFAULT_REGION
. ~/.aws/aws-adamhooper-credentials.sh

type -p aws >/dev/null || fatal 'You need the `aws` command in your $PATH'
type -p ssh >/dev/null || fatal 'You need the `ssh` command in your $PATH'

AVAILABILITY_ZONE=us-east-1a
TAG=macleans-policy-vote-2015
BASE_IMAGE=ami-1733fc7c # https://cloud-images.ubuntu.com/releases/vivid/release-20150707/ us-east-1 64-bit hvm

[ -z "$DEPLOY_ENV" ] && &>2 echo 'Must be run with DEPLOY_ENV=production or DEPLOY_ENV=staging' && exit 1

VPC_ID=vpc-3bbea35e # macleans: a VPC, 10.1.0.0/16
SUBNET_ID=subnet-914307c8 # macleans: VPC macleans, zone us-east-1a, 10.1.0.0/24, auto-assign public IP
# Also need an internet gateway, igw-66bbf203, attached to macleans VPC, added to 0.0.0.0/0 in macleans route table

ELASTIC_IP_ADDRESS_production=52.2.169.255
ELASTIC_IP_ID_production=eipalloc-29e7b94c
ELASTIC_IP_ADDRESS_staging=52.6.146.132
ELASTIC_IP_ID_staging=eipalloc-3f65465a

X="ELASTIC_IP_ADDRESS_$DEPLOY_ENV"
ELASTIC_IP_ADDRESS=${!X}
X="ELASTIC_IP_ID_$DEPLOY_ENV"
ELASTIC_IP_ID=${!X}

VOLUME_ID_production=vol-e6ec421d # macleans-policy-vote-2015: 40GB GP2 (big so it'll get IOPS)
VOLUME_ID_staging=vol-9b3caa60

X="VOLUME_ID_$DEPLOY_ENV"
VOLUME_ID=${!X}

SECURITY_GROUP_ID=sg-ff449098 # macleans-policy-vote-2015: VPC macleans, inbound HTTP and SSH from Anywhere

wait_for_ssh() {
  success=$(ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no ubuntu@$1 echo 'success' 2>/dev/null)
  if [ 'success' != "$success" ]; then
    >&2 echo "Sleeping waiting for $1 to respond to SSH..."
    sleep 5
    wait_for_ssh $1
  else
    >&2 echo "$1 is up"
  fi
}

wait_for_cloud_init() {
  line=$(do_ssh $1 ls /run/cloud-init/result.json 2>/dev/null)
  if [ '/run/cloud-init/result.json' != "$line" ]; then
    >&2 echo "Sleeping waiting for $1 to finish cloud-init..."
    sleep 5
    wait_for_cloud_init $1
  else
    >&2 echo "$1 is finished cloud-init"
  fi
}

do_ssh() {
  ip=$(shift)
  ssh ubuntu@$ELASTIC_IP_ADDRESS "$@"
}

get_instance_ip() {
  aws ec2 describe-instances \
    --instance-ids $1 \
    --output text \
    --query 'Reservations[*].Instances[*].PublicIpAddress'
}

wait_for_instance_ip() {
  ip=$(get_instance_ip $1)
  if [ -z "$ip" ]; then
    >&2 echo "Waiting for $1 to get an ip address..."
    sleep 1
    wait_for_instance_ip $1
  else
    echo $ip
  fi
}

run_server() {
  instance_id=$(aws ec2 run-instances \
    --image-id $BASE_IMAGE \
    --instance-type t2.micro \
    --placement AvailabilityZone=$AVAILABILITY_ZONE \
    --key-name $AWS_KEYPAIR_NAME \
    --subnet-id $SUBNET_ID \
    --security-group-ids $SECURITY_GROUP_ID \
    --user-data "file://cloud-init.txt" \
    | grep 'InstanceId' | cut -d'"' -f4)

  instance_ip=$(wait_for_instance_ip $instance_id)
  >&2 echo "Instance $instance_id has IP address $instance_ip"

  wait_for_ssh $instance_ip

  >&2 echo "Attaching $VOLUME_ID to $instance_id..."
  aws ec2 attach-volume \
    --volume-id $VOLUME_ID \
    --instance-id $instance_id \
    --device 'xvdf' \
    >/dev/null

  >&2 echo "Attaching $ELASTIC_IP_ADDRESS to $instance_id..."
  >&2 aws ec2 associate-address \
    --instance-id $instance_id \
    --allocation-id $ELASTIC_IP_ID \
    >/dev/null
  >&2 echo "Instance $instance_id associated with public IP $ELASTIC_IP_ADDRESS"

  echo $instance_id
}

>&2 echo "Ensuring instance is launched..."
instance_id=$(run_server)
wait_for_cloud_init $ELASTIC_IP_ADDRESS
>&2 echo "Up and running at http://$ELASTIC_IP_ADDRESS"
