#! /bash/sh
# Get session DONE
#parse session info DONE
#get Stores DONE
#parse and get store ids DONE
#pick a random store DONE
#get coupons of the store DONE
#parse coupon ids and pick a random one DONE
#perform a share and a redeem DONE
session_key="";
signature="";
currentTime="";
storeIds=();
couponIds=();
storeId="";
uid="";
mandatoryParams="";
random() {
	rand=$RANDOM;
	a=$1;
	echo $((rand % a));
}

init() {
	latRand=$(random 90);
	lngRand=$(random 180);
	uniqueIdRand=$(random 999999999);
	mandatoryParams="UserAgent=android&lng=$lngRand&lat=$latRand";
}
latRand="";
lngRand="";
uniqueIdRand="";
sessionHeader="";
getMethod="-X GET";
postMethod="-X POST";


getStores() {
	sessionHeader="-H Accept:application/json -H sessionKey:$session_key -H signature:$signature -H currentTime:$currentTime";
	url="http://stg.slocamo.com/slocamo/client-services/stores?$mandatoryParams";
	stores=`curl $sessionHeader $getMethod $url`;
	op=$(echo $stores|sed -e 's/\"idstore\":[0-9][0-9]*/\n&\n/g');
	re="\"idstore\":([0-9][0-9]*)"
	j=0;

	for a in $op
	do
    	if [[ $a =~ $re ]]; then
        	storeIds[$j]=${BASH_REMATCH[1]} ;
        	j=`expr $j + 1`;
    	fi
	done
}

getCoupons() {
	sessionHeader="-H Accept:application/json -H sessionKey:$session_key -H signature:$signature -H currentTime:$currentTime";
	size=${#storeIds[@]}
	randVal=$(random $size);
	storeId=${storeIds[$randVal]};
	url="http://stg.slocamo.com/slocamo/client-services/coupons?store-id=$storeId&currentTime=1374444444&$mandatoryParams";
	coupons=`curl $sessionHeader $getMethod $url`;

	op=$(echo $coupons|sed -e 's/\"idcoupons\":[0-9][0-9]*/\n&\n/g');
	re="\"idcoupons\":([0-9][0-9]*)"
	j=0;

	for a in $op
	do
	    if [[ $a =~ $re ]]; then
	        couponIds[$j]=${BASH_REMATCH[1]} ;
	        j=`expr $j + 1`;
	    fi
	done
}

createSession() {
	header="-H Accept:application/json -H partnerId:1001 -H apiKey:fa980c9fdf11ab88339eefbf1ab3f4be46c6bc61";
	curlData="-d $mandatoryParams&network-unique-id=$uniqueIdRand&type=facebook";
	url="http://stg.slocamo.com/slocamo/client-services/session";
	response=`curl $header $postMethod $curlData $url`;
	key="session_key";
	re="\"$key\":\"([^\"]*)\""
	if [[ $response =~ $re ]]; then

	    session_key="${BASH_REMATCH[1]}"
	fi

	key="session_secret";
	re="\"$key\":\"([^\"]*)\""
	if [[ $response =~ $re ]]; then

	    session_secret="${BASH_REMATCH[1]}"
	fi

	key="uid";
	re="\"$key\":([0-9][0-9]*)"
	if [[ $response =~ $re ]]; then

	    uid="${BASH_REMATCH[1]}"
	fi
	currentTime="123";
	signature=`echo -n "$session_secret$currentTime" | openssl dgst -sha1 |awk '{print $NF}'`;
	#Calling stores only once, just to make some optimization.
	getStores;
}

postRedeemCoupon() {
	sessionHeader="-H Accept:application/json -H sessionKey:$session_key -H signature:$signature -H currentTime:$currentTime";
	size=${#couponIds[@]}
	randVal=$(random $size);
	couponId=${couponIds[$randVal]};
	#echo $couponId
	curlData="-d $mandatoryParams&idcoupons=$couponId&idstore=$storeId&redeem_date=545454545";
	url="http://stg.slocamo.com/slocamo/client-services/coupon-redeems";
	`curl $sessionHeader $postMethod $curlData $url`;
}

postShareCoupon() {
	sessionHeader="-H Accept:application/json -H sessionKey:$session_key -H signature:$signature -H currentTime:$currentTime";
	size=${#couponIds[@]}
	randVal=$(random $size);
	couponId=${couponIds[$randVal]};
	curlData="-d $mandatoryParams&idcoupons=$couponId&idstore=$storeId&alloc_type=1&alloc_date=23443434&forward_count=1&forwarded_by=$uid&accepted_status=1";
	url="http://stg.slocamo.com/slocamo/client-services/user-coupons";
	`curl $sessionHeader $postMethod $curlData $url`;
}
reset() {
	couponIds=();
	uid="";
	session_key="";
	session_secret="";
	signature="";
	storeId="";
}
getTimeInMillis() {
	echo $(($(date +%s%N)/1000000));
}
main() {
	init;
	timeInMillis=$(getTimeInMillis);
	createSession;	
	timeInMillis=`expr $(getTimeInMillis) - $timeInMillis`;
	echo "Session: $timeInMillis";
	timeInMillis=$(getTimeInMillis);
	getCoupons;
	timeInMillis=`expr $(getTimeInMillis) - $timeInMillis`;
	echo "Coupons: $timeInMillis";
	timeInMillis=$(getTimeInMillis);
	postRedeemCoupon;
	timeInMillis=`expr $(getTimeInMillis) - $timeInMillis`;
	echo "Redeem: $timeInMillis";
	timeInMillis=$(getTimeInMillis);
	postShareCoupon;
	timeInMillis=`expr $(getTimeInMillis) - $timeInMillis`;
	echo "Share: $timeInMillis";
	reset;
}

for (( i=0; i<=$1; i++ ))
do 
  main
done
