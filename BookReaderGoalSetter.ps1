Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()

# Function to create a label and textbox
function Create-FormInput([System.Windows.Forms.Form]$form, [string]$labelText, [int]$yPosition) {
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $labelText
    $label.Location = New-Object System.Drawing.Point(10, $yPosition)
    $label.Size = New-Object System.Drawing.Size(280, 20)
    $form.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBoxYPosition = $yPosition + 20
    $textBox.Location = New-Object System.Drawing.Point(10, $textBoxYPosition)
    $textBox.Size = New-Object System.Drawing.Size(260, 20)
    $form.Controls.Add($textBox)

    return $textBox
}

# Function to calculate the reading schedule
function Generate-ReadingSchedule($title, $totalPages, $pagesPerWeek) {
    $weeksNeeded = [math]::Ceiling($totalPages / $pagesPerWeek)
    $daysPerWeek = 7 # Adjust this for the actual number of days you plan to read each week
    $rootTask = [PSCustomObject]@{
        content    = "Read '$title'"
        priority   = "3"
        subtasks   = @()
    }

    for ($week = 1; $week -le $weeksNeeded; $week++) {
        $weekStartPage = ($week - 1) * $pagesPerWeek + 1
        $weekEndPage = [math]::Min($week * $pagesPerWeek, $totalPages)
        $weekContent = "Read '$title' pages $weekStartPage to $weekEndPage"
        $dailyPages = [math]::Ceiling(($weekEndPage - $weekStartPage + 1) / $daysPerWeek)

        $weekSubtasks = @()
        for ($day = 0; $day -lt $daysPerWeek; $day++) {
            $dayStartPage = $weekStartPage + ($day * $dailyPages)
            $dayEndPage = [math]::Min($dayStartPage + $dailyPages - 1, $weekEndPage)

            if ($dayStartPage -le $weekEndPage) {
                $weekSubtasks += [PSCustomObject]@{
                    content = "Read '$title' pages $dayStartPage to $dayEndPage"
                    priority = "3"
                }
            }
        }

        $rootTask.subtasks += [PSCustomObject]@{
            content    = $weekContent
            priority   = "3"
            subtasks   = $weekSubtasks
        }
    }

    return $rootTask
}

# Create the form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'Book Reading Breakdown'
$form.Size = New-Object System.Drawing.Size(300, 280)
$form.StartPosition = 'CenterScreen'

# Add inputs using the Create-FormInput function
$titleBox = Create-FormInput $form 'Book Title:' 20
$pagesBox = Create-FormInput $form 'Total Pages:' 70
$pagesPerWeekBox = Create-FormInput $form 'Pages per Week:' 120

# Add the submit button
$submitButton = New-Object System.Windows.Forms.Button
$submitButton.Location = New-Object System.Drawing.Point(10, 170)
$submitButton.Size = New-Object System.Drawing.Size(260, 23)
$submitButton.Text = 'Generate Reading Schedule'
$form.Controls.Add($submitButton)

$submitButton.Add_Click({
    $title = $titleBox.Text
    $totalPages = [int]$pagesBox.Text
    $pagesPerWeek = [int]$pagesPerWeekBox.Text

    $schedule = Generate-ReadingSchedule $title $totalPages $pagesPerWeek
    $json = $schedule | ConvertTo-Json -Depth 10

    # Specify the file name and path here
    $json | Out-File "ReadingSchedule.json"

    [System.Windows.Forms.MessageBox]::Show('Reading schedule created!')
    $form.Close()
})

# Show the form
$form.ShowDialog() | Out-Null