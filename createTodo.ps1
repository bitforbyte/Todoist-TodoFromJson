# Check if filename was provided
if ($args.Length -eq 0)
{
    Write-Host "Please provide a JSON filename as an argument."
    exit
}
$jsonFileName = $args[0]

# Set default value (Should be overwritten by json file)
$rootTask = [PSCustomObject]@{
    content = $null
    description = $null
    priority = $null
    due_string = $null
    subtasks = $null
}

# Set your API token
$apiToken = Get-Content -Path './config.txt'

# Recursive function to create a task and its subtasks
function Create-Task {
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

# Confirm file given is valid JSON
if (Test-Path $jsonFileName) {
    try {
        # Load the root task from the JSON file
        $rootTask = Get-Content -Path $jsonFileName | ConvertFrom-Json
    } catch {
        Write-Host "Invalid JSON content in file: $jsonFileName! Error $($_.Exception.Message)"
    }
} else {
    Write-Host "File not found: $jsonFileName"
}

try {
    # Create the root task and its subtasks
    Create-Task -task $rootTask -parentId $null
} catch {
    Write-Host "An Uncaught error occured while Creating task! Error: $($_.Exception.Message)"
}

