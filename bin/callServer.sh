maxReqIndex=$1
portNumber=$2

while [ 1 ]
do
   num=$(jot -r 1 0 $maxReqIndex)
   curl http://localhost:$portNumber/lines/$num
   sleep 0.2
done
