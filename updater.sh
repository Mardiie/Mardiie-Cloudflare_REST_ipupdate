#!/bin/bash
#
##user variables
#email adress for your CloudFlare account
email=''
#your CloudFlare API key
key=''
#script and record file directory
workdir=''

##program variables
time=$(date +%d.%m.%Y-%H:%M)
grepip='[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}\.[[:digit:]]\{1,3\}'
grepname='\"name\"\:\"[[:alnum:]]\{0,15\}\.\{0,1\}[[:alnum:]]\{1,15\}\.[[:alnum:]]\{1,3\}\"'
hostip=$(dig +short myip.opendns.com @resolver1.opendns.com)
logdir=/var/log/cfdns/

function writelog {
	local logline=$1
	local logname="cfdns.log.1"
	cd $logdir
	echo $logline >> $logname
}

function checkdir {
	if [ ! -d $logdir ]
	then	
		mkdir $logdir
	fi
}

function checklogs {
	cd $logdir
	local ls=$(ls)
	local count=0
	for log in $ls
		do
			count=$[ $count + 1 ]
		done
	echo $count
}

function renamelogs {
	cd $logdir
	local ls=$(ls)
	local n=1
	for log in $ls
	do
		n=$((++n))
		new_name=$(echo $log | sed -E 's/[[:digit:]]/'$n'/')
		mv $log /tmp/$new_name
	done
	mv /tmp/cfdns.log.* .
}

function createlog {
	local logname="cfdns.log.1"
	cd $logdir
	touch $logname
}

function checklines {
	cd $logdir
	local ls=$(ls)
	for log in $ls
	do
		if [[ $log =~ "cfdns.log.1" ]]
		then
			lines=$(wc -l $log | sed -E 's/cfdns.log.1//')
			if [ $lines -ge 100 ]
			then
				renamelogs
				createlog
			fi
		fi
	done
}

function log {
	local logline=$1
	local ls=$(ls)
	local count=0
	checkdir
	if [ -n "$ls" ]
	then
			count=$(checklogs)
			if [ $count -eq 10 ]
			then
				checklines "$count"
				rm $logdir/cfdns.log.$count		
				writelog "$logline"
			elif [ $count -eq 0 ]
			then
				createlog
				writelog "$logline"
			elif [ $count -lt 10 ]
			then
				checklines "$count"
				writelog "$logline"
			fi	
	elif [ -z $ls ]
	then
		createlog
	fi
}

function get_record {
	local _ip=$4
	local _name=$5
	local tmp=$(curl -s -X GET $1 -H "Content-Type: application/json" -H "X-Auth-Key: $2" -H "X-Auth-Email: $3") 
	local recordip=$(echo $tmp | grep -o $grepip)
	local recordname=$(echo $tmp | grep -o $grepname | cut -d \" -f 4)
	eval $_ip="'$recordip'"
	eval $_name="'$recordname'"
}

function update_record {	
	local data='{"type":"A","name":"'"$5"'","content":"'"$4"'","ttl":0,"proxied":false}'
	local _resultip=$6
	set=$(curl -s -X PUT $1 -H "Content-Type: application/json" -H "X-Auth-Key: $2" -H "X-Auth-Email: $3" --data $data | grep -o $grepip)
	eval $_resultip="'$set'"
}

wget -q --spider https://google.nl
if [ $? -eq 0 ]
then
	for record in $(cat $workdir/records)
	do
		if [[ $record == https* ]]
		then
			get_record "$record" "$key" "$email" returnip returnname
			if [ $returnip != $hostip ]
			then
				update_record "$record" "$key" "$email" "$hostip" "$returnname" resultip
				logline=$(echo -e "$time\t$returnname IP address was $returnip and has been updated to $resultip.")
				log "$logline"
			else
				logline=$(echo -e "$time\t$returnname IP address is $returnip which is your current outside IP.")
				log "$logline"
			fi			
		fi		
	done
fi
