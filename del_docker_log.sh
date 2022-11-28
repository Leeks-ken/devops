#!/bin/bash
# cront
# 0 1 * * * bash /opt/scripts/del_docker_log.sh >/dev/null 2>&1

LOG_FILE="/tmp/system_cron.log"

function log() {
  if [[ $# -eq 1 ]];then
    msg=$1
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[32m[INFO]\033[0m ${msg}" >> "${LOG_FILE}"
  elif [[ $# -eq 2 ]];then
    param=$1
    msg=$2
    if [[ ${param} = "-w" ]];then
      echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[34m[WARNING]\033[0m ${msg}" >> "${LOG_FILE}"
    elif [[ ${param} = "-e" ]];then
      echo -e "$(date +"%Y-%m-%d %H:%M:%S") \033[31m[ERROR]\033[0m ${msg}" >> "${LOG_FILE}"
      exit 1
    elif [[ ${param} = "-d" ]];then
      echo "$(date +"%Y-%m-%d %H:%M:%S") [DEBUG] ${msg}" >> "${LOG_FILE}"
      if [[ ${DEBUG_FLAG} = 1 ]];then
        set -x
      fi
    fi
  fi
}


clean_docker_log() {
  Docker_Root_Dir=$(docker info |grep "Docker Root Dir" | awk -F": " '{print $2}')
  Docker_Json_Log=$(find "${Docker_Root_Dir}"/containers/ -name "*-json.log")

  for FILE in ${Docker_Json_Log}; do
    log "true > ${FILE}"
    true > "${FILE}"
  done
}


function clear_aelf_log() {
  aelf_log_dir=/opt/aelf-node/Logs

  age15_date=$(date -d "15 days ago " +"%Y-%m-%d")
  ago15_timestamp=$(date -d "${age15_date}" +%s)

  today=$(date +"%Y-%m-%d")

  for file_name in $(ls ${aelf_log_dir})
  do
    file_date=$(echo "${file_name}" | awk -F"." '{print $1}')
    file_timestamp=$(date -d "${file_date}" +%s)

    if [ "${ago15_timestamp}" -gt "${file_timestamp}" ]; then
      log "rm ${aelf_log_dir}/${file_name}"
      rm "${aelf_log_dir}/${file_name}"
    fi

    gz_suffix=$(echo "${file_name}" | awk -F"." '{print $NF}')
    if [ "x${file_date}" != "x${today}" ] && [ "x${gz_suffix}" != "xgz" ]; then
      log "gzip ${aelf_log_dir}/${file_name}"
      gzip "${aelf_log_dir}/${file_name}"
    fi

  done
}

DOCKER_NUM=$(dpkg -l |grep  "^ii"|awk '{print $2}'|grep -c docker)

if [ "${DOCKER_NUM}" -ne 0 ]; then
  clean_docker_log

  if [ "$(docker inspect --format '{{.State.Running}}' aelf-node)" = "true" ]; then
    clear_aelf_log
  fi
fi
