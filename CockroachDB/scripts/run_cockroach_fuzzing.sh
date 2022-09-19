#!/bin/bash -e

if [ "$1" == "SQLRight" ]; then

    cd "$(dirname "$0")"/.. 
    
    if [ ! -d "./Results" ]; then
        mkdir -p Results
    fi

    resoutdir="sqlright_cockroach"

    for var in "$@"
    do
        if [ "$var" == "NOREC" ]; then
            resoutdir="$resoutdir""_NOREC"
        elif [ "$var" == "TLP" ]; then
            resoutdir="$resoutdir""_TLP"
        elif [ "$var" == "OPT" ]; then
            resoutdir="$resoutdir""_OPT"
        fi
    done

    bugoutdir="$resoutdir""_bugs"
    
    cd Results
    
    if [ -d "./$resoutdir" ]; then
        echo "Detected Results/$resoutdir folder existed. Please cleanup the output folder and then retry. "
        exit 5
    fi
    if [ -d "./$bugoutdir" ]; then
        echo "Detected Results/$bugoutdir folder existed. Please cleanup the output folder and then retry. "
        exit 5
    fi
    
    sudo docker run -i --rm \
        -v $(pwd)/$resoutdir:/home/cockroach/fuzzing/fuzz_root/outputs \
        -v $(pwd)/$bugoutdir:/home/cockroach/fuzzing/Bug_Analysis \
        --name $resoutdir \
        sqlright_cockroach /bin/bash /home/cockroach/scripts/run_sqlright_cockroach_fuzzing_helper.sh ${@:2}
    
else
    echo "Usage: bash run_cockroach_fuzzing.sh SQLRight --start-core <num> --num-concurrent <num> -O <oracle> "
fi
