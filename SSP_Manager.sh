#!/bin/bash

sci_name='suppressMessages(if (!require(taxize)) install.packages("taxize"))
suppressMessages(output <- sci2comm(scinames="INPUT", db = "eol"))
if(length(output[[1]]) == 0){
  output <- "NA"
} else {
  output <- output[[1]]
}
cat(output)'

input_tester() {
  w1=${1}
  w2=${2}

  alphabet="abcdefghijklmnopqrstuvwxyz"

  export exe="NO"
  i=1
  while [[ "${i}" -le 26 ]]; do
    Letter=$(echo "${alphabet}" | cut -c "${i}")
    L1=$(echo "${w1}" | grep -oi "${Letter}" | wc -l)
    L2=$(echo "${w2}" | grep -oi "${Letter}" | wc -l)
    if [[ "${L1}" != "${L2}" ]]; then
      export exe="OK"
      break 1
    fi
    ((i++))
  done
}

format_print() {
  n_i=$(cat ${1}/${2} | grep -wn "Eng>" | cut -d ':' -f 1)
  name=$(cat ${1}/${2} | sed -n "1,${n_i}p")

  s_i=$(($(cat ${1}/${2} | grep -wn ">Sample" | cut -d ':' -f 1) + 1))
  s_j=$(($(cat ${1}/${2} | grep -wn ">Plan" | cut -d ':' -f 1) - 2))
  if [[ "${s_i}" -gt 0 ]] && [[ "${s_j}" -gt 0 ]]; then
    sample=$(cat ${1}/${2} | sed -n "${s_i},${s_j}p")
  fi

  p_i=$(($(cat ${1}/${2} | grep -wn ">Plan" | cut -d ':' -f 1) + 1))
  p_j=$(($(cat ${1}/${2} | grep -wn ">Progress" | cut -d ':' -f 1) - 2))
  if [[ "${p_i}" -gt 0 ]] && [[ "${p_j}" -gt 0 ]]; then
    plan=$(cat ${1}/${2} | sed -n "${p_i},${p_j}p")
  fi

  pr_i=$(($(cat ${1}/${2} | grep -wn ">Progress" | cut -d ':' -f 1) + 1))
  pr_j=$(($(cat ${1}/${2} | grep -wn ">Comment" | cut -d ':' -f 1) - 2))
  if [[ "${pr_i}" -gt 0 ]] && [[ "${pr_j}" -gt 0 ]]; then
    progress=$(cat ${1}/${2} | sed -n "${pr_i},${pr_j}p")
  fi

  c_i=$(cat ${1}/${2} | grep -wn ">Comment" | cut -d ':' -f 1)
  c_j=$(cat ${1}/${2} | wc -l)
  if [[ "${c_i}" -gt 0 ]] && [[ "${c_j}" -gt 0 ]]; then
    comment=$(cat ${1}/${2} | sed -n "${c_i},${c_j}p")
  fi

  if [[ "${sample}" ]] && [[ "${plan}" ]] && [[ "${progress}" ]]; then
    sample=$(echo "${sample}" | awk 'BEGIN{FS="\t"}; {printf "%-10s %-10s %-10s %-10s %-15s %-10s %-10s\n", $1, $2, $3, $4, $5, $6, $7}')
    plan=$(echo "${plan}" | awk 'BEGIN{FS="\t"}; {printf "%-10s %-10s\n", $1, $2}')
    progress=$(echo "${progress}" | awk 'BEGIN{FS="\t"}; {printf "%-20s %-10s %-15s\n", $1, $2, $3}')

    echo -e "${name}\n----------\n>Sample\n${sample}\n----------\n>Plan\n${plan}\n----------\n>Progress\n${progress}\n----------\n${comment}"
  else
    echo -e "***Message: Something wrong in the file ${2}.\n"
  fi
}
export -f format_print

search() {
  species=$(echo "${2}" | cut -d "." -f 1)
  if [[ ! -e "${1}/${2}" ]] && [[ -z "$(grep -wr "${species}" ${1})" ]]; then
    echo -e "***Feedback: ${2} doesn't exist."
  else
    echo -e "***Feedback: ${2} exist."
    read -p "Look into the file?(Y/n) " choice

    if [[ "$(grep -wr "${species}" ${1})" ]]; then
      file=$(basename $(grep -wr "${species}" ${1} | sed -n "1p" | cut -d ':' -f 1))
    else
      file=${2}
    fi

    if [[ -z "${choice}" ]]; then
      choice="n"
    fi

    if [[ "${choice}" == "y" ]] || [[ "${choice}" == "yes" ]] || [[ "${choice}" == "Y" ]] || [[ "${choice}" == "Yes" ]]; then
      echo -e "\n\nProfile name: ${file}\n=================================="
      format_print ${1} ${file}
      echo -e "==================================\n"
    fi
  fi
}

check() {
  species=$(echo "${2}" | cut -d "." -f 1)
  if [[ ! -e "${1}/${2}" ]] && [[ -z "$(grep -wr "${species}" ${1})" ]]; then
    echo -e "***Feedback: ${2} doesn't exist."
  else
    echo -e "***Feedback: ${2} exist."

    if [[ "$(grep -wr "${species}" ${1})" ]]; then
      file=$(basename $(grep -wr "${species}" ${1} | sed -n "1p" | cut -d ':' -f 1))
    else
      file=${2}
    fi

    echo -e "\n\nFile name: ${file}\n=================================="
    format_print ${1} ${file}
    echo -e "==================================\n"
  fi
}

create() {
  species=$(echo "${2}" | cut -d "." -f 1)
  if [[ ! -e ${1}/${2} ]] && [[ -z "$(grep -wr "${species}" ${1})" ]]; then
    
    c_io=0
    control=0
    while [[ "${c_io}" -lt 1 ]] && [[ "${control}" -le 2 ]]; do
      if [[ "${species}" ]]; then
        species=$(echo "${species}" | tr '_' ' ')
        sci_name_run=$(echo "${sci_name}" | sed "s/INPUT/${species}/")
        sciname=$(Rscript <(echo "${sci_name_run}"))
        if [[ "${sciname}" != "NA" ]]; then
          species=$(echo "${species}" | tr ' ' '_')
          echo "${Template}" | sed "s/Sci_NA/${species}/" >${1}/${species}.profile
          echo -e "***Feedback: ${species}.profile is created."
          ((c_io++))
        else
          read -p "***Requirement: Input the scientific name: " species
        fi
      else
        read -p "***Requirement: Specify the scientific name: " species
      fi
      ((control++))
    done

    if [[ "${control}" -ge 3 ]]; then
      echo "${Template}" | sed "s/Eng_NA/${2}/" >${1}/${2}
      echo echo -e "***Feedback: ${species} cannot be found in EOL database, but ${2} is still created."
    fi
  else
    echo -e "***Message:Profile exists!"
  fi
}

edit() {
  if [[ "${3}" == "Sample" ]] || [[ "${3}" == "sample" ]]; then
    sub_io=0
    while [[ "${sub_io}" -lt 1 ]]; do
      i=$(($(cat ${1}/${2} | grep -wn ">Plan" | cut -d ':' -f 1) - 2))
      j=$(cat ${1}/${2} | wc -l)

      if [[ "${i}" -gt 0 ]] && [[ "${j}" -gt 0 ]]; then
        cat ${1}/${2} | sed -n "1,${i}p" >${1}/.${2}.part1
        ((i++))
        cat ${1}/${2} | sed -n "${i},${j}p" >${1}/.${2}.part2

        echo '
----------
Sub-Menu
add
1. [column] add [content]
2. add [row entry]

change
1. [label] [column] change [content]
2. [label] change [content]

remove 
1. [label] [column] remove
2. remove [row entry]

back
----------'
        read -p $'\nIn-section operation <- ' input
        if [[ "$(echo "${input}" | grep -wi 'add')" ]]; then
          if [[ "$(echo "${input}" | tr " " "\n" | grep -win 'add' | cut -d ':' -f 1)" -eq 1 ]]; then
            insert=$(echo "${input}" | sed "s/add //" | tr " " "\t")
            echo -e "${insert}" >${1}/.${2}.insert
            cat ${1}/.${2}.part1 ${1}/.${2}.insert ${1}/.${2}.part2 >${1}/${2}
            rm -rf ${1}/.${2}.part1 ${1}/.${2}.insert ${1}/.${2}.part2
          else
            column=$(echo "${input}" | cut -d ' ' -f 1)
            content=$(echo "${input}" | sed "s/${column} add //")

            i=$(($(cat ${1}/${2} | grep -wn ">Sample" | cut -d ':' -f 1) + 1))
            head=$(cat ${1}/${2} | sed -n "${i}p" | tr "\t" "\n")
            column_i=$(echo "${head}" | grep -win "${column}" | cut -d ':' -f 1)

            insert="NA"
            j=2
            while [[ "${j}" -lt "${column_i}" ]]; do
              insert=$(echo "${insert}\tNA")
              ((j++))
            done

            insert=$(echo "${insert}\t${content}")

            j=$((column_i + 1))
            while [[ "${j}" -le 7 ]]; do
              insert=$(echo "${insert}\tNA")
              ((j++))
            done

            echo -e "${insert}" >${1}/.${2}.insert
            cat ${1}/.${2}.part1 ${1}/.${2}.insert ${1}/.${2}.part2 >${1}/${2}
            rm -rf ${1}/.${2}.part1 ${1}/.${2}.insert ${1}/.${2}.part2
          fi

        elif [[ "$(echo "${input}" | grep -wi 'change')" ]]; then
          if [[ "$(echo "${input}" | tr " " "\n" | grep -win 'change' | cut -d ':' -f 1)" -eq 2 ]]; then
            label=$(echo "${input}" | cut -d ' ' -f 1)
            content=$(echo "${input}" | sed "s/${label} change //" | tr " " "\t")
            changed=$(cat ${1}/${2} | grep -wi "${label}")

            sed -i '' "s/${changed}/${content}/" ${1}/${2}
          else
            label=$(echo "${input}" | cut -d ' ' -f 1)
            column=$(echo "${input}" | cut -d ' ' -f 2)
            content=$(echo "${input}" | sed "s/${label} ${column} change //")

            column_i=$(cat ${1}/${2} | grep -wi "${column}" | tr "\t" "\n" | grep -win "${column}" | cut -d ':' -f 1)
            label_c=$(cat ${1}/${2} | grep -w "${label}")
            changed=$(echo "${label_c}" | tr "\t" "\n" | sed "${column_i}c ${content}" | tr "\n" "\t")

            sed -i '' "s/${label_c}/${changed}/" ${1}/${2}
          fi

        elif [[ "$(echo "${input}" | grep -wi 'remove')" ]]; then
          if [[ "$(echo "${input}" | tr " " "\n" | grep -win 'remove' | cut -d ':' -f 1)" -eq 1 ]]; then
            removal=$(echo "${input}" | sed "s/remove //" | tr " " "\t")
            sed -i '' "/${removal}/d" ${1}/${2}
          else
            label=$(echo "${input}" | cut -d ' ' -f 1)
            column=$(echo "${input}" | cut -d ' ' -f 2)

            column_i=$(cat ${1}/${2} | grep -wi "${column}" | tr "\t" "\n" | grep -win "${column}" | cut -d ':' -f 1)
            content=$(cat ${1}/${2} | grep -w "${label}")
            removal=$(echo "${content}" | tr "\t" "\n" | sed "${column_i}c NA" | tr "\n" "\t")

            sed -i '' "s/${content}/${removal}/" ${1}/${2}
          fi

        elif [[ "${input}" == 'back' ]]; then
          ((sub_io++))
        fi

      else
        echo -e "***Message: Something wrong in the file ${2}.\n"
      fi
    done

  elif [[ "${3}" == "Plan" ]] || [[ "${3}" == "plan" ]]; then
    sub_io=0
    while [[ "${sub_io}" -lt 1 ]]; do
      echo '
----------
Sub-Menu
1. [type] add [quantity]
2. [type] change [quantity]
3. [type] remove
4. back
----------'
      read -p $'\nIn-section operation <- ' input
      if [[ "${input}" == 'back' ]]; then
        ((sub_io++))
      else
        type=$(echo "${input}" | cut -d ' ' -f 1)
        quantity=$(echo "${input}" | cut -d ' ' -f 3)

        if [[ "$(echo "${input}" | tr ' ' "\n" | egrep -win 'add|change' | cut -d ':' -f 1)" -eq 2 ]]; then
          if [[ -z "${quantity}" ]]; then
            control=0
            while [[ "${control}" -lt 1 ]]; do
              read -p "***Requirement: Specify quantity: " quantity
              if [[ "${quantity}" ]]; then
                ((control++))
              fi
            done
          fi
        else
          quantity=' '
        fi

        match=$(grep -wi "${type}" ${1}/${2})
        TAB=$'\t'
        sed -i '' "s/${match}/${type}${TAB}${quantity}/" ${1}/${2}
      fi
    done

  elif [[ "${3}" == "Progress" ]] || [[ "${3}" == "progress" ]]; then
    sub_io=0
    while [[ "${sub_io}" -lt 1 ]]; do
      echo '
----------
Sub-Menu
1. [stage] add [quantity] [date]
2. [stage] [column] change [content]
3. [stage] [column] remove
4. back
----------'
      read -p $'\nIn-section operation <- ' input
      if [[ "$(echo "${input}" | tr " " "\n" | grep -win 'add' | cut -d ':' -f 1)" -eq 2 ]]; then
        stage=$(echo "${input}" | cut -d ' ' -f 1)
        quantity=$(echo "${input}" | cut -d ' ' -f 3)

        if [[ -z "${quantity}" ]]; then
          control=0
          while [[ "${control}" -lt 1 ]]; do
            read -p "***Requirement: Specify quantity: " quantity
            if [[ "${quantity}" ]]; then
              ((control++))
            fi
          done
        fi

        date=$(echo "${input}" | cut -d ' ' -f 4)

        if [[ -z "${date}" ]]; then
          control=0
          while [[ "${control}" -lt 1 ]]; do
            read -p "***Requirement: Specify date: " date
            if [[ "${date}" ]]; then
              ((control++))
            fi
          done
        fi

        match=$(grep -wi "${stage}" ${1}/${2})
        TAB=$'\t'
        sed -i '' "s/${match}/${stage}${TAB}${quantity}${TAB}${date}/" ${1}/${2}

      elif [[ "$(echo "${input}" | tr " " "\n" | grep -win 'change' | cut -d ':' -f 1)" -eq 3 ]]; then
        stage=$(echo "${input}" | cut -d ' ' -f 1)
        column=$(echo "${input}" | cut -d ' ' -f 2)
        content=$(echo "${input}" | sed "s/${stage} ${column} change //")

        column_i=$(cat ${1}/${2} | grep -wi "${column}" | tr "\t" "\n" | grep -win "${column}" | cut -d ':' -f 1)
        stage_c=$(cat ${1}/${2} | grep -w "${stage}")
        changed=$(echo "${stage_c}" | tr "\t" "\n" | sed "${column_i}c ${content}" | tr "\n" "\t")

        sed -i '' "s/${stage_c}/${changed}/" ${1}/${2}

      elif [[ "$(echo "${input}" | tr " " "\n" | grep -win 'remove' | cut -d ':' -f 1)" -eq 3 ]]; then
        stage=$(echo "${input}" | cut -d ' ' -f 1)
        column=$(echo "${input}" | cut -d ' ' -f 2)

        column_i=$(cat ${1}/${2} | grep -wi "${column}" | tr "\t" "\n" | grep -win "${column}" | cut -d ':' -f 1)
        content=$(cat ${1}/${2} | grep -w "${stage}")
        removal=$(echo "${content}" | tr "\t" "\n" | sed "${column_i}c ' '" | tr "\n" "\t")

        sed -i '' "s/${content}/${removal}/" ${1}/${2}

      elif [[ "${input}" == 'back' ]]; then
        ((sub_io++))
      fi
    done

  elif [[ "${3}" == "Comment" ]] || [[ "${3}" == "comment" ]]; then
    sub_io=0
    while [[ "${sub_io}" -lt 1 ]]; do
      echo '
----------
Sub-Menu
1. add [comment]
2. back
----------'
      read -p $'\nIn-section operation <- ' input
      if [[ "$(echo "${input}" | grep -wi 'add')" ]]; then
        echo "${input}" | sed "s/add //" >>${1}/${2}
      elif [[ "${input}" == 'back' ]]; then
        ((sub_io++))
      fi
    done
  fi
}

export Template='Sci> Sci_NA
Eng> Eng_NA
----------
>Sample
Label	Sex	Position	MolSex	Sex_Date	HMW	Selection
----------
>Plan
Type	Quantity
Illumina
10XC
Hi-Seq
PacBio
----------
>Progress
Stage	Quantity	Registration_date
Extraction
Sexing
Sample_selection
Sent_for_seq
----------
>Comment'

Menu='----------
Menu
1. search/check [file]
2. create [file]
3. edit [file] [section]
4. nanoedit [file]
5. delete [file]
6. exit/quit/q
----------'

# Parse the flags
while getopts "ha:" opt; do
  case $opt in
  h) usage && exit ;;
  a) Database=$(echo "${OPTARG}" | cut -d "/" -f 1) ;;
  esac
done

# Test availability of the database
dir=$(pwd)
if [[ ! -d "${dir}}/${Database}" ]] || [[ -z "${Database}" ]]; then
  Database=$(echo "${dir}/_SSP_Database")
  if [[ ! -d "${Database}" ]]; then
    read -p "Requirement: Specify the directory of the database: " Database
    if [[ -z "${Database}" ]]; then
      echo -e "***Message: Missing database information.\n"
      exit
    elif [[ ! -d "${Database}" ]] || [[ ! -d "${dir}/${Database}" ]]; then
      echo -e "***Message: Database unavailable.\n"
      exit
    else
      dir=$(dirname "${Database}")
    fi
  fi
fi

# Begin
echo "***Message: Database was successfully loaded."

io=0
while [[ "${io}" -lt 1 ]]; do
  echo "${Menu}"
  read -p $'\nOperation <- ' input

  in_command=$(echo "${input}" | cut -d ' ' -f 1)
  if [[ "${in_command}" == "search" ]] || [[ "${in_command}" == "check" ]]; then

    file=$(echo "${input}" | sed "s/^search //" | sed "s/^check //" | tr ' ' '_')
    if [[ "$(echo "${file}" | cut -d '.' -f 2)" != 'profile' ]]; then
      file=$(echo "${file}.profile")
    fi

    if [[ "${in_command}" == "search" ]]; then
      input_tester 'search' "${input}"
      if [[ "${exe}" == "OK" ]]; then
        search ${Database} ${file} #Direct to search function
      else
        echo -e "***Message: Failing command.\n"
      fi
    else
      input_tester 'check' "${input}"
      if [[ "${exe}" == "OK" ]]; then
        check ${Database} ${file} #Direct to check function
      else
        echo -e "***Message: Failing command.\n"
      fi
    fi

  elif [[ "${in_command}" == "create" ]]; then
    input_tester 'create' "${input}"
    if [[ "${exe}" == "OK" ]]; then
      file=$(echo "${input}" | sed "s/^create //" | tr ' ' '_')
      if [[ "$(echo "${file}" | cut -d '.' -f 2)" != 'profile' ]]; then
        file=$(echo "${file}.profile")
      fi

      create ${Database} ${file} #Direct to create function
    else
      echo -e "***Message: Failing command.\n"
    fi

  elif [[ "${in_command}" == 'edit' ]]; then
    input_tester 'edit' "${input}"
    if [[ "${exe}" == "OK" ]]; then
      file=$(echo "${input}" | sed "s/^edit //" | tr ' ' '_')
      if [[ "$(echo "${file}" | cut -d '.' -f 2)" != 'profile' ]]; then
        file=$(echo "${file}.profile")
      fi

      section=$(echo "${input}" | cut -d ' ' -f 3)

      species=$(echo "${file}" | cut -d '.' -f 1)
      if [[ -e ${Database}/${file} ]]; then
        if [[ -z "${section}" ]]; then
          s_control=0
          while [[ "${s_control}" -lt 1 ]]; do
            read -p "***Requirement: Specify section: " section
            if [[ "$(cat ${Database}/${file} | grep -wi ${section})" ]]; then
              ((s_control++))
            fi
          done
        fi

        edit ${Database} ${file} ${section} #Direct to edit function
      elif [[ "$(grep -wr "${species}" ${Database})" ]]; then
        file=$(basename $(grep -wr "${species}" ${Database} | sed -n "1p" | cut -d ':' -f 1))

        if [[ -z "${section}" ]]; then
          s_control=0
          while [[ "${s_control}" -lt 1 ]]; do
            read -p "***Requirement: Specify section: " section
            if [[ "$(cat ${Database}/${file} | grep -wi ${section})" ]]; then
              ((s_control++))
            fi
          done
        fi

        edit ${Database} ${file} ${section} #Direct to edit function
      else
        echo -e "***Message:Profile doesn't exists!\n"
      fi
    else
      echo -e "***Message: Failing command.\n"
    fi

  elif [[ "${in_command}" == 'nanoedit' ]]; then
    input_tester 'nanoedit' "${input}"
    if [[ "${exe}" == "OK" ]]; then
      file=$(echo "${input}" | sed "s/^nanoedit //" | tr ' ' '_')
      if [[ "$(echo "${file}" | cut -d '.' -f 2)" != 'profile' ]]; then
        file=$(echo "${file}.profile")
      fi

      species=$(echo "${file}" | cut -d '.' -f 1)
      if [[ -e ${Database}/${file} ]]; then
        nano ${Database}/${file}
      elif [[ "$(grep -wr "${species}" ${Database})" ]]; then
        file=$(basename $(grep -wr "${species}" ${Database} | sed -n "1p" | cut -d ':' -f 1))
        nano ${Database}/${file}
      else
        echo -e "***Message:Profile doesn't exists!\n"
      fi
    else
      echo -e "***Message: Failing command.\n"
    fi

  elif [[ "${in_command}" == 'delete' ]]; then
    input_tester 'delete' "${input}"
    if [[ "${exe}" == "OK" ]]; then
      file=$(echo "${input}" | sed "s/^delete //" | tr ' ' '_')
      if [[ "$(echo "${file}" | cut -d '.' -f 2)" != 'profile' ]]; then
        file=$(echo "${file}.profile")
      fi

      rm -i ${Database}/${file}
    else
      echo -e "***Message: Failing command.\n"
    fi

  elif [[ "${in_command}" == 'exit' ]] || [[ "${in_command}" == 'q' ]] || [[ "${in_command}" == 'quit' ]]; then
    ((io++))
  else
    echo -e "***Message: Unrecognizable command.\n"
  fi

done
