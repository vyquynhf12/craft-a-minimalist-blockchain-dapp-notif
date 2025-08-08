#!/bin/bash

# Constants
CHAIN_RPC="https://mainnet.infura.io/v3/YOUR_PROJECT_ID"
CONTRACT_ADDRESS="0x...YOUR_CONTRACT_ADDRESS..."

# Set up notification service (e.g. Telegram, Discord, etc.)
NOTIFICATION_SERVICE="telegram"
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

# Set up blockchain query interval (in seconds)
QUERY_INTERVAL=60

# Function to query blockchain for new transactions
query_blockchain() {
  curl -X POST \
  $CHAIN_RPC \
  -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_getTransactionCount","params":["'$CONTRACT_ADDRESS'"],"id":1}'

  # Parse JSON response
  TRANSACTION_COUNT=$(jq '.result' | tr -d '"')

  # Check if new transactions are available
  if [ $TRANSACTION_COUNT -gt $LAST_TRANSACTION_COUNT ]; then
    # Get new transactions and notify via notification service
    NEW_TRANSACTIONS=$(curl -X POST \
      $CHAIN_RPC \
      -H 'Content-Type: application/json' \
      -d '{"jsonrpc":"2.0","method":"eth_getTransactionByHash","params":["'$CONTRACT_ADDRESS'"],"id":1}')

    # Send notification
    case $NOTIFICATION_SERVICE in
      telegram)
        curl -X POST \
        https://api.telegram.org/bot$BOT_TOKEN/sendMessage \
        -H 'Content-Type: application/json' \
        -d '{"chat_id": "'$CHAT_ID'", "text": "New transactions detected!\n\n'$NEW_TRANSACTIONS'"}'
        ;;
      *)
        echo "Unsupported notification service"
        ;;
    esac

    # Update last transaction count
    LAST_TRANSACTION_COUNT=$TRANSACTION_COUNT
  fi
}

# Main loop
while true; do
  query_blockchain
  sleep $QUERY_INTERVAL
done