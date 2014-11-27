#!/bin/bash
nagios_srv="XXXXXX"
nagios_port="XXXXXX"
send_nsca_cmd=/usr/sbin/send_nsca
rsync_cmd=/usr/bin/rsync
send_nsca_conf=/etc/send_nsca.cfg
#set the InteralFileSeparator to newline, needed for formating rsyncs output
IFS='
'
rsyncout[0]=""
arg_counter=0
usage="Usage:
    -s SOURCE-DIRECTORY\n
    -y DELETE\n
    -d SOURCE-DIRECTORY\n
    -e EXCLUDE-FROM-FILE\n
    -p PORT\n
    -h HOSTNAME\n
    -s NAGIOS-SERVICE-NAME\n
    -i show this message\n
    -? show this message"

#get the commandline-arguments    
while getopts "s:d:c:h:i:e:p:y:" options; do
  case $options in
    s ) src_dir=$OPTARG
        ((arg_counter+=1));;
    d ) dst_dir=$OPTARG
        ((arg_counter+=1));;
    y ) delete=$OPTARG
        ((arg_counter+=1));;        
    p ) port=$OPTARG
        ((arg_counter+=1));;        
    e ) exclude_file=$OPTARG
        (());;
    h ) hostname=$OPTARG
        ((arg_counter+=1));;
    c ) service_check=$OPTARG
        ((arg_counter+=1));;
    i ) echo -e $usage
        exit 0;;
   \? ) echo -e $usage
        exit 1;;
  esac
done


#All arguments supplied?
if [ $arg_counter -lt 4 ];then
    echo "Not enough arguments supplied"
    echo -e $usage
    exit 1
fi

if [[ -n $exclude_file ]];then
exclude_file="--exclude-from=$exclude_file"
fi

if [[ -n $delete ]];then
delete="--del"
fi

#The actual rsync-command
$rsync_cmd $exclude_file $delete -avze 'ssh -p '$port' -i /root/.ssh/id_rsa' $src_dir $dst_dir &> /tmp/rsync_tmp.log

#Nagios only knows exit-status 0,1,2 so wegot to capture and convert all others
case $? in
    0) exitcode=$? ;;
    1) exitcode=$? ;;
    2) exitcode=$? ;;
    *) exitcode=2
esac

#Read the output of the rsync-job line for line into an array
while read line; do
rsyncout=("${rsyncout[@]}" $line)
done < "/tmp/rsync_tmp.log"

#count the lines of rsyncs output
counter=${#rsyncout[@]}

#write only the last two lines of the output to $output
output="${rsyncout[$counter - 2]} ${rsyncout[$counter - 1]}"

#Send the result to the nagios-server
echo "$hostname;$service_check;$exitcode;$output" | $send_nsca_cmd -H $nagios_srv -p $nagios_port -d ';' -c $send_nsca_conf
