function fish_greeting -d "Greeting message on shell session start up"
  set_color $fish_color_autosuggestion[1]
  echo -en (show_date_info) "\n"
  echo -en "\n"
  echo -en "Current Machine:\n"
  echo -en (show_os_info) "\n"
  echo -en (show_cpu_info) "\n"
  echo -en (show_mem_info) "\n"
  echo -en (show_net_info) "\n"
  echo ""
  set_color normal
end


function welcome_message -d "Say welcome to user"
  echo (python -c "import requests,json;print(requests.get('http://www.yerkee.com/api/fortune/wisdom').json()['fortune'])")
  set_color normal
end


function show_date_info -d "Prints information about date"

  set --local up_time (uptime | cut -d "," -f1 | cut -d "p" -f2 | sed 's/^ *//g')

  set --local time (echo $up_time | cut -d " " -f2)
  set --local formatted_uptime $time

  switch $time
  case "days"
  case "day"
    set formatted_uptime "$up_time"
  case "min"
    set formatted_uptime $up_time"utes"
  case '*'
    set formatted_uptime "$formatted_uptime hours"
  end

  set_color normal
  echo -en "Today is the "
  set_color cyan
  echo -en (date "+%F")
  set_color normal
  echo -en ", we are up and running for "
  set_color cyan
  echo -en "$formatted_uptime"
  set_color normal
  echo -en "."
end


function show_os_info -d "Prints operating system info"

  set_color yellow
  echo -en "OS:  "
  set_color 0F0  # green
  echo -en (lsb_release -d | cut -f2)
  set_color normal
end


function show_cpu_info -d "Prints iformation about cpu"

  set --local os_type (uname -s)
  set --local cpu_info ""

  if [ "$os_type" = "Linux" ]

    set --local procs_n (grep -c "^processor" /proc/cpuinfo)
    set --local cores_n (grep "cpu cores" /proc/cpuinfo | head -1 | cut -d ":"  -f2 | tr -d " ")
    set --local cpu_type (grep "model name" /proc/cpuinfo | head -1 | cut -d ":" -f2)
    set cpu_info "$procs_n processors, $cores_n cores, $cpu_type"

  else if [ "$os_type" = "Darwin" ]

    set --local procs_n (system_profiler SPHardwareDataType | grep "Number of Processors" | cut -d ":" -f2 | tr -d " ")
    set --local cores_n (system_profiler SPHardwareDataType | grep "Cores" | cut -d ":" -f2 | tr -d " ")
    set --local cpu_type (system_profiler SPHardwareDataType | grep "Processor Name" | cut -d ":" -f2 | tr -d " ")
    set cpu_info "$procs_n processors, $cores_n cores, $cpu_type"
  end

  set_color yellow
  echo -en "CPU: "
  set_color 0F0  # green
  echo -en $cpu_info
  set_color normal
end


function show_mem_info -d "Prints memory information"

  set --local os_type (uname -s)
  set --local total_memory ""

  if [ "$os_type" = "Linux" ]
    set total_memory (free -h | grep "Mem" | cut -d " " -f 12)

  else if [ "$os_type" = "Darwin" ]
    set total_memory (system_profiler SPHardwareDataType | grep "Memory:" | cut -d ":" -f 2 | tr -d " ")
  end

  set_color yellow
  echo -en "Mem: "
  set_color 0F0  # green
  echo -en $total_memory
  set_color normal
end


function show_net_info -d "Prints information about network"

  set --local os_type (uname -s)
  set --local ip ""
  set --local gw ""

  if [ "$os_type" = "Linux" ]
    set ip (ip address show | grep -E "inet .* global" | xargs | cut -d " " -f2)
    set gw (ip route | grep default | cut -d " " -f3)

  else if [ "$os_type" = "Darwin" ]
    set ip (ifconfig | grep -v "127.0.0.1" | grep "inet " | head -1 | cut -d " " -f2)
    set gw (netstat -nr | grep -E "default.*UGSc" | cut -d " " -f13)
  end

  set_color yellow
  echo -en "Net: "
  set_color 0F0  # green
  echo -en "IPv4 $ip; Gateway $gw"
  set_color normal
end
