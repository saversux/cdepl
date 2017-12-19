#!/bin/bash

unpack_logfiles()
{
    local result_archives_path=$1
    local out_path=$2

    if [ -d $out_path ]; then
        rm -rf $out_path
    fi

    mkdir -p $out_path

    cd $out_path

    for f in ${result_archives_path}/*; do
        local file="$(basename $f)"
        local extension="${file##*.}"
        local filename="${file%.tar.gz}"

        if [ "$extension" = "gz" ]; then
            local out_dir=${out_path}/$filename

            echo "Unpacking $file to $out_dir..."
            mkdir $out_dir
            cd $out_dir

            tar -xzvf $f > /dev/null 2>&1
        fi
    done
}

create_csv_single_benchmark()
{
    local deployment_out_dir=$1
    local out_path=$2

    if [ ! -d "$deployment_out_dir" ]; then
        echo "Deployment out dir $deployment_out_dir does not exist"
        exit 1
    fi

    mkdir -p $out_path

    # Check if directory structure is correct
    if [ ! -d "${deployment_out_dir}/dxnet/log" ]; then
        echo "Invalid directory structure in $deployment_out_dir"
        exit 1
    fi

    echo "Creating table of log output from ${deployment_out_dir}"

    # Detect parameters using the directory

    local out_file=""

    local avg_send_runtime="0"
    local avg_send_time_per_msg="0"
    local avg_send_throughput="0"
    local avg_send_throughput_overhead="0"

    local avg_recv_runtime="0"
    local avg_recv_time_per_msg="0"
    local avg_recv_throughput="0"
    local avg_recv_throughput_overhead="0"

    local min_send_runtime=""
    local min_send_time_per_msg=""
    local min_send_throughput=""
    local min_send_throughput_overhead=""

    local min_recv_runtime=""
    local min_recv_time_per_msg=""
    local min_recv_throughput=""
    local min_recv_throughput_overhead=""

    local max_send_runtime=""
    local max_send_time_per_msg=""
    local max_send_throughput=""
    local max_send_throughput_overhead=""

    local max_recv_runtime=""
    local max_recv_time_per_msg=""
    local max_recv_throughput=""
    local max_recv_throughput_overhead=""

    local counter="0"
    local header=""
    local summaries=""
    local node_details=""

    local node_count=$(ls -1 "${deployment_out_dir}/dxnet/log" | wc -l)

    for logfile in ${deployment_out_dir}/dxnet/log/*; do
        local file="$(basename $logfile)"
        local filename="${file%}"
        local node_id=$(echo $filename | sed -n -E "s/node([0-9]*)/\1/p")
        echo "Parsing $filename..."

        # Grab config parameters from first node (same for further nodes)
        if [ ! "$out_file" ]; then
            local workload=$(cat $logfile | sed -n -E "s/\[SEND WORKLOAD\] ([0-9.]*)/\1/p")

            if [ ! "$workload" ]; then
                workload="unkn"
            fi

            local msg_size=$(cat $logfile |sed -n -E "s/\[SEND MSG SIZE\] ([0-9.]*)/\1/p")

            if [ ! "$msg_size" ]; then
                msg_size="unkn"
            fi

            local threads=$(cat $logfile | sed -n -E "s/\[SEND THREADS\] ([0-9.]*)/\1/p")

            if [ ! "$threads" ]; then
                threads="unkn"
            fi

            local msg_handlers=$(cat $logfile | sed -n -E "s/\[SEND MSG HANDLERS\] ([0-9.]*)/\1/p")

            if [ ! "$msg_handlers" ]; then
                msg_handlers="unkn"
            fi

            out_file="${out_path}/dxnet_bench_${workload}_${node_count}_${msg_size}_${threads}_${msg_handlers}.csv"

            # Print header with metadata
            header="#workload $workload, nodes $node_count, msg_size $msg_size, threads $threads, msg_handlers $msg_handlers\n"
            header="${header}#nodeid;send_runtime_ms;send_time_per_msg_ns;send_throughput_mb_sec;send_throughput_overhead_mb_sec;recv_runtime_ms;recv_time_per_msg_ns;recv_throughput_mb_sec;recv_throughput_overhead_mb_sec\n"
        fi

        local send_runtime=$(cat $logfile | sed -n -E "s/\[SEND RUNTIME\] ([0-9.]*) .*/\1/p")
        local send_time_per_msg=$(cat $logfile | sed -n -E "s/\[SEND TIME PER MESSAGE\] ([0-9.]*) .*/\1/p")
        local send_throughput=$(cat $logfile | sed -n -E "s/\[SEND THROUGHPUT\] ([0-9.]*) .*/\1/p")
        local send_throughput_overhead=$(cat $logfile | sed -n -E "s/\[SEND THROUGHPUT\] ([0-9.]*) .*/\1/p")

        local recv_runtime=$(cat $logfile | sed -n -E "s/\[RECV RUNTIME\] ([0-9.]*) .*/\1/p")
        local recv_time_per_msg=$(cat $logfile | sed -n -E "s/\[RECV TIME PER MESSAGE\] ([0-9.]*) .*/\1/p")
        local recv_throughput=$(cat $logfile | sed -n -E "s/\[RECV THROUGHPUT\] ([0-9.]*) .*/\1/p")
        local recv_throughput_overhead=$(cat $logfile | sed -n -E "s/\[RECV THROUGHPUT\] ([0-9.]*) .*/\1/p")

        # Calculate avg, min and max of all values
        # Avarage
        avg_send_runtime=$(echo "$avg_send_runtime + $send_runtime" | bc -l)
        avg_send_time_per_msg=$(echo "$avg_send_time_per_msg + $send_time_per_msg" | bc -l)
        avg_send_throughput=$(echo "$avg_send_throughput + $send_throughput" | bc -l)
        avg_send_throughput_overhead=$(echo "$avg_send_throughput_overhead + $send_throughput_overhead" | bc -l)

        avg_recv_runtime=$(echo "$avg_recv_runtime + $recv_runtime" | bc -l)
        avg_recv_time_per_msg=$(echo "$avg_recv_time_per_msg + $recv_time_per_msg" | bc -l)
        avg_recv_throughput=$(echo "$avg_recv_throughput + $recv_throughput" | bc -l)
        avg_recv_throughput_overhead=$(echo "$avg_recv_throughput_overhead + $recv_throughput_overhead" | bc -l)

        # Min
        if [ ! "$min_send_runtime" ] || [ "$(echo "$send_runtime < $min_send_runtime" | bc -l)" = "1" ]; then
            min_send_runtime=$send_runtime
        fi

        if [ ! "$min_send_time_per_msg" ] || [ "$(echo "$send_time_per_msg < $min_send_time_per_msg" | bc -l)" = "1"  ]; then
            min_send_time_per_msg=$send_time_per_msg
        fi

        if [ ! "$min_send_throughput" ] || [ "$(echo "$send_throughput < $min_send_throughput" | bc -l)" = "1"  ]; then
            min_send_throughput=$send_throughput
        fi

        if [ ! "$min_send_throughput_overhead" ] || [ "$(echo "$send_throughput_overhead < $min_send_throughput_overhead" | bc -l)" = "1"  ]; then
            min_send_throughput_overhead=$send_throughput_overhead
        fi


        if [ ! "$min_recv_runtime" ] || [ "$(echo "$recv_runtime < $min_recv_runtime" | bc -l)" = "1" ]; then
            min_recv_runtime=$recv_runtime
        fi

        if [ ! "$min_recv_time_per_msg" ] || [ "$(echo "$recv_time_per_msg < $min_recv_time_per_msg" | bc -l)" = "1" ]; then
            min_recv_time_per_msg=$recv_time_per_msg
        fi

        if [ ! "$min_recv_throughput" ] || [ "$(echo "$recv_throughput < $min_recv_throughput" | bc -l)" = "1" ]; then
            min_recv_throughput=$recv_throughput
        fi

        if [ ! "$min_recv_throughput_overhead" ] || [ "$(echo "$recv_throughput_overhead < $min_recv_throughput_overhead" | bc -l)" = "1" ]; then
            min_recv_throughput_overhead=$recv_throughput_overhead
        fi

        # Max
        if [ ! "$max_send_runtime" ] || [ "$(echo "$send_runtime > $max_send_runtime" | bc -l)" = "1"  ]; then
            max_send_runtime=$send_runtime
        fi

        if [ ! "$max_send_time_per_msg" ] || [ "$(echo "$send_time_per_msg > $max_send_time_per_msg" | bc -l)" = "1" ]; then
            max_send_time_per_msg=$send_time_per_msg
        fi

        if [ ! "$max_send_throughput" ] || [ "$(echo "$send_throughput > $max_send_throughput" | bc -l)" = "1" ]; then
            max_send_throughput=$send_throughput
        fi

        if [ ! "$max_send_throughput_overhead" ] || [ "$(echo "$send_throughput_overhead > $max_send_throughput_overhead" | bc -l)" = "1" ]; then
            max_send_throughput_overhead=$send_throughput_overhead
        fi


        if [ ! "$max_recv_runtime" ] || [ "$(echo "$recv_runtime > $max_recv_runtime" | bc -l)" = "1" ]; then
            max_recv_runtime=$recv_runtime
        fi

        if [ ! "$max_recv_time_per_msg" ] || [ "$(echo "$recv_time_per_msg > $max_recv_time_per_msg" | bc -l)" = "1" ]; then
            max_recv_time_per_msg=$recv_time_per_msg
        fi

        if [ ! "$max_recv_throughput" ] || [ "$(echo "$recv_throughput > $max_recv_throughput" | bc -l)" = "1" ]; then
            max_recv_throughput=$recv_throughput
        fi

        if [ ! "$max_recv_throughput_overhead" ] || [ "$(echo "$recv_throughput_overhead > $max_recv_throughput_overhead" | bc -l)" = "1" ]; then
            max_recv_throughput_overhead=$recv_throughput_overhead
        fi

        # Per node values
        node_details="${node_details}${node_id};${send_runtime};${send_time_per_msg};${send_throughput};${send_throughput_overhead};${recv_runtime};${recv_time_per_msg};${recv_throughput};${recv_throughput_overhead}\n"
        counter=$((counter + 1))
    done 

    # Finish avarage
    avg_send_runtime=$(echo "$avg_send_runtime / $counter" | bc -l)
    avg_send_time_per_msg=$(echo "$avg_send_time_per_msg / $counter" | bc -l)
    avg_send_throughput=$(echo "$avg_send_throughput / $counter" | bc -l)
    avg_send_throughput_overhead=$(echo "$avg_send_throughput_overhead / $counter" | bc -l)

    avg_recv_runtime=$(echo "$avg_recv_runtime / $counter" | bc -l)
    avg_recv_time_per_msg=$(echo "$avg_recv_time_per_msg / $counter" | bc -l)
    avg_recv_throughput=$(echo "$avg_recv_throughput / $counter" | bc -l)
    avg_recv_throughput_overhead=$(echo "$avg_recv_throughput_overhead / $counter" | bc -l)

    # Create summaries
    summaries="avg;${avg_send_runtime};${avg_send_time_per_msg};${avg_send_throughput};${avg_send_throughput_overhead};${avg_recv_runtime};${avg_recv_time_per_msg};${avg_recv_throughput};${avg_recv_throughput_overhead}\n"
    summaries="${summaries}min;${min_send_runtime};${min_send_time_per_msg};${min_send_throughput};${min_send_throughput_overhead};${min_recv_runtime};${min_recv_time_per_msg};${min_recv_throughput};${min_recv_throughput_overhead}\n"
    summaries="${summaries}max;${max_send_runtime};${max_send_time_per_msg};${max_send_throughput};${max_send_throughput_overhead};${max_recv_runtime};${max_recv_time_per_msg};${max_recv_throughput};${max_recv_throughput_overhead}\n"

    # Print to output
    printf "$header" > "$out_file"
    printf "$summaries" >> "$out_file"
    printf "$node_details" >> "$out_file"
}

create_csv_single_benchmark_progress()
{
    local deployment_out_dir=$1
    local out_path=$2

    if [ ! -d "$deployment_out_dir" ]; then
        echo "Deployment out dir $deployment_out_dir does not exist"
        exit 1
    fi

    mkdir -p $out_path

    # Check if directory structure is correct
    if [ ! -d "${deployment_out_dir}/dxnet/log" ]; then
        echo "Invalid directory structure in $deployment_out_dir"
        exit 1
    fi

    echo "Creating progress table of log output from ${deployment_out_dir}"

    # Detect parameters using the directory
    local out_file=""

    local node_count=$(ls -1 "${deployment_out_dir}/dxnet/log" | wc -l)

    for logfile in ${deployment_out_dir}/dxnet/log/*; do
        local file="$(basename $logfile)"
        local filename="${file%}"
        local node_id=$(echo $filename | sed -n -E "s/node([0-9]*)/\1/p")
        echo "Parsing $filename..."

        local workload=$(cat $logfile | sed -n -E "s/\[SEND WORKLOAD\] ([0-9.]*)/\1/p")

        if [ ! "$workload" ]; then
            workload="unkn"
        fi

        local msg_size=$(cat $logfile |sed -n -E "s/\[SEND MSG SIZE\] ([0-9.]*)/\1/p")

        if [ ! "$msg_size" ]; then
            msg_size="unkn"
        fi

        local threads=$(cat $logfile | sed -n -E "s/\[SEND THREADS\] ([0-9.]*)/\1/p")

        if [ ! "$threads" ]; then
            threads="unkn"
        fi

        local msg_handlers=$(cat $logfile | sed -n -E "s/\[SEND MSG HANDLERS\] ([0-9.]*)/\1/p")

        if [ ! "$msg_handlers" ]; then
            msg_handlers="unkn"
        fi

        out_file="${out_path}/dxnet_bench_progress_${node_id}_${workload}_${node_count}_${msg_size}_${threads}_${msg_handlers}.csv"

        # Print header with metadata
        printf "#node_id $node_id, workload $workload, nodes $node_count, msg_size $msg_size, threads $threads, msg_handlers $msg_handlers\n" >> "$out_file"
        printf "#timestamp_sec;tx_mb_sec;rx_mb_sec;txo_mb_sec;rxo_mb_sec\n" >> "$out_file"

        # Filter data and print
        cat $logfile | sed -n -E 's/.*\[PROGRESS\] ([0-9]*).*TX ([0-9.]*).*RX ([0-9.]*).*TXO ([0-9.]*).*RXO ([0-9.]*)/\1;\2;\3;\4;\5/p' >> "$out_file"
    done 
}

# Create a table with the progress of all nodes of a single benchmark iteration
# to compare the send and recv throughputs of the nodes
create_csvs_nodes_benchmark_progress()
{
    local table_path=$1
    local out_table_path=$2

    mkdir -p $out_table_path

    # First, iterate the single bench progress tables and collect the different 
    # combinations
    local list_count="0"
    local list=()
    local out_table_header=()

    for f in ${table_path}/*; do
        local file="$(basename $f)"
        local filename="${file%.csv}"

        if [[ "$filename" == "dxnet_bench_progress_"* ]]; then
            local file_node_id=$(cat $f | sed -n -E "s/.*node_id ([0-9]*).*/\1/p")
            local file_workload=$(cat $f | sed -n -E "s/.*workload ([0-9]*).*/\1/p")
            local file_nodes=$(cat $f | sed -n -E "s/.*nodes ([0-9]*).*/\1/p")
            local file_msg_size=$(cat $f | sed -n -E "s/.*msg_size ([0-9]*).*/\1/p")
            local file_threads=$(cat $f | sed -n -E "s/.*threads ([0-9]*).*/\1/p")
            local file_msg_handlers=$(cat $f | sed -n -E "s/.*msg_handlers ([0-9]*).*/\1/p")

            # check if entry exists
            local exists=""
            for i in $(seq 0 $list_count); do
                if [ "{list[$i]}" = "*_${file_workload}_${file_nodes}_${file_msg_size}_${file_threads}_${file_msg_handlers}" ]; then
                    exists="1"
                    break
                fi
            done

            if [ ! "$exists" ]; then
                list[$list_count]="*_${file_workload}_${file_nodes}_${file_msg_size}_${file_threads}_${file_msg_handlers}"
                out_table_header[$list_count]="#workload ${file_workload}, nodes ${file_nodes}, msg_size ${file_msg_size}, threads ${file_threads}, msg_handlers ${file_msg_handlers}"
                list_count=$((list_count + 1))
            fi
        fi
    done 

    # Now, for each combination we found, grab the benchmark outputs with 
    # different node ids and create the tables
    for i in $(seq 0 $((list_count - 1))); do
        local out_file="${out_table_path}/dxnet_bench_progress_${list[$i]}.csv"

        echo "Parsing for nodes progress table dxnet_bench_progress_${list[$i]}..."

        # replace * with x for filename
        out_file=$(echo "$out_file" | sed -e 's/\*/x/')

        local max_data_count="0"

        local max_node_count="0"
        local max_time_sec="0"
        local data_txo=()
        local data_rxo=()

        # Iterate all files matching the pattern
        for file in ${table_path}/dxnet_bench_progress_${list[$i]}.csv; do
            local file_txo=$(cat $file | tail -n+3 | cut -d ';' -f 4)
            local file_rxo=$(cat $file | tail -n+3 | cut -d ';' -f 5)

            local file_node_id=$(cat $file | sed -n -E "s/.*node_id ([0-9]*).*/\1/p")

            if [ "$((file_node_id + 1))" -gt "$max_node_count" ]; then
                max_node_count="$((file_node_id + 1))"
            fi

            local time_count="$(echo "$file_txo" | wc -l)"

            if [ "$time_count" -gt "$max_time_sec" ]; then
                max_time_sec="$time_count"
            fi

            data_txo[$file_node_id]="$file_txo"
            data_rxo[$file_node_id]="$file_rxo"
        done

        # Table header
        echo "#node_count $max_node_count" > "$out_file"

        header="#time_sec"

        # Assemble header
        for k in $(seq 0 $((max_node_count - 1))); do
            header="${header};node_${k}_txo_mb;node_${k}_rxo_mb"
        done

        echo "$header" >> "$out_file"

        # Table lines
        for j in $(seq 1 $max_time_sec); do
            # First column is time in sec
            line="${j}"
            
            # Assemble lines
            for k in $(seq 0 $((max_node_count - 1))); do
                txo_item=$(echo "${data_txo[$k]}" | head -n $j | tail -n 1)
                rxo_item=$(echo "${data_rxo[$k]}" | head -n $j | tail -n 1)

                line="${line};${txo_item};${rxo_item}"
            done

            echo "$line" >> "$out_file"
        done
    done 
}

create_csvs_increasing_node_counts()
{
    local table_path=$1
    local out_table_path=$2

    mkdir -p $out_table_path

    # First, iterate the single bench tables and collect the different combinations
    local list_count="0"
    local list=()
    local out_table_header=()

    for f in ${table_path}/*; do
        local file="$(basename $f)"
        local filename="${file%.csv}"

        if [[ "$filename" == "dxnet_bench_"* ]]; then
            local file_workload=$(cat $f | sed -n -E "s/.*workload ([0-9]*).*/\1/p")
            local file_nodes=$(cat $f | sed -n -E "s/.*nodes ([0-9]*).*/\1/p")
            local file_msg_size=$(cat $f | sed -n -E "s/.*msg_size ([0-9]*).*/\1/p")
            local file_threads=$(cat $f | sed -n -E "s/.*threads ([0-9]*).*/\1/p")
            local file_msg_handlers=$(cat $f | sed -n -E "s/.*msg_handlers ([0-9]*).*/\1/p")

            # check if entry exists
            local exists=""
            for i in $(seq 0 $list_count); do
                if [ "{list[$i]}" = "${file_workload}_*_${file_msg_size}_${file_threads}_${file_msg_handlers}" ]; then
                    exists="1"
                    break
                fi
            done

            if [ ! "$exists" ]; then
                list[$list_count]="${file_workload}_*_${file_msg_size}_${file_threads}_${file_msg_handlers}"
                out_table_header[$list_count]="#workload ${file_workload}, msg_size ${file_msg_size}, threads ${file_threads}, msg_handlers ${file_msg_handlers}"
                list_count=$((list_count + 1))
            fi
        fi
    done

    # Now, for each combination we found, grab the benchmark outputs with varying nodes counts and create the tables
    for i in $(seq 0 $((list_count - 1))); do
        local out_file="${out_table_path}/dxnet_bench_nodes_${list[$i]}.csv"

        echo "Parsing for node count table dxnet_bench_nodes_${list[$i]}..."

        # replace * with x for filename
        out_file=$(echo "$out_file" | sed -e 's/\*/x/')

        local max_node_count="0"
        local nodes_count="0"
        local nodes=()
        local data=()

        # Iterate all files matching the pattern
        for file in ${table_path}/dxnet_bench_${list[$i]}.csv; do
            local file_nodes=$(cat $file | sed -n -E "s/.*nodes ([0-9]*).*/\1/p")

            if [ "$file_nodes" -gt "$max_node_count" ]; then
                max_node_count="$file_nodes"
            fi

            nodes[$nodes_count]="$file_nodes"
            nodes_count=$((nodes_count + 1))

            local avg=$(cat $file | sed -n -E "s/avg;(.*)/\1/p")
            local min=$(cat $file | sed -n -E "s/min;(.*)/\1/p")
            local max=$(cat $file | sed -n -E "s/max;(.*)/\1/p")

            data[$file_nodes]="${file_nodes};${avg};${min};${max}"
        done

        # Table header
        echo "${out_table_header[$i]}" > "$out_file"
        echo "#node_count;" \
            "avg_send_runtime_ms;avg_send_time_per_msg_ns;avg_send_throughput_mb_sec;avg_send_throughput_overhead_mb_sec;avg_recv_runtime_ms;avg_recv_time_per_msg_ns;avg_recv_throughput_mb_sec;avg_recv_throughput_overhead_mb_sec;" \
            "min_send_runtime_ms;min_send_time_per_msg_ns;min_send_throughput_mb_sec;min_send_throughput_overhead_mb_sec;min_recv_runtime_ms;min_recv_time_per_msg_ns;min_recv_throughput_mb_sec;min_recv_throughput_overhead_mb_sec;" \
            "max_send_runtime_ms;max_send_time_per_msg_ns;max_send_throughput_mb_sec;max_send_throughput_overhead_mb_sec;max_recv_runtime_ms;max_recv_time_per_msg_ns;max_recv_throughput_mb_sec;max_recv_throughput_overhead_mb_sec" >> "$out_file"

        # Output data with increasing node count
        for j in $(seq 0 $max_node_count); do
            if [ "${data[$j]}" ]; then
                echo "${data[$j]}" >> "$out_file"
            fi
        done
    done 
}

create_csvs_increasing_msg_size()
{
    local table_path=$1
    local out_table_path=$2

    mkdir -p $out_table_path

    # First, iterate the single bench tables and collect the different combinations
    local list_count="0"
    local list=()
    local out_table_header=()

    for f in ${table_path}/*; do
        local file="$(basename $f)"
        local filename="${file%.csv}"

        if [[ "$filename" == "dxnet_bench_"* ]]; then
            local file_workload=$(cat $f | sed -n -E "s/.*workload ([0-9]*).*/\1/p")
            local file_nodes=$(cat $f | sed -n -E "s/.*nodes ([0-9]*).*/\1/p")
            local file_msg_size=$(cat $f | sed -n -E "s/.*msg_size ([0-9]*).*/\1/p")
            local file_threads=$(cat $f | sed -n -E "s/.*threads ([0-9]*).*/\1/p")
            local file_msg_handlers=$(cat $f | sed -n -E "s/.*msg_handlers ([0-9]*).*/\1/p")

            # check if entry exists
            local exists=""
            for i in $(seq 0 $list_count); do
                if [ "{list[$i]}" = "${file_workload}_${file_nodes}_*_${file_threads}_${file_msg_handlers}" ]; then
                    exists="1"
                    break
                fi
            done

            if [ ! "$exists" ]; then
                list[$list_count]="${file_workload}_${file_nodes}_*_${file_threads}_${file_msg_handlers}"
                out_table_header[$list_count]="#workload ${file_workload}, nodes ${file_nodes}, threads ${file_threads}, msg_handlers ${file_msg_handlers}"
                list_count=$((list_count + 1))
            fi
        fi
    done

    # Now, for each combination we found, grab the benchmark outputs with varying msg sizes and create the tables
    for i in $(seq 0 $((list_count - 1))); do
        local out_file="${out_table_path}/dxnet_bench_nodes_${list[$i]}.csv"

        echo "Parsing for msg size table dxnet_bench_nodes_${list[$i]}..."

        # replace * with x for filename
        out_file=$(echo "$out_file" | sed -e 's/\*/x/')

        local max_count="0"
        local data=()

        # Iterate all files matching the pattern
        for file in ${table_path}/dxnet_bench_${list[$i]}.csv; do
            local file_msg_size=$(cat $file | sed -n -E "s/.*msg_size ([0-9]*).*/\1/p")

            if [ "$file_msg_size" -gt "$max_count" ]; then
                max_count="$file_msg_size"
            fi

            local avg=$(cat $file | sed -n -E "s/avg;(.*)/\1/p")
            local min=$(cat $file | sed -n -E "s/min;(.*)/\1/p")
            local max=$(cat $file | sed -n -E "s/max;(.*)/\1/p")

            data[${file_msg_size}]="${file_msg_size};${avg};${min};${max}"
        done

        # Table header
        echo "${out_table_header[$i]}" > "$out_file"
        echo "#msg_size;" \
            "avg_send_runtime_ms;avg_send_time_per_msg_ns;avg_send_throughput_mb_sec;avg_send_throughput_overhead_mb_sec;avg_recv_runtime_ms;avg_recv_time_per_msg_ns;avg_recv_throughput_mb_sec;avg_recv_throughput_overhead_mb_sec;" \
            "min_send_runtime_ms;min_send_time_per_msg_ns;min_send_throughput_mb_sec;min_send_throughput_overhead_mb_sec;min_recv_runtime_ms;min_recv_time_per_msg_ns;min_recv_throughput_mb_sec;min_recv_throughput_overhead_mb_sec;" \
            "max_send_runtime_ms;max_send_time_per_msg_ns;max_send_throughput_mb_sec;max_send_throughput_overhead_mb_sec;max_recv_runtime_ms;max_recv_time_per_msg_ns;max_recv_throughput_mb_sec;max_recv_throughput_overhead_mb_sec" >> "$out_file"

        # Output data with increasing node count
        for j in $(seq 0 $max_count); do
            if [ "${data[${j}]}" ]; then
                echo "${data[${j}]}" >> "$out_file"
            fi
        done
    done 
}

create_csvs_increasing_thread_count()
{
    local table_path=$1
    local out_table_path=$2

    mkdir -p $out_table_path

    # First, iterate the single bench tables and collect the different combinations
    local list_count="0"
    local list=()
    local out_table_header=()

    for f in ${table_path}/*; do
        local file="$(basename $f)"
        local filename="${file%.csv}"

        if [[ "$filename" == "dxnet_bench_"* ]]; then
            local file_workload=$(cat $f | sed -n -E "s/.*workload ([0-9]*).*/\1/p")
            local file_nodes=$(cat $f | sed -n -E "s/.*nodes ([0-9]*).*/\1/p")
            local file_msg_size=$(cat $f | sed -n -E "s/.*msg_size ([0-9]*).*/\1/p")
            local file_threads=$(cat $f | sed -n -E "s/.*threads ([0-9]*).*/\1/p")
            local file_msg_handlers=$(cat $f | sed -n -E "s/.*msg_handlers ([0-9]*).*/\1/p")

            # check if entry exists
            local exists=""
            for i in $(seq 0 $list_count); do
                if [ "{list[$i]}" = "${file_workload}_${file_nodes}_${file_msg_size}_*_${file_msg_handlers}" ]; then
                    exists="1"
                    break
                fi
            done

            if [ ! "$exists" ]; then
                list[$list_count]="${file_workload}_${file_nodes}_${file_msg_size}_*_${file_msg_handlers}"
                out_table_header[$list_count]="#workload ${file_workload}, nodes ${file_nodes}, msg_size ${file_msg_size}, msg_handlers ${file_msg_handlers}"
                list_count=$((list_count + 1))
            fi
        fi
    done

    # Now, for each combination we found, grab the benchmark outputs with varying msg sizes and create the tables
    for i in $(seq 0 $((list_count - 1))); do
        local out_file="${out_table_path}/dxnet_bench_nodes_${list[$i]}.csv"

        echo "Parsing for threads table dxnet_bench_nodes_${list[$i]}..."

        # replace * with x for filename
        out_file=$(echo "$out_file" | sed -e 's/\*/x/')

        local max_count="0"
        local data=()

        # Iterate all files matching the pattern
        for file in ${table_path}/dxnet_bench_${list[$i]}.csv; do
            local file_threads=$(cat $file | sed -n -E "s/.*threads ([0-9]*).*/\1/p")

            if [ "$file_threads" -gt "$max_count" ]; then
                max_count="$file_threads"
            fi

            local avg=$(cat $file | sed -n -E "s/avg;(.*)/\1/p")
            local min=$(cat $file | sed -n -E "s/min;(.*)/\1/p")
            local max=$(cat $file | sed -n -E "s/max;(.*)/\1/p")

            data[${file_threads}]="${file_threads};${avg};${min};${max}"
        done

        # Table header
        echo "${out_table_header[$i]}" > "$out_file"
        echo "#threads;" \
            "avg_send_runtime_ms;avg_send_time_per_msg_ns;avg_send_throughput_mb_sec;avg_send_throughput_overhead_mb_sec;avg_recv_runtime_ms;avg_recv_time_per_msg_ns;avg_recv_throughput_mb_sec;avg_recv_throughput_overhead_mb_sec;" \
            "min_send_runtime_ms;min_send_time_per_msg_ns;min_send_throughput_mb_sec;min_send_throughput_overhead_mb_sec;min_recv_runtime_ms;min_recv_time_per_msg_ns;min_recv_throughput_mb_sec;min_recv_throughput_overhead_mb_sec;" \
            "max_send_runtime_ms;max_send_time_per_msg_ns;max_send_throughput_mb_sec;max_send_throughput_overhead_mb_sec;max_recv_runtime_ms;max_recv_time_per_msg_ns;max_recv_throughput_mb_sec;max_recv_throughput_overhead_mb_sec" >> "$out_file"

        # Output data with increasing node count
        for j in $(seq 0 $max_count); do
            if [ "${data[${j}]}" ]; then
                echo "${data[${j}]}" >> "$out_file"
            fi
        done
    done 
}

# Plot a single benchmark results with avg, min, max and results of every single node
plot_single_benchmark()
{
    local in_table=$1
    local out_dir=$2

    local file="$(basename $in_table)"
    local filename="${file%.csv}"

    mkdir -p "${out_dir}/gp"

    local plot_script="${out_dir}/gp/${filename}.gp"

    # Generate gnuplot script
	echo "set terminal pdf" > ${plot_script}
	echo "set output \"${out_dir}/${filename}.pdf\"" >> ${plot_script}

	echo "set xlabel 'Node ID'" >> ${plot_script}
	echo "set ylabel 'Throughput MB/sec'" >> ${plot_script}

	echo "set key horiz" >> ${plot_script}
	echo "set key right top" >> ${plot_script}

    echo "set style data histogram" >> ${plot_script}
    echo "set style histogram cluster gap 1" >> ${plot_script}

    echo "set style line 1 lt 1 lc rgb '#696969'" >> ${plot_script}
	echo "set style line 2 lt 2 lc rgb '#9ACD32'" >> ${plot_script}
	echo "set style line 3 lt 3 lc rgb '#1E90FF'" >> ${plot_script}
	echo "set style line 4 lt 4 lc rgb '#A52A2A'" >> ${plot_script}

	# Set thousands separator. Depends on locale settings
	echo "set decimal locale" >> ${plot_script}
	echo "set format y \"%'g\"" >> ${plot_script}

    echo "set datafile separator \";\"" >> ${plot_script}

    echo "set style fill solid" >> ${plot_script}
    echo "set boxwidth 0.5" >> ${plot_script}

	echo "plot \\" >> ${plot_script}

    echo "\"${in_table}\" using 4:xtic(1) title \"Send payload\" ls 1, \\" >> ${plot_script}
    echo "\"${in_table}\" using 5:xtic(1) title \"Send full message\" ls 2, \\" >> ${plot_script}
    echo "\"${in_table}\" using 8:xtic(1) title \"Recv payload\" ls 3, \\" >> ${plot_script}
    echo "\"${in_table}\" using 9:xtic(1) title \"Recv full message\" ls 4, \\" >> ${plot_script}

	# Execute plot
	gnuplot ${plot_script}
}

# Plot a single benchmark progress with rx, tx, rxo and txo
plot_single_benchmark_progress()
{
    local in_table=$1
    local out_dir=$2

    local file="$(basename $in_table)"
    local filename="${file%.csv}"

    mkdir -p "${out_dir}/gp"

    local plot_script="${out_dir}/gp/${filename}.gp"

    # Generate gnuplot script
	echo "set terminal pdf" > ${plot_script}
	echo "set output \"${out_dir}/${filename}.pdf\"" >> ${plot_script}

	echo "set xlabel 'Time (sec)'" >> ${plot_script}
	echo "set ylabel 'Throughput (MB)'" >> ${plot_script}

	echo "set key horiz" >> ${plot_script}
	echo "set key right top" >> ${plot_script}

    echo "set style line 1 lt 1 lc rgb '#696969'" >> ${plot_script}
	echo "set style line 2 lt 2 lc rgb '#9ACD32'" >> ${plot_script}
	echo "set style line 3 lt 3 lc rgb '#1E90FF'" >> ${plot_script}
	echo "set style line 4 lt 4 lc rgb '#A52A2A'" >> ${plot_script}

	# Set thousands separator. Depends on locale settings
	echo "set decimal locale" >> ${plot_script}
	echo "set format y \"%'g\"" >> ${plot_script}

    echo "set datafile separator \";\"" >> ${plot_script}

	echo "plot \\" >> ${plot_script}

    echo "\"${in_table}\" using 1:2 with lines title \"Send payload\" ls 1, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:3 with lines title \"Send full message\" ls 2, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:4 with lines title \"Recv payload\" ls 3, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:5 with lines title \"Recv full message\" ls 4, \\" >> ${plot_script}

	# Execute plot
	gnuplot ${plot_script}
}

plot_increasing_node_count()
{
    local in_table=$1
    local out_dir=$2

    local file="$(basename $in_table)"
    local filename="${file%.csv}"

    mkdir -p "${out_dir}/gp"

    local plot_script="${out_dir}/gp/${filename}.gp"

    # Generate gnuplot script
	echo "set terminal pdf" > ${plot_script}
	echo "set output \"${out_dir}/${filename}.pdf\"" >> ${plot_script}

    # Full decimal steps in x
    echo "set xtics 1" >> ${plot_script}

    # Create stats on node count column to get the min and max
    # Use these values to add some space before the first value in x
    # and after the last value in x
    echo "stats \"${in_table}\" using 1:1 nooutput" >> ${plot_script}
    echo "set xrange [STATS_min_x - 0.5:STATS_max_x + 0.5]" >> ${plot_script}

	echo "set xlabel 'Node count'" >> ${plot_script}
	echo "set ylabel 'Throughput MB/sec'" >> ${plot_script}

	echo "set key horiz" >> ${plot_script}
	echo "set key right top" >> ${plot_script}

    echo "set style line 1 lt 1 lc rgb '#696969'" >> ${plot_script}
	echo "set style line 2 lt 2 lc rgb '#9ACD32'" >> ${plot_script}
	echo "set style line 3 lt 3 lc rgb '#1E90FF'" >> ${plot_script}
	echo "set style line 4 lt 4 lc rgb '#A52A2A'" >> ${plot_script}

	# Set thousands separator. Depends on locale settings
	echo "set decimal locale" >> ${plot_script}
	echo "set format y \"%'g\"" >> ${plot_script}

    echo "set datafile separator \";\"" >> ${plot_script}

	echo "plot \\" >> ${plot_script}

    echo "\"${in_table}\" using 1:4 with lines notitle ls 1, \\" >> ${plot_script}
    echo "\"\" using 1:4:12:20 with yerrorbars title \"Avg. send payload\" ls 1, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:5 with lines notitle ls 2, \\" >> ${plot_script}
    echo "\"\" using 1:5:13:21 with yerrorbars title \"Avg. send payload + overhead\" ls 2, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:8 with lines notitle ls 3, \\" >> ${plot_script}
    echo "\"\" using 1:8:16:24 with yerrorbars title \"Avg. recv payload\" ls 3, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:9 with lines notitle ls 4, \\" >> ${plot_script}
    echo "\"\" using 1:9:17:24 with yerrorbars title \"Avg. recv payload + overhead\" ls 4" >> ${plot_script}

	# Execute plot
	gnuplot ${plot_script}
}

# Use multiple tables and plots the avg, min and max with increasing node count, msg size or thread count (x axis)
plot_increasing_msg_size_or_thread_count()
{
    local in_table=$1
    local out_dir=$2
    local x_axis_title=$3

    local file="$(basename $in_table)"
    local filename="${file%.csv}"

    mkdir -p "${out_dir}/gp"

    local plot_script="${out_dir}/gp/${filename}.gp"

    # Generate gnuplot script
	echo "set terminal pdf" > ${plot_script}
	echo "set output \"${out_dir}/${filename}.pdf\"" >> ${plot_script}

    echo "set logscale x 2" >> ${plot_script}

	echo "set xlabel \"${x_axis_title}\"" >> ${plot_script}
	echo "set ylabel 'Throughput MB/sec'" >> ${plot_script}

	echo "set key horiz" >> ${plot_script}
	echo "set key right top" >> ${plot_script}

    echo "set style line 1 lt 1 lc rgb '#696969'" >> ${plot_script}
	echo "set style line 2 lt 2 lc rgb '#9ACD32'" >> ${plot_script}
	echo "set style line 3 lt 3 lc rgb '#1E90FF'" >> ${plot_script}
	echo "set style line 4 lt 4 lc rgb '#A52A2A'" >> ${plot_script}

	# Set thousands separator. Depends on locale settings
	echo "set decimal locale" >> ${plot_script}
	echo "set format y \"%'g\"" >> ${plot_script}

    echo "set datafile separator \";\"" >> ${plot_script}

	echo "plot \\" >> ${plot_script}

    echo "\"${in_table}\" using 1:4 with lines notitle ls 1, \\" >> ${plot_script}
    echo "\"\" using 1:4:12:20 with yerrorbars title \"Avg. send payload\" ls 1, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:5 with lines notitle ls 2, \\" >> ${plot_script}
    echo "\"\" using 1:5:13:21 with yerrorbars title \"Avg. send payload + overhead\" ls 2, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:8 with lines notitle ls 3, \\" >> ${plot_script}
    echo "\"\" using 1:8:16:24 with yerrorbars title \"Avg. recv payload\" ls 3, \\" >> ${plot_script}
    echo "\"${in_table}\" using 1:9 with lines notitle ls 4, \\" >> ${plot_script}
    echo "\"\" using 1:9:17:24 with yerrorbars title \"Avg. recv payload + overhead\" ls 4" >> ${plot_script}

	# Execute plot
	gnuplot ${plot_script}
}

###############
# Entry point #
###############

if [ "$#" -lt "2" ]; then
    echo "Provided a folder of archived results, this generates csv files and plots of the results using dxnet's logfiles"
    echo "Usage: <directory with archived (.tar.gz) benchmark results> <output dir>"
    exit 1
fi

result_archives_path="$(realpath $1)"
out_path="$(realpath $2)"

if [ -e "$out_path" ]; then
    rm -r $out_path
fi

unpacked_path="${out_path}/unpacked"

# First, unpack all archives
unpack_logfiles $result_archives_path $unpacked_path

table_path="${out_path}/tables"

# Iterate unpacked folders and create one table for each folder
for f in ${unpacked_path}/*; do
    create_csv_single_benchmark $f ${table_path}/single
    create_csv_single_benchmark_progress $f ${table_path}/single_progress
done

# Use the single benchmark results to create further tables

# Progress of all nodes on one benchmark
create_csvs_nodes_benchmark_progress ${table_path}/single_progress ${table_path}/nodes_progress

# With increasing node count
create_csvs_increasing_node_counts ${table_path}/single ${table_path}/node_count

# With increasing msg size
create_csvs_increasing_msg_size ${table_path}/single ${table_path}/msg_size

# With increasing (send) threads
create_csvs_increasing_thread_count ${table_path}/single ${table_path}/threads

# Remove unpacked logs
rm -r $unpacked_path

# Plotting is next
plot_path="${out_path}/plot"

mkdir -p $plot_path

# Results of single benchmark
for f in ${table_path}/single/*; do
    plot_single_benchmark $f ${plot_path}/single
done

# Progress of single benchmark
for f in ${table_path}/single_progress/*; do
    plot_single_benchmark_progress $f ${plot_path}/single_progress
done

# Node counts
for f in ${table_path}/node_count/*; do
    plot_increasing_node_count $f ${plot_path}/node_count
done

# Msg sizes
for f in ${table_path}/msg_size/*; do
    plot_increasing_msg_size_or_thread_count $f ${plot_path}/msg_size "Msg size (bytes)"
done

# Threads
for f in ${table_path}/threads/*; do
    plot_increasing_msg_size_or_thread_count $f ${plot_path}/threads "(Send) threads"
done