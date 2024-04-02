# Define the desired date format and user input format
$global:dateFormat = "MM/dd/yy"

# Function to prompt user based on custom placeholders
function Get-UserInputFromPlaceholder {
    param([string]$placeholder)
    if ($placeholder -match "\{PromptUser_(.+)\}") {
        $parts = $placeholder -split ','
        $promptMessage = $parts[0].Substring(11) # Remove '{PromptUser_' prefix
        $typeHint = if ($parts.Length -gt 1) { "[$($parts[1].Trim())]" } else { "" }
        $defaultValue = if ($parts.Length -gt 2) { $parts[2].Trim() } else { "" }
        
        # Prepare the full prompt message, including the default value if provided
        $fullPromptMessage = "$promptMessage $typeHint"
        if ($defaultValue -ne "") {
            $fullPromptMessage += " [Default: $defaultValue]"
        }

        $userInput = Read-Host $fullPromptMessage
        if (-not $userInput) { # If user input is empty, use the default value
            $userInput = $defaultValue
        }
        return $userInput
    }
    return $placeholder
}



# Function to recursively process each task and subtask for placeholders
function Process-TaskObject {
    param([PSCustomObject]$task)
    foreach ($prop in $task.PSObject.Properties) {
        if ($prop.TypeNameOfValue -eq 'System.String' -and $prop.Value -match "\{PromptUser_.+\}") {
            $prop.Value = Get-UserInputFromPlaceholder $prop.Value
        } elseif ($prop.Name -eq 'subtasks' -and $prop.Value) {
            foreach ($subtask in $prop.Value) {
                Process-TaskObject -task $subtask
            }
        }
    }
}

# Function to create a task (and subtasks) in Todoist via API calls
function Create-Task {
    param($task, $parentId = $null)
    Process-TaskObject -task $task
    $taskHashtable = $task | ConvertTo-Json -Depth 10 | ConvertFrom-Json -AsHashtable
    if ($null -ne $parentId) { $taskHashtable['parent_id'] = $parentId }
    $taskJson = $taskHashtable | ConvertTo-Json -Depth 10
    $response = Invoke-RestMethod -Uri 'https://api.todoist.com/rest/v2/tasks' -Method Post -Body $taskJson -ContentType 'application/json' -Headers @{ 'Authorization' = "Bearer $apiToken" }
    $taskId = $response.id
    if ($task.PSObject.Properties.Name -contains 'subtasks') {
        foreach ($subtask in $task.subtasks) {
            Create-Task -task $subtask -parentId $taskId
        }
    }
}

# Check for the JSON filename argument
if ($args.Length -eq 0) {
    Write-Host "Please provide a JSON filename as an argument."
    exit
}

$jsonFileName = $args[0]
$apiToken = Get-Content -Path './config.txt'

# Confirm the JSON file exists and load it
if (Test-Path $jsonFileName) {
    try {
        $rootTask = Get-Content -Path $jsonFileName | ConvertFrom-Json
        Create-Task -task $rootTask
    } catch {
        Write-Host "Invalid JSON content in file: $jsonFileName! Error $($_.Exception.Message)"
    }
} else {
    Write-Host "File not found: $jsonFileName"
}
