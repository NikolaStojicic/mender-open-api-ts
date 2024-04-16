#!/bin/bash
# Please invoke from fetch-client/docs (current dir)

current_dir=$(pwd)
parent_dir=$(dirname $current_dir)

links=(
    "https://raw.githubusercontent.com/mendersoftware/deployments/master/docs/devices_api.yml"
    "https://raw.githubusercontent.com/mendersoftware/deployments/master/docs/internal_api.yml"
    "https://raw.githubusercontent.com/mendersoftware/deployments/master/docs/management_api.yml"
    "https://raw.githubusercontent.com/mendersoftware/deployments/master/docs/management_api_v2.yml"
    "https://raw.githubusercontent.com/mendersoftware/inventory/master/docs/devices_api.yml"
    "https://raw.githubusercontent.com/mendersoftware/inventory/master/docs/internal_api.yml"
    "https://raw.githubusercontent.com/mendersoftware/inventory/master/docs/internal_api_v2.yml"
    "https://raw.githubusercontent.com/mendersoftware/inventory/master/docs/management_api.yml"
    "https://raw.githubusercontent.com/mendersoftware/inventory/master/docs/management_api_v2.yml"

)

index_file="$parent_dir/index.ts"

rm $index_file
touch $index_file

echo "import { createClient } from './create';" >> $index_file

declare -a ts_paths

for url in "${links[@]}"; do
    path=${url#"https://raw.githubusercontent.com/mendersoftware/"}
    repo=$(echo $path | cut -d'/' -f1)
    file=$(echo $path | cut -d'/' -f4)
    path="$repo/$file"
    mkdir -p $(dirname "$path")
    mkdir -p "$current_dir/generated"
    mkdir -p "$current_dir/generated/$repo"
    curl -Ls $url > $path

    full_path="$current_dir/$path"
    full_output_path="$current_dir/generated/$repo/$(basename $path .yml).ts"

    npx openapi-typescript@5 $full_path --output $full_output_path

    ts_path=${repo}_$(basename $path .yml)
    echo "import { paths as $ts_path } from './docs/generated/$repo/$(basename $path .yml)';" >> $index_file
    ts_paths+=("$ts_path")
done

echo "" >> $index_file
echo "export const mender = {" >> $index_file

for ts_path in "${ts_paths[@]}"; do
    repo=$(echo $ts_path | cut -d'_' -f1)
    file=${ts_path#"${repo}_"}
    needle="/*$repo-needle*/"

    if [[ $ts_path =~ "v2" ]]; then
        api="'/v2/$repo'"
    else
        api="'/v1/$repo'"
    fi

    replacement=$"$file: createClient<$ts_path>($api),\n    $needle"

    if fgrep -q "$needle" $index_file; then
        needle_escaped=$(printf '%s\n' "$needle" | sed 's:[][\/.^$*]:\\&:g')
        sed -i "" "s|$needle_escaped|$replacement|g" $index_file
    else
        echo "  $repo: {" >> $index_file
        echo "    $file: createClient<$ts_path>($api)," >> $index_file
        echo "    $needle" >> $index_file
        echo "  }," >> $index_file
    fi
    

done

echo "};" >> "$parent_dir/index.ts"