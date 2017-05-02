rm -rf /tmp/nn_dist \
& python nn_distributed.py --ps_hosts=localhost:2223 --worker_hosts=localhost:2225 --job_name=ps --task_index=0 \
& python nn_distributed.py --ps_hosts=localhost:2223 --worker_hosts=localhost:2225 --job_name=worker --task_index=0
 
