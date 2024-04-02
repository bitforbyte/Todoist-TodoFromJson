# Define the desired date format and user input format
$global:dateFormat = "MM/dd/yy"

# Function to prompt user based on custom placeholders
function Get-UserInputFromPlaceholder {
    param([string]$text)
    # Regex to find and process all placeholders in the given text
    $placeholderPattern = '\{PromptUser_([^}]+)\}'
    $matches = [regex]::Matches($text, $placeholderPattern)

    foreach ($match in $matches) {
        $fullPlaceholder = $match.Value
        $placeholderContent = $match.Groups[1].Value

        # Split the placeholder content to extract the prompt and optional parts
        $parts = $placeholderContent -split ','
        $promptMessage = $parts[0]
        $typeHint = ''
        $defaultValue = ''
        if ($parts.Length -gt 1) { $typeHint = "[$($parts[1].Trim())]" }
        if ($parts.Length -gt 2) { $defaultValue = $parts[2].Trim() }

        # Construct the full prompt message, including the default value if provided
        $fullPromptMessage = $promptMessage
        if ($typeHint -ne '') { $fullPromptMessage += " $typeHint" }
        if ($defaultValue -ne '') { $fullPromptMessage += " [Default: $defaultValue]" }

        # Read user input
        $userInput = Read-Host $fullPromptMessage
        if (-not $userInput) { # If user input is empty, use the default value
            $userInput = $defaultValue
        }

        # Replace only the current placeholder in the text with the user's input
        $text = $text.Replace($fullPlaceholder, $userInput)
    }

    return $text
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
