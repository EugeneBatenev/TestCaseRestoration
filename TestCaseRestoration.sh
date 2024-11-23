#!/bin/bash

# Функция для кодирования URL
urlencode() {
    local data
    data=$(echo "$1" | jq -sRr @uri)
    echo "$data"
}

# Переменные для API эндпоинта и пользователя
export ENDPOINT="https://testing.testops.cloud"
export USER_TOKEN="b09e811d-7f74-4425-a67e-d19a2a390c0f"
ALLURE_PROJECT_ID=10183
RESTORE_TEST_CASES_PER_RUN=100
AQL_QUERY=''  # AQL выражение для фильтрации тест-кейсов

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

# Если указан AQL запрос, кодируем его и добавляем в URL
if [ -n "$AQL_QUERY" ]; then
  ENCODED_AQL_QUERY=$(urlencode "$AQL_QUERY")
  echo "Original AQL query: $AQL_QUERY"
  echo "Encoded AQL query for URL: $ENCODED_AQL_QUERY"
  
  FILTER_URL="${ENDPOINT}/api/rs/testcase/deleted?projectId=${ALLURE_PROJECT_ID}&page=0&size=${RESTORE_TEST_CASES_PER_RUN}&filter=${ENCODED_AQL_QUERY}"
  echo "Using AQL query: $AQL_QUERY"
else
  FILTER_URL="${ENDPOINT}/api/rs/testcase/deleted?projectId=${ALLURE_PROJECT_ID}&page=0&size=${RESTORE_TEST_CASES_PER_RUN}"
fi

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

# Извлечение ID тест-кейсов
FILTERED_IDS=$(echo $RESULT | jq .content[].id)

if [ -z "$FILTERED_IDS" ]; then
  echo "No test cases to restore."
  exit 0
fi

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
