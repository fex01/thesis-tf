
for i in $(seq 99); do
    curl -X POST http://localhost:8080/job/thesis/build?delay=0sec --data verbosity=high --user admin:e17a935058ef4a6ca1cd07aec9a0de45
    echo "execution $i"
    sleep 40
done