#!/bin/bash

copy_data_from_docker() {
    copyBaseDir="/home/cockroach/fuzzing/fuzz_root/outputs/outputs_"
    copyBaseCommand="sudo docker cp ""$1"":""$copyBaseDir"

    isFinished=false
    outputIdx=0

    # Copy the plot_data file outside. 
    while [ "$isFinished" = false ]; do
        copyCommand="$copyBaseCommand$outputIdx""/plot_data ./plot_data_$outputIdx "
        echo "$copyCommand"
        sudo $copyCommand &> /dev/null && sudo chown -R luy70 ./plot_data_$outputIdx || true
        if [ ! -f "./plot_data_$outputIdx" ]; then
            echo "Finished copying plot_data"
            isFinished=true
        fi
        ((outputIdx=outputIdx+1))
    done 

    # Also copy the bug_samples folder out. 
    copyBaseDir="/home/cockroach/fuzzing/Bug_Analysis/bug_samples"
    copyCommand="sudo docker cp ""$1"":""$copyBaseDir"" ./"
    echo "$copyCommand"
    sudo $copyCommand &> /dev/null && sudo chown -R luy70 ./bug_samples || true
    echo "Finished copying bug_samples"
    echo "Finished with $1"
    echo ""

    # Done
}

run_index=0

while [ -d "./run_""$run_index" ]; do
    ((run_index=run_index+1))
done

# create the folder. Go into it. 
mkdir -p "./run_"$run_index
cd "./run_"$run_index

# create the with_rsg and without_rsg folder
mkdir -p with_rsg
mkdir -p without_rsg
mkdir -p without_dyn_fix

# copy the with_rsg
cd with_rsg
copy_data_from_docker "sqlright_testing"

# copy the without_rsg
cd ../without_rsg
copy_data_from_docker "sqlright_testing_no_rsg"

# copy the without_rsg
cd ../without_dyn_fix
copy_data_from_docker "sqlright_testing_no_dyn"

# plot the data
cd ../
cp ../plot_map_size.py ./
cp ../plot_validity.py ./
cp ../plot_bug_num.py ./

python3 plot_map_size.py
python3 plot_validity.py
python3 plot_bug_num.py

cd ../
echo "Beginning Zipping the files. "
zip -r ./run_$run_index.zip ./run_$run_index &> /dev/null
echo " "
echo " "
echo " "
realpath ./run_$run_index.zip
