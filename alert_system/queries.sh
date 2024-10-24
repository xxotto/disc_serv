#!/bin/bash

set -euo pipefail

CAMPAIGN_QUERY="
    SELECT campaign_id, campaign_name, active, campaign_description FROM vicidial_campaigns;
"

get_today_date() {
    date '+%Y-%m-%d'
}

get_lists_query() {
    local campaign_id="$1"
    echo "
        SELECT list_id, list_name, active, list_description 
        FROM vicidial_lists
        WHERE campaign_id='$campaign_id';
    "
}

get_leads_in_list_query() {
    local list_id="$1"
    local today
    today=$(get_today_date)
    echo "
        SELECT lead_id, entry_date, status, user, list_id 
        FROM vicidial_list 
        WHERE DATE(entry_date) = '$today' 
          AND status = 'NEW'
          AND list_id='$list_id'
        ORDER BY lead_id ASC
        LIMIT 6;
    "
}

get_leads_in_hopper_query() {
    local campaign_id="$1"
    echo "
        SELECT hopper_id, lead_id, campaign_id, list_id
        FROM vicidial_hopper
        WHERE campaign_id='$campaign_id' 
        ORDER BY hopper_id
        LIMIT 6;
    "
}
