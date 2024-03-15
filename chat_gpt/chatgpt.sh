#!/bin/bash

# OpenAI ChatGPT API endpoint
API_ENDPOINT="https://api.openai.com/v1/chat/completions"

# OpenAI API Key
API_KEY="SET_YOUR_KEY"

# Function to send prompt to ChatGPT API and get response
get_chatgpt_response() {
    prompt="$1"

    payload=$(jq -n \
                  --arg model "gpt-3.5-turbo" \
                  --arg content "$prompt" \
                  --argjson max_tokens 500 \
                  '{
                    model: $model,
                    messages: [{role: "user", content: $content}],
                    max_tokens: $max_tokens
                   }')

    response=$(curl -s -X POST \
                    -H "Content-Type: application/json" \
                    -H "Authorization: Bearer $API_KEY" \
                    -d "$payload" \
                    $API_ENDPOINT)

    # Check if the response contains an error
    error_message=$(echo "$response" | jq -r '.error.message //empty')
    if [ -n "$error_message" ]; then
        # If there is an error message, print it
        echo "Sorry, I don't understand. Please try a different prompt."
    else
        # Extract and return the response from JSON
        response=$(echo "$response" | jq -r '.choices[0].message.content')
        # Replace ~ with another char since it's used as an ending char
        response=$(echo "$response" | tr '~' '-')
        # Replace \n with a \r\n
        response=$(echo "$response" | awk 'ORS="\n\r"' )
        echo "$response"
    fi
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
        elif [[ "$char" =~ [^a-zA-Z0-9] ]]; then
            prompt="$prompt\\$char"
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
        # Send prompt to ChatGPT API and get response
        response=$(get_chatgpt_response "$prompt")

        # Send response back to the client
        echo "$response ~"
    done
}

# Listen for prompts from clients
handle_prompt