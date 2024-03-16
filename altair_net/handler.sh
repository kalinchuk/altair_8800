#!/bin/bash

handle_response() {
  prompt="$1"
  response=$(curl -s "$prompt" | w3m -dump -T text/html)
  echo "$response"
}

# Function to clean up the prompt and handle backspace
process_input() {
  input=$(echo "$input" | tr '\r' ' ')
  input=$(printf "%s" "$1" | sed 's/^[^[:alnum:]]*//;s/[^[:alnum:]]*$//')
  prompt=""
  len=$(printf "%s" "$input" | wc -m)
  for i in $(seq 1 $len); do
    char=$(printf "%s" "$input" | cut -c $i)
    
    if [ "$char" = "$(printf "\b")" ]; then
      prompt=$(printf "%s" "$prompt" | sed 's/.$//')
    else
      prompt="$prompt$char"
    fi
  done

  echo "$prompt"
}

# Function to handle incoming prompts
handle_prompt() {
  while read prompt; do
    prompt=$(process_input "$prompt")
    response=$(handle_response "$prompt")
    echo "$response ~"
  done
}

# Listen for prompts from clients
handle_prompt