#!/bin/bash

init_makes_models() {
  path='./data/makemodel.txt'
  models=()
  makes=()
  n=1
  while read line; do
    IFS=','
    read -ra data <<<"$line"
    current_model=${data[1]}
    current_make=${data[0]}
    if [[ ! "${makes[@]}" =~ "$current_make" ]]; then
      echo "begin;" >>init.sql
      echo "insert into makes values (default, '$current_make') on conflict do nothing;" >>init.sql
      echo "commit;" >>init.sql
      makes+=("$current_make")
    fi
    if [[ ! "${models[@]} " =~ "$current_model" ]]; then
      echo "begin;" >>init.sql
      echo "insert into models values (default, (select id from makes where name = '$current_make'), '$current_model') on conflict do nothing;" >>init.sql
      echo "commit;" >>init.sql
      models+=("$current_model")
      n=$((n + 1))
    fi
    echo "models added: $n"
  done <$path
}

init_engines() {
  path='./data/engines.txt'
  n=1
  echo "begin;" >>init.sql
  while read line; do
    IFS=','
    read -ra data <<<"$line"
    echo "insert into engines values (default, (select id from makes where name = '${data[0]}'), '${data[1]}', '${data[2]}', ${data[3]}, ${data[4]}, ${data[5]}, ${data[6]}, ${data[7]}, ${data[8]}, ${data[9]}) on conflict do nothing;" >>init.sql
    n=$((n + 1))
    echo "engines added: $n"
  done <$path
  echo "commit;" >>init.sql
}

init_transmissions() {
  path='./data/transmissions.txt'
  n=1
  echo "begin;" >>init.sql
  while read line; do
    IFS=','
    read -ra data <<<"$line"
    echo "insert into transmissions values (default, (select id from makes where name = '${data[0]}'), '${data[1]}', '${data[2]}', ${data[3]}, ${data[4]}, '${data[5]}') on conflict do nothing;" >>init.sql
    n=$((n + 1))
    echo "transmissions added: $n"
  done <$path
  echo "commit;" >>init.sql
}

init_makes_models
init_engines
init_transmissions
psql -d postgres -f init.sql
