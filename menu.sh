#!/bin/bash

declare -i userid=0

user_add () {
  read -p "Please enter an email address:" email
	read -p "What will your username be?" username
	read -p "Enter your password:" password
	result=$(psql -t -d postgres -c "insert into users values (default, '$username', '$password', '$email');")
	echo "$result"
}

user_login () {
  read -p "Enter username: " username
	read -p "Enter password: " password
	result=$(psql -t -d postgres -c "select id from users where username = '$username'")
	if test -z "$result"
	then
		echo "No users found with that information."
	else
		userid="$result"
		echo "Your UserID has been assigned to $userid."
	fi
	if [[ $userid != 0 ]]; then
		show_user_menu
	fi
}

vehicle_add () {
  read -p "Enter the make of your vehicle: " make
	read -p "Enter your vehicle's model name: " model
	read -p "Enter your $make $model's year of manufacture: " year
	result=$(psql -t -d postgres -c "select (select id from makes where name = '$make'), (select id from models where name = '$model') from makemodel where make = '$make' and model = '$model'")
	echo $result
	if test -z "$result"
	then
		echo "Error - $make $model is not in the system."
	else
		result=$(psql -d postgres -c "insert into vehicles values (default, $userid, (select id from models where name = '$model'), default, default, default, default, default, default, default, $year)")
		echo "Successfully added a $year $make $model to your vehicles."
	fi
}

get_vehicle_info () {
  result=""
  IFS='-'
  read -ra data <<< "$1"
  {
  for (( i=1; i < $2+1; i++ ))
	do
	  declare -i modelid=0
		declare -i year=0
		declare -i vehicleid=0
		if [[ i -gt 1 ]]; then
			v_idx=$((i*3-3))
			y_idx=$((i*3-2))
			id_idx=$((i*3-1))
		else
			v_idx=$((i-1))
			y_idx=$((i))
			id_idx=$((i+1))
		fi
		modelid=${data[id_idx]}
		vehicleid=${data[v_idx]}
		year=${data[y_idx]}
		res=$(psql -t -d postgres -c "select (select name from makes where id = makeid), name, (select username from users where id = (select ownerid from vehicles where id = $vehicleid)) from models where id = $modelid" | sed 's/|//g' | tr -s ' ')
		result+="$year $res\n"
	done
	printf "$result"
	}
}

vehicle_search () {
  declare -i count=0
	read -p "What make would you like to search for? (Tip: enter 'any' for all makes) " make
	read -p "What model would you like to search for? (Tip: enter 'any' for all models from a certain make)" model
  if [[ $make == "any" ]] || [[ $model == "any" ]]
  then
    if [[ $make == "any" ]]
    then
      count=$(psql -t -d postgres -c "select count(*) from vehicles where modelid = (select id from models where name = '$model')")
      result=$(psql -t -d postgres -c "select id, year, modelid from vehicles where modelid = (select id from models where name = '$model')")
    fi
    if [[ $model == "any" ]]
    then
      count=$(psql -t -d postgres -c "select count(*) from vehicles where make_from_modelid(vehicles.modelid) = '$make'")
      result=$(psql -t -d postgres -c "select id, year, modelid from vehicles where make_from_modelid(vehicles.modelid) = '$make'")
    fi
  elif [[ $make == "any" ]] && [[ $model == "any" ]]
  then
    count=$(psql -t -d postgres -c "select count(*) from vehicles")
    result=$(psql -t -d postgres -c "select id, year, modelid from vehicles")
  else
    count=$(psql -t -d postgres -c "select count(*) from vehicles where makeid = (select id from makes where name = '$make') and modelid = (select id from models where name = '$model')")
	  result=$(psql -t -d postgres -c "select id, year, modelid from vehicles where makeid = (select id from makes where name = '$make') and modelid = (select id from models where name = '$model')")
	fi
	result=$(echo $result | sed 's/|//g' | tr -s ' ' | tr -d '\n' | sed 's/ /-/g')
	echo $(get_vehicle_info $result $count)
}

show_user_menu () {
	username=`psql -t -d postgres -c "select username from users where id = $userid"`
	PS3="Welcome, $username. Please make a selection: "
	select option in "Add Vehicle" "Your Vehicles" Search "Log Out (Main Menu)" Exit
	do
		case $option in
			"Add Vehicle")
        vehicle_add
				;;
			"Your Vehicles")
				result=$(psql -t -d postgres -c "select id, year, modelid from vehicles where ownerid = $userid")
	      count=$(psql -t -d postgres -c "select count(*) from vehicles where ownerid = $userid")
	      result=$(echo $result | sed 's/|//g' | tr -s ' ' | tr -d '\n')
        get_vehicle_info $result $count
				;;
			Search)
			  vehicle_search
				;;
			"Log Out (Main Menu)")
				userid=0
				show_main_menu
				;;
			Exit)
				exit 0
				;;
		esac
	done
}

show_main_menu () {
	PS3="Please make a selection: "
	select option in Login "New User" Exit
	do
		case $option in
			Login)
        user_login
				;;
			"New User")
        user_add
				;;
			Exit)
				exit 0
		esac
	done
}


show_main_menu