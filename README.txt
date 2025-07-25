The repository contains four files and details are provided below

1.Deploying WMS PL-SQL code into GIT repo.docx
    Usecase documentation for the AI implementation

2.Progress tracker in notion.zip
    Progress tracker for the use case (can be opened in Notion app)

3.warehouse_order_management.sql
    The auto generated code using cursor ai for order management process package

4.warehouse_order_management_with_orderid_limit.sql
    The auto generated code using cursor ai for add additional requirements to the order management process package



AI prompts for the usecase:-

1. Generating sample PL/SQL code for order management process in WMS:

AI prompt: Generate a sample PL/SQL code for order management process in the warehouse and provide all the components associated with the package to deploy them into Oracle DB.

2. Make changes to the PL/SQL code as per requirement using cursor IDE**

AI prompt: Include a condition to restrict the order id in Orders table within 999999. If the order id pass behind 999999, reset the order id to 1 and continue. Using Order Management Process PL/SQl block, suggest the best place to include the condition and show the inserted version of the procedure as well for the confirmation. Once confirmed, add the updated PL/SQL package to a new file and push the file to my Git repository.


3. Generating synthetic data using Python script (includes faker library)

AI prompt: Generate the synthetic data in the form of sql insert statements by running the Python script using faker library. The data should align with the tables available in the above pl sql script 