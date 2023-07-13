# Todoist-TodoFromJson
This project is mean to work with Todoist using their api, it will take in a json file that will contain Todoist request objects along with subtasks. It will then create Checklist items on your todoist app

# Authentication

You will need an api key from Todoist in order to send requests link to todoist api documentation can be found [here](https://developer.todoist.com/rest/v2/#authorization)

It is best to encrypt keys, so in order to do so take "Your API Key" and put it in the commands below.
> :warning: ** While this is ok for development, you don't want to store encrypted keys for anything in 'production' **
## For windows
```
"Your API Key" | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Set-Content "./config.txt"
```

## For Linux (Coming soon...)

# Using the scripts
You can run the provided scripts to insert the given json templates into you're json