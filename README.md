# elastic-ps-automation
A set of functions for automating Kibana settings.

## USAGE

To use this Powershell Module, all you need to do is import it into the script that you want to write.

This can be done with the following Powershell command:

```powershell
import-module -Name .\Elastic-PS.psm1
```

With that you can use the functions located in the module

With this module imported, you can use all or some of the functions to quickly create a lot of
users, spaces, rulesets, or dataviews all at once. Individual functions are explained below.

## Functions Explained

To start scripting your Kibana settings, you'll first want to configure a few script-scoped variables

### Set-KibanaIP
Sets the Kibana URL that all the functions in this module will use.

EX:
```powershell
Set-KibanaIP "https://10.0.5.45:5601"
```

This will store the URL for Kibana in a script level IP called `$KIBANAIP`

### Set-ElasticIP
Much like the `Set-KibanaIP` function, this one will set the Elastic URL on the script level

EX:
```powershell
Set-ElasticIP "https://10.0.5.45:9200"
```
This will store the URL for Elastic in a script level IP called `$ELASTICIP`

### Set-KibanaCreds
While this is also used for elasticsearch, this function will create a PSCredential object will be used to authenticate to our server. If you are not using HTTPS with your stack, this command is not needed. If you are, make sure to run this function before running other commands.

EX:
```powershell
Set-KibanaCreds
```

This will store the PSCredential object in a script level variable called `$CREDS`

### Set-Space
This will create a space in Kibana with the user-passed `$name` variable. This is done through the creation of a 
hash table that is then passed in the body of the request to the Kibana server. 

You can have disabled features set here too. That is commented out, but it would be apart of the `$postParams` variable if used

EX:
```powershell
Set-Space "awesome-space"
```

### Remove-Space
Does what it says. Will send a DELETE to Kibana to delete the space specified in the `$name` variable

EX:
```powershell
Remove-Space "awesome-space"
```

### Set-Role
This function will create a new role. To configure the specific settings in here, you'll need to edit the body manually. 
Right now, the permissions set in this role allow it to read the Data Views in the "names" key. This theoretically should 
be a hash table, but I guess the body is too large for that to be, so it is instead just JSON. 

EX
```powershell
Set-Role "role"
```

### Remove-Role
Does what it says. DELETEs the specific role in Kibana

```powershell
Remove-Role "role"
```

### Set-User
This will create a user. Because Kibana does not actually manage users, this will be done through
Elasticsearch rather than Kibana. The password for the user is in the JSON of the request.

EX:
```powershell
Set-User "user"
```

### Remove-User
Removes a user

### Set-DataView
This will create a dataview for the user's space. This may not be nessesary depending on how 
you are configuring your spaces. In the original usage of this script, each user was only meant 
to see one index named after themselves. This may not be applicable to your use case. Regardless,
it's easy enough to modify this function and the request. 

EX:
```powershell
Set-DataView "data-view"
```

### Remove-DataView
Removes a data view from Kibana. 

### Import-Rules
This function, in it's current state, simply modifies a provided `rules.ndjson` to add a unique
index name to each rule. The original goal was to automatically import this ruleset to each space,
but the Kibana API doesn't work that well a lot of the time.

EX:
```powershell
Import-Rules "index-segment"
```

### Set-FullAccount
With most of the functions above, specifically `Set-Space`, `Set-Role`,`Set-User`,`Set-DataView`,
we can create a full account. This command runs all of these functions with one input. This 
will create a unique user, space, role, and dataview for the user's space. 

EX:
```powershell
Set-FullAccount "Analyst"
```


### Remove-FullAccount
Does the opposite of `Set-FullAccount`.