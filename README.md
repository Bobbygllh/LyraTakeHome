1. Ensure the VS Code RestClient Extension is installed
2. login to the Salesforce Dev org with the provided username and password
3. Navigate to Setup, then search and click on "App Manager"
4. Find the Connected App named Create Support Case (Create_Support_Case)
5. Click on the dropdown and select "View"
6. Next to Consumer Key and Secret, click "Manage Consumer Details"
7. Copy the Consumer Key and Secret to the scripts > authentication.rest file in this project
8. You should be able to click "Send Request" and retrieve an access_token
9. Replace the ---------------- in the CreateSupportCaseAPI.rest with the access_token
