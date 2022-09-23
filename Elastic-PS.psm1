# A set of functions to interact with the Elastic Stack API
# Written by Samuel Barrows for ResponderCon 2022

#Set the kibana url and port on the script scope
#url should contain the full URL
#EX: https://10.0.8.32:5601
function Set-KibanaIP($url){
    $script:KIBANA = $url 
}

#Set the elastic url and port on the script scope
#url should contain the full URL
#EX: https://10.0.8.32:9200
function Set-ElasticIP($url){
    $script:ELASTIC = $url
}

#Get the credentials for authenticating to the API
function Set-KibanaCreds(){
    Write-Output "Enter Kibana Creds"
    $script:CREDS = Get-Credential
}

######## The above commands should be run first for convenience sake ######## 

function Set-Space($name){
    #Create a specified space

    # New Space Details
    $postParams = @{id=$name;name=$name;description=$name + " space";color='#aabbcc';initials=$name[0];}
    #disabledFeatures='["enterpriseSearch","apm","fleet","fleetv2","stackAlerts","osquery","indexPatterns","observabilityCases","ml","canvas","actions","uptime","infrastructure","savedObjectsManagement","savedObjectsTagging","actions","generalCases","stackAlerts"]'}

    # needed for some reason
    $headers = @{"kbn-xsrf"='true';}

    #Make the actual request
    Invoke-WebRequest -SkipCertificateCheck -Uri $KIBANA/api/spaces/space `
    -Method POST -Body $postParams -Headers $headers -Authentication Basic -Credential $CREDS 
}

function Remove-Space($name){
    # Delete a specified space

    # needed for some reason
    $headers = @{"kbn-xsrf"='true';}

    Invoke-WebRequest -SkipCertificateCheck -Uri $KIBANA/api/spaces/space/$name `
    -Method Delete -Headers $headers -Authentication Basic -Credential $CREDS
}

function Set-Role($name){
    #Create a role
    
    #Headers
    $headers = @{"kbn-xsrf"='true';}

    #The request (hash tables fucked itself)
    $body = "
    {
    `"metadata`" : {
        `"version`" : 1
    },
    `"elasticsearch`": {
        `"cluster`" : [ `"read_slm`", `"read_ccr`" ],
        `"indices`" : [ {
        `"names`" : [ `"winlogbeat-*`", `".items-*`", `".lists-*`", `".alerts-security.alerts-*`", `".items-default`", `".lists-default`", `".alerts-security.alerts-default`" ],
        `"privileges`" : [ `"read`", `"read_cross_cluster`", `"view_index_metadata`", `"monitor`", `"index`" ]
        } ]
    },
    `"kibana`": [
        {
        `"base`": [`"all`"],
        `"feature`": {
        },
        `"spaces`": [
            `"$name`",
            `"default`"
        ]
        }
    ]
    }
    "
    #read, write,view_index_metadata,mainenance, for .items-prd-win10-HOST, . preventing access to alerts page

    #Make the request
    Invoke-WebRequest -SkipCertificateCheck -Uri $KIBANA/api/security/role/$name `
    -Method Put -Body $body -Headers $headers -Authentication Basic -Credential $CREDS
}

#There should be a mass delete for roles
function Remove-Role($name){
    #remove a role

    $headers = @{"kbn-xsrf"='true';}

    Invoke-WebRequest -SkipCertificateCheck -Uri $KIBANA/api/security/role/$name `
    -Method Delete -Headers $headers -Authentication Basic -Credential $CREDS
}

function Set-User($name){
    #Create a user

    #$headers = "`"Content-Type`":`"application/json`""

    $body = "
    {
        `"password`" : `"l0ng-r4nd0m-p@ssw0rd`",
        `"roles`" : [ `"$name`" ],
        `"full_name`" : `"$name`"
    }
    "
    Invoke-WebRequest -SkipCertificateCheck -Uri $ELASTIC/_security/user/$name `
    -Method Put -Body $body -Headers @{"Content-Type"="application/json";} -Authentication Basic -Credential $CREDS
    
}

#There should be a mass delete for users

function Remove-User($name){
    #Remove a user
    Invoke-WebRequest -SkipCertificateCheck -Uri $ELASTIC/_security/user/$name `
    -Method Delete -Headers @{"Content-Type"="application/json";} -Authentication Basic -Credential $CREDS
}

function Set-DataView($name){
    #Create a dataview
    $headers = @{"kbn-xsrf"='true';'Content-Type'='application/json'}
    #$headers = @{"kbn-xsrf"='true';}

    $title = "winlogbeat-$name-index".ToString()
    $body = "
    {
        `"data_view`": {
            `"title`": `"$title*`",
            `"name`": `"$title*`"
        }
    }
    "
    Invoke-WebRequest -SkipCertificateCheck -Uri $KIBANA/s/$name/api/data_views/data_view `
    -Method Post -Headers $headers -Body $body -Authentication Basic -Credential $CREDS
}

function Remove-DataView($name){
    #Remove a Dataview
    $headers = @{"kbn-xsrf"='true';}

    Invoke-WebRequest -SkipCertificateCheck -Uri $KIBANA/s/$name/api/data_views/data_view/$name `
    -Method Delete -Headers $headers -Authentication Basic -Credential $CREDS
    
}

function Import-Rules($name){
    #import an ndjson ruleset into a space
    
    #Doesnt work, but just creates the rulesets
    #for each space

    #$headers = @{"kbn-xsrf"='true';"Content-Type"="multipart/form-data";}

    #$form = @{"filename"="@20220902T145154.ndjson";"file"="@20220902T145154.ndjson";}

    #replace the index of each rule to be our spaces index
    #NOTE: This implies that the ruleset has the index of "log-index"
    #      This was done as a placeholder for this line
    (Get-Content .\rules.ndjson -Raw) -Replace "`"log-index`"", `
    "`"winlogbeat-$name-index`"" | Set-Content .\$name-sig.ndjson

    #The webrequest
    #Invoke-WebRequest -SkipCertificateCheck -Uri $KIBANA:5601/s/$name/api/detection_engine/rules/_import?overwrite=true `
    #-Method Post -Headers $headers -Form $form -Authentication Basic -Credential $CREDS

}

function Set-FullAccount($name){
#Create all the nessesary stuff for a user account
    Set-Space $name
    Set-Role $name
    Set-User $name
    Set-DataView $name
} 

function Remove-FullAccount($name){
    #Delete all aspects of an account
    Remove-Space $name
    Remove-Role $name
    Remove-User $name
    Remove-DataView $name
}

Export-ModuleMember -Function *
Export-ModuleMember -Function 'Get-KibanaCreds'