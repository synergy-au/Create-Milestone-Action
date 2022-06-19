#!/bin/bash

# Initialize constants
LOWER_BOUND=3
UPPER_BOUND=28
NEW_TARGET=14

# Initialize variables
MILESTONE_LINKED=''

# --------------------------------------------------------------------------------

function create_milestone_curl_cmd()
{
    # First argument should be set as the milestone title
    TITLE=${1}

    # Second argument shold be set as the milestone due on date
    DUE_ON=${2}

    # Need to authenticate to obtain write access for the REST API POST event
    CREATED_MILESTONE=$( curl --silent -X POST -H "Authorization: token ${SECRETS_TOKEN}" "Accept: application/vnd.github.v3+json" https://api.github.com/repos/"${REPOSITORY}"/milestones -d '{"title":'\"${TITLE}\"',"due_on":'\"${DUE_ON}\"',"state":"open"}' )
}

function link_milestone_curl_cmd()
{
    # First argument should be set as the milestone number
    MILESTONE_NUMBER=${1}

    # The issue or pull request number used to link the milestone to
    ISSUE_NUMBER="${PULL_REQUEST_NUMBER}"

    # Need to authenticate to obtain write access for the REST API PATCH event
    LINKED_PULL_REQUEST=$( curl --silent -X PATCH -H "Authorization: token ${SECRETS_TOKEN}" "Accept: application/vnd.github.v3+json" https://api.github.com/repos/"${REPOSITORY}"/issues/"${ISSUE_NUMBER}" -d '{"milestone":'\"${MILESTONE_NUMBER}\"'}' )
}

# --------------------------------------------------------------------------------

# Display information from Github
echo Github Repository: "${REPOSITORY}"
echo Pull Request Name: "${PULL_REQUEST_TITLE}"
echo Pull Request Number: "${PULL_REQUEST_NUMBER}"
echo Pull Request Milestone: "${PULL_REQUEST_MILESTONE}"

# Check whether a milestone is linked to the pull request
# If there is no milestone linked to the pull request then a value of "null" is returned from the API
if [[ $PULL_REQUEST_MILESTONE != "null" ]];
then
    MILESTONE_LINKED='true'
else
    MILESTONE_LINKED='false'
fi

if [[ $MILESTONE_LINKED == "true" ]];
then
    echo A milestone is already linked!
    echo New milestone cannot be created or linked
else
    echo There is no milestone linked to the pull request

    # Set datetime variables for milestone filtering after searching
    CURRENT_DATETIME=$( echo $(date +'%Y-%m-%dT%H:%M:%SZ') )
    LOWER_BOUND_DATETIME_REF=$( echo $(date +'%Y-%m-%dT%H:%M:%SZ' --date "$CURRENT_DATETIME +$LOWER_BOUND days") )
    UPPER_BOUND_DATETIME_REF=$( echo $(date +'%Y-%m-%dT%H:%M:%SZ' --date "$CURRENT_DATETIME +$UPPER_BOUND days") )
    NEW_TARGET_DATETIME_REF=$( echo $(date +'%Y-%m-%dT%H:%M:%SZ' --date "$CURRENT_DATETIME +$NEW_TARGET days") )

    # Get all OPEN milestones with a due date newer than the current date and time
    MILESTONE_DATA=$( curl --silent -H "Accept: application/vnd.github.v3+json" https://api.github.com/repos/"${REPOSITORY}"/milestones?state=open\&sort=due_on\&direction=asc )
    FUTURE_MILESTONES=$( echo $MILESTONE_DATA | jq --raw-output '[ .[] | select((.due_on >= '\"$LOWER_BOUND_DATETIME_REF\"') and (.due_on <= '\"$UPPER_BOUND_DATETIME_REF\"')) ]' )

    if [[ $FUTURE_MILESTONES != '' ]];
    then
        echo Future milestones within the range of the lower and upper bounds have been found

        MILESTONE=$( echo $FUTURE_MILESTONES | jq --raw-output '.[0]' )
        MILESTONE_NUMBER=$( echo $MILESTONE | jq --raw-output '.number' )

        echo Linking milestone number $MILESTONE_NUMBER to pull request number $PULL_REQUEST_NUMBER
        link_milestone_curl_cmd $MILESTONE_NUMBER
    else
        echo No future milestones found within the range of the lower and upper bounds

        echo Creating new future milestone
        MILESTONE_TITLE=$( echo $(date +'%Y-%m-%d' --date "$NEW_TARGET_DATETIME_REF") )
        create_milestone_curl_cmd $MILESTONE_TITLE $NEW_TARGET_DATETIME_REF
        MILESTONE_NUMBER=$( echo $CREATED_MILESTONE | jq --raw-output '.number' )

        echo Linking milestone number $MILESTONE_NUMBER to pull request number $PULL_REQUEST_NUMBER
        link_milestone_curl_cmd $MILESTONE_NUMBER
    fi
fi
