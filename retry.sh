#!/bin/bash

for i in `seq 0 ${NUM_RETRIES}`; 
do 
	./deploy.sh && break || (./cleanup.sh || sleep ${BUILD_TIME})
done