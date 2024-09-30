## Test Case Restoration Script

## Variables
ENDPOINT: The Allure TestOps API endpoint.

USER_TOKEN: Your Allure TestOps API token.

ALLURE_PROJECT_ID: The ID of the project from which you want to restore test cases.

RESTORE_TEST_CASES_PER_RUN: The number of test cases to fetch and attempt to restore per run.


### How It Works
The script first obtains a Bearer token using the USER_TOKEN.
It then fetches deleted test cases from the specified project.
After fetching the deleted test cases, the script loops through them and restores each one by setting the deleted flag to false.
### Usage
Clone the repository or download the script.
Open the script and modify the following variables as needed:

ENDPOINT: Your Allure TestOps API endpoint.
USER_TOKEN: Your personal Allure TestOps token.
ALLURE_PROJECT_ID: The project ID you are working with.

