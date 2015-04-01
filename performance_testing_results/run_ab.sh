#!/bin/bash

maxSteps=3
nRequests=10000
nConcurrency=500

# Type of request true = ADD, false = QUERY
bAddDoc=false

bWriteToFile=true
datetime=$(date "+%Y.%m%d-%H.%M.%S")
date2=$(date "+%Y-%m-%d")

if [ "$bAddDoc" = true ]; then
    # DOC ADD
    outFile="./exp_output/exp-add-$date2-nrequests-$nRequests-nconc-$nConcurrency-steps-$maxSteps.txt"
else
    # QUERY
    outFile="./exp_output/exp-query-$date2-nrequests-$nRequests-nconc-$nConcurrency-steps-$maxSteps.txt"
fi
echo $outFile

if [ "$bWriteToFile" = true ]; then 
    cat /dev/null > $outFile
fi

if [ "$bAddDoc" = true ]; then
    echo "run time = $datetime, num requests = $nRequests, num concurrencies = $nConcurrency [ADD DOC]"
else
    echo "run time = $datetime, num requests = $nRequests, num concurrencies = $nConcurrency [QUERY]"
fi

if [ "$bWriteToFile" = true ]; then
    if [ "$bAddDoc" = true ]; then
	echo "run time = $datetime, num requests = $nRequests, num concurrencies = $nConcurrency, num steps/runs = $maxSteps [DOC ADD]" >> $outFile
    else
	echo "run time = $datetime, num requests = $nRequests, num concurrencies = $nConcurrency, num steps/runs = $maxSteps [QUERY]" >> $outFile
    fi

    echo "run,time_taken_s,requests_per_sec,time_per_request_ms_all_concurrent_requests,total_bytes_transferred,complete_requests,failed_requests,transfer_rate_kb_per_sec_received,errors" >> $outFile
fi

for (( i = 1; i <= $maxSteps; i++ ))
do
    echo "running step: $i of $maxSteps [#requests $nRequests, #conc $nConcurrency]"

    if [ "$bAddDoc" = true ]; then
	ab -n $nRequests -c $nConcurrency -s 60 -p single_event.json -T 'application/json' -e ab_out.csv https://las-skylr.oscar.ncsu.edu/api/data/document/add 1> tmpout.ab 2>error.del
    else
	ab -n $nRequests -c $nConcurrency -s 60 -p query_singleton.json -T 'application/json' -e ab_out.csv https://las-skylr.oscar.ncsu.edu/api/data/document/query 1> tmpout.ab 2>error.del
    fi

    cat error.del | (while read err
	do
	if echo "$err" | grep -q "SSL handshake failed"; then
	    count=$((count+1))
	fi
	done
    echo "***********************"
    echo "Num errors: $count"

    # parse output of ab command
    cat tmpout.ab | (while read line
	do

	#echo "line> $line"
	OLDIFS=$IFS
	if echo "$line" | grep -q "Time taken for tests"; then
	    IFS=':' read -a arr <<< "$line"
	    IFS=$OLDIFS
	    timeTaken=${arr[1]}
	    #echo "TIME TAKEN:" $timeTaken

	elif echo "$line" | grep -q "Complete requests"; then
	    IFS=':' read -a arr <<< "$line"
	    IFS=$OLDIFS
	    completeRequests=${arr[1]}

	elif echo "$line" | grep -q "Failed requests"; then
	    IFS=':' read -a arr <<< "$line"
	    IFS=$OLDIFS
	    failedRequests=${arr[1]}

	elif echo "$line" | grep -q "Requests per second"; then
	    IFS=':' read -a arr <<< "$line"
	    IFS=$OLDIFS
	    requestsPerSec=${arr[1]}

	elif echo "$line" | grep -q "Time per request"; then
	    IFS=':' read -a arr <<< "$line"
	    IFS=$OLDIFS
	    timePerRequest2=${arr[1]}

	elif echo "$line" | grep -q "Total transferred"; then
	    IFS=':' read -a arr <<< "$line"
	    IFS=$OLDIFS
	    totalTransferred=${arr[1]}

	elif echo "$line" | grep -q "Transfer rate"; then
	    IFS=':' read -a arr <<< "$line"
	    IFS=$OLDIFS
	    transferRate=${arr[1]}

	elif echo "$line" | grep -q "SSL handshake failed"; then
	    (count++)
	    echo "$line > $count"
	    
	fi
	done

    # process metrics extracted
    #echo "TIME TAKEN: $timeTaken"
    #echo "REQ/sec: $requestsPerSec"
    #echo "TIME / request: $timePerRequest2"
    #echo "TOTAL XFERRED: $totalTransferred"
    #echo "error: $count"
    OLDIFS=$IFS
    IFS=' ' read -a timeTaken <<< "$timeTaken"
    IFS=' ' read -a requestsPerSec <<< "$requestsPerSec"
    IFS=' ' read -a timePerRequest2 <<< "$timePerRequest2"
    IFS=' ' read -a totalTransferred <<< "$totalTransferred"
    IFS=' ' read -a completeRequests <<< "$completeRequests"
    IFS=' ' read -a failedRequests <<< "$failedRequests"
    IFS=' ' read -a transferRate <<< "$transferRate"
    if [ "$bWriteToFile" = true ]; then
	echo "$i,$timeTaken,$requestsPerSec,$timePerRequest2,$totalTransferred,$completeRequests,$failedRequests,$transferRate,$count" >> $outFile
    fi
))
done
