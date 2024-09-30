#!/bin/bash

# Переменные для API эндпоинта и пользователя
export ENDPOINT="https://testing.testops.cloud"
export USER_TOKEN="b09e811d-7f74-4425-a67e-d19a2a390c0f"
ALLURE_PROJECT_ID=10318
RESTORE_TEST_CASES_PER_RUN=100
AQL_FILTER=""

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

# Проверка наличия AQL фильтра
if [ -z "$AQL_FILTER" ]; then
  echo "Warning: No AQL filter provided. Fetching all deleted test cases."
else
  echo "Using AQL filter: $AQL_FILTER"
fi

# Получение удалённых тест-кейсов с фильтрацией по AQL (если указана)
if [ -z "$AQL_FILTER" ]; then
  RESULT=$(curl -s -X GET "${ENDPOINT}/api/rs/testcase/deleted?projectId=${ALLURE_PROJECT_ID}&page=0&size=${RESTORE_TEST_CASES_PER_RUN}" \
    --header "accept: */*" \
    --header "Authorization: Bearer ${JWT_TOKEN}")
else
  RESULT=$(curl -s -X GET "${ENDPOINT}/api/rs/testcase/deleted?projectId=${ALLURE_PROJECT_ID}&page=0&size=${RESTORE_TEST_CASES_PER_RUN}&query=$(echo $AQL_FILTER)" \
    --header "accept: */*" \
    --header "Authorization: Bearer ${JWT_TOKEN}")
fi

# Проверка, найдены ли тест-кейсы
if [ -z "$RESULT" ]; then
  echo "No deleted test cases found or there was an error."
  exit 1
fi

echo "Found deleted test cases in project ${ALLURE_PROJECT_ID}:"

# Извлечение ID тест-кейсов
IDS=$(echo $RESULT | jq .content[].id)

# Проверка, есть ли ID для восстановления
if [ -z "$IDS" ]; then
  echo "No test cases to restore."
  exit 0
fi

# Восстановление каждого тест-кейса
for ID in ${IDS}; do
    echo "Restoring test case ID: ${ID}"
    curl -s -X PATCH "${ENDPOINT}/api/rs/testcase/${ID}" \
      --header "accept: */*" \
      --header "Content-Type: application/json" \
      --header "Authorization: Bearer ${JWT_TOKEN}" \
      -d "{\"deleted\": false}"
    echo "Test case ${ID} restored."
done

echo "Restoration process completed."
