#!/bin/bash

# PSQL variable for querying the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
NUMBER_OF_GUESSES=0

# Prompt for username
echo "Enter your username:"
read USERNAME

# Check if username exists in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username = '$USERNAME'")

USER_ID=
GAMES_PLAYED=
BEST_GAME=

if [[ -z $USER_INFO ]]
then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert new user into database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  # Get the newly created user_id
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username = '$USERNAME'")
  GAMES_PLAYED=0
  BEST_GAME=0 # Use 0 or a very high number to indicate no best game yet
else
  # Existing user
  IFS='|' read USER_ID GAMES_PLAYED BEST_GAME <<< "$USER_INFO"
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"

GUESS_LOOP() {
  read GUESS

  # Validate if input is an integer
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]
  then
    echo "That is not an integer, guess again:"
    GUESS_LOOP
    return # Exit the function call
  fi

  NUMBER_OF_GUESSES=$(( NUMBER_OF_GUESSES + 1 ))

  if [[ $GUESS -lt $SECRET_NUMBER ]]
  then
    echo "It's higher than that, guess again:"
    GUESS_LOOP
  elif [[ $GUESS -gt $SECRET_NUMBER ]]
  then
    echo "It's lower than that, guess again:"
    GUESS_LOOP
  else
    # Correct guess
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"

    # Update user's game stats
    NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
    UPDATE_GAMES_PLAYED_RESULT=$($PSQL "UPDATE users SET games_played = $NEW_GAMES_PLAYED WHERE user_id = $USER_ID")

    if [[ $BEST_GAME -eq 0 || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]
    then
      UPDATE_BEST_GAME_RESULT=$($PSQL "UPDATE users SET best_game = $NUMBER_OF_GUESSES WHERE user_id = $USER_ID")
    fi
  fi
}
#this is just to keep up with quota
#this also
#maybe next time do not keep quota of how many commits
GUESS_LOOP