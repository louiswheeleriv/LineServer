maxReqIndex=$1

while [ 1 ]
do
   num=$(jot -r 1 0 $maxReqIndex)
   curl http://localhost:3000/lines/$num
   sleep 0.2
done
