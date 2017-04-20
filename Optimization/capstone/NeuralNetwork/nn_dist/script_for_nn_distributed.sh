rm -rf /tmp/nn_dist \
& python nn_distributed.py --ps_hosts=localhost:2223,localhost:2224 --worker_hosts=localhost:2225,localhost:2226,localhost:2227,localhost:2228 --job_name=ps --task_index=0 \
& python nn_distributed.py --ps_hosts=localhost:2223,localhost:2224 --worker_hosts=localhost:2225,localhost:2226,localhost:2227,localhost:2228 --job_name=ps --task_index=1 \
& python nn_distributed.py --ps_hosts=localhost:2223,localhost:2224 --worker_hosts=localhost:2225,localhost:2226,localhost:2227,localhost:2228 --job_name=worker --task_index=0 \
& python nn_distributed.py --ps_hosts=localhost:2223,localhost:2224 --worker_hosts=localhost:2225,localhost:2226,localhost:2227,localhost:2228 --job_name=worker --task_index=1 \
& python nn_distributed.py --ps_hosts=localhost:2223,localhost:2224 --worker_hosts=localhost:2225,localhost:2226,localhost:2227,localhost:2228 --job_name=worker --task_index=2 \
& python nn_distributed.py --ps_hosts=localhost:2223,localhost:2224 --worker_hosts=localhost:2225,localhost:2226,localhost:2227,localhost:2228 --job_name=worker --task_index=3
 
