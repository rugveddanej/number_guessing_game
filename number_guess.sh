#!/bin/bash

# PSQL variable for database queries
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if username exists in database
USER_INFO=$($PSQL "SELECT username, games_played, best_game FROM users WHERE username='$USERNAME'")

if [[ -z $USER_INFO ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played, best_game) VALUES('$USERNAME', 0, 0)")
else
  # Existing user
  IFS='|' read USERNAME_DB GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
GUESS_COUNT=0

while true
do
  read GUESS
  GUESS_COUNT=$(( GUESS_COUNT + 1 ))
  
  # Check if input is a valid integer
  if [[ ! $GUESS =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    continue
  fi
  
  # Check the guess
  if [[ $GUESS -eq $SECRET_NUMBER ]]
  then
    echo "You guessed it in $GUESS_COUNT tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
done

# Update user statistics
if [[ -z $USER_INFO ]]
then
  # First game for new user
  UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played=1, best_game=$GUESS_COUNT WHERE username='$USERNAME'")
else
  # Update existing user
  NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
  if [[ $BEST_GAME -eq 0 || $GUESS_COUNT -lt $BEST_GAME ]]
  then
    # New best score
    UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$GUESS_COUNT WHERE username='$USERNAME'")
  else
    # No new best score
    UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE username='$USERNAME'")
  fi
fi
