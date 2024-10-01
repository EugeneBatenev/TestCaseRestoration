#!/bin/bash

# Переменные для API эндпоинта и пользователя
export ENDPOINT="https://testing.testops.cloud"
export USER_TOKEN="b09e811d-7f74-4425-a67e-d19a2a390c0f"
ALLURE_PROJECT_ID=10183
RESTORE_TEST_CASES_PER_RUN=100

# Получение Bearer-токена
echo "Obtaining Bearer token..."
JWT_TOKEN=$(curl -s -X POST "${ENDPOINT}/api/uaa/oauth/token" \
     --header "Expect:" \
     --header "Accept: application/json" \
     --form "grant_type=apitoken" \
     --form "scope=openid" \
     --form "token=${USER_TOKEN}" \
     | jq -r .access_token)

# Проверка, получен ли токен
if [ -z "$JWT_TOKEN" ]; then
  echo "Error: Could not retrieve JWT token."
  exit 1
fi

echo "Bearer token obtained successfully: $JWT_TOKEN"

# URL для получения всех удалённых тест-кейсов
FILTER_URL="${ENDPOINT}/api/rs/testcase/deleted?projectId=${ALLURE_PROJECT_ID}&page=0&size=${RESTORE_TEST_CASES_PER_RUN}"

# Получение удалённых тест-кейсов
echo "Fetching deleted test cases..."
RESULT=$(curl -s -X GET "${FILTER_URL}" \
  --header "accept: */*" \
  --header "Authorization: Bearer ${JWT_TOKEN}")

# Проверка, найдены ли тест-кейсы
if [ -z "$RESULT" ]; then
  echo "No deleted test cases found or there was an error."
  exit 1
fi

# Подсчёт количества удалённых тест-кейсов
DELETED_COUNT=$(echo $RESULT | jq '.content | length')

echo "Found ${DELETED_COUNT} deleted test case(s) in project ${ALLURE_PROJECT_ID}:"

# Если тест-кейсы не найдены, завершение работы скрипта
if [ "$DELETED_COUNT" -eq 0 ]; then
  echo "No test cases to restore."
  exit 0
fi

# Подтверждение пользователя для восстановления тест-кейсов
read -p "Do you want to restore the deleted test cases? (y/n): " CONFIRMATION

if [ "$CONFIRMATION" == "y" ]; then
  # Извлечение ID тест-кейсов
  FILTERED_IDS=$(echo $RESULT | jq .content[].id)

  # Восстановление каждого тест-кейса
  for ID in ${FILTERED_IDS}; do
      echo "Restoring test case ID: ${ID}"
      curl -s -X PATCH "${ENDPOINT}/api/rs/testcase/${ID}" \
        --header "accept: */*" \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer ${JWT_TOKEN}" \
        -d "{\"deleted\": false}"
      echo "Test case ${ID} restored."
  done

  echo "Restoration process completed."

elif [ "$CONFIRMATION" == "n" ]; then
  echo "Operation canceled by user. Exiting in 10 seconds..."
  sleep 10
  exit 0
else
  echo "Invalid input. Please run the script again and enter 'y' or 'n'."
  exit 1
fi
