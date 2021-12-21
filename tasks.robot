*** Settings ***
Documentation     Template robot main suite.
Library            RPA.Dialogs
Library            RPA.Robocorp.Vault
Library            RPA.Browser.Selenium
Library            RPA.HTTP
Library            RPA.RobotLogListener
Library            RPA.Tables
Library            RPA.PDF
Library            RPA.Archive
Library            RPA.FileSystem
Library            RPA.Robocorp.Process

*** Variables ***
${GLOBAL_RETRY_AMOUNT}=    3x
${GLOBAL_RETRY_INTERVAL}=    1s

*** Keywords ***
Get Secret Data
    #Get data from vault.json
    ${secret}=    Get Secret    global_variable
    [Return]    ${secret}

*** Keywords ***
Open the robot order website

    #Open dialog to identity operator
    Add heading    We need to verify your identity !
    Add text   Please tell us your name:
    Add text input    name    
    ${dialog_result}=    Run dialog
    Log    Current operator: ${dialog_result}[name]

    ${secret}=    Get Secret Data

    #Open browser
    Open Chrome Browser    ${secret}[url]
    Maximize Browser Window
    Wait Until Element Is Visible    id:username    60
    Click Element    css:li.nav-item:nth-child(2)

*** Keywords ***
Get orders
    #Get order input file via url
    ${secret}=    Get Secret Data
    Download     ${secret}[url_input_file]      overwrite=True
    ${orders}   Read table from CSV    orders.csv   header=True    dialect=excel
    [Return]    ${orders}

*** Keywords ***
Close the annoying modal
    #Close popup when moving to Order Robot tab
    Click Button    css:button.btn.btn-dark
    Wait Until Element Is Visible    id:head    10

*** Keywords ***
Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Click Button    id:id-body-${row}[Body]
    Input Text    css:input.form-control    ${row}[Legs]
    Input Text    css:input.form-control:nth-child(2)    ${row}[Address]

*** Keywords ***
Preview the robot
    #Click Preview
    Click Button    id:preview

*** Keywords ***
Submit the order
    #Click Submit
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt    10

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]     ${order_number}
    ${html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${html}    ${CURDIR}${/}output${/}${order_number}.pdf
    [Return]    ${CURDIR}${/}output${/}${order_number}.pdf

*** Keywords ***
Take a screenshot of the robot
    [Arguments]     ${order_number}
    ${screenshot}=    Screenshot     id:robot-preview-image      ${CURDIR}${/}output${/}${order_number}.png
    [Return]    ${CURDIR}${/}output${/}${order_number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    #Capture screenshot
    [Arguments]    ${screenshot}    ${pdf}
    ${embed_screenshot} =     Create List    ${screenshot}
    Add files to pdf    ${embed_screenshot}    ${pdf}    TRUE


*** Keywords ***
Go to order another robot
    #Click Go to another
    Click Button    id:order-another

*** Keywords ***
Create a ZIP file of the receipts
    #Zip all receipt with embeded screenshot
    Archive Folder With Zip    ${CURDIR}${/}output${/}   ${CURDIR}${/}output${/}output.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${orders}=    Get orders
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Preview the robot
        Wait Until Keyword Succeeds    ${GLOBAL_RETRY_AMOUNT}    ${GLOBAL_RETRY_INTERVAL}    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
        Log To Console    ${row}
    END
    Create a ZIP file of the receipts