param(
    [Parameter(Mandatory=$true)]
    [string]$jsonFileName
)

# Set your API token
#$apiToken = Get-Content -Path './config.txt'
$encryptedApiKey = Get-Content -Path "./config.txt"

# Convert encryptedApiKey to a secure string
$secureApiKey = ConvertTo-SecureSTring -String $encryptedApiKey

# Decrypt the secure string to get the plaintext API key
$apiToken = [System.Net.NetworkCredential]::new("", $secureApiKey).Password

# Recursive function to create a task and its subtasks
function Add-Task {
    param($task, $parentId)

    # Convert the task to a hashtable cause just JSON is funky about adding proper
    $taskHashtable = $task | ConvertTo-Json -Depth 10 | ConvertFrom-Json  -AsHashtable

    # Add the parent ID to the task if it's not null
    if ($null -ne $parentId) {
        $taskHashtable['parent_id'] = $parentId
    }

    # Create the task
    $taskJson = $taskHashtable | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri 'https://api.todoist.com/rest/v2/tasks' -Method Post -Body $taskJson -ContentType 'application/json' -Headers @{
        'Authorization' = "Bearer $apiToken"
    }

    # Get the ID of the task
    $taskId = $response.id

    # If the task has subtasks, create them
    if ($task.PSObject.Properties.Name -contains 'subtasks') {
        foreach ($subtask in $task.subtasks) {
            Create-Task -task $subtask -parentId $taskId
        }
    }
}

# Load the root task from the JSON file
$rootTask = Get-Content -Path $jsonFileName | ConvertFrom-Json

# Create the root task and its subtasks
Add-Task -task $rootTask -parentId $null