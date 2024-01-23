# Import the necessary libraries
import tkinter as tk
from tkinter import ttk
import json

# Load the tasks from the JSON file
with open('./PRChecklist.json') as f:
    tasks = json.load(f)

# Function to recursively add tasks to the treeview
def add_task(task, parent=''):
    id = tree.insert(parent, 'end', text=task['content'])
    for subtask in task.get('subtasks', []):
        add_task(subtask, id)

# Submit button callback function
def submit():
    selected_items = tree.selection()
    print("Selected tasks:")
    print(f"Submitting {selected_items}...") 

# Create the main window
root = tk.Tk()

# Create a treeview to display all tasks
tree = ttk.Treeview(root)
tree['columns'] = ('task',)
tree.column('#0', width=270, minwidth=270, stretch=tk.YES)  # change stretch to YES
tree.column('task', width=0, minwidth=0, stretch=tk.NO)
tree.heading('#0', text='Task', anchor=tk.W)
tree.heading('task', text='Task Object', anchor=tk.W)
tree['selectmode'] = 'extended'  # Enable selection of multiple contiguous items

# Add all tasks to the treeview
add_task(tasks)

# Add a submit button
submit_button = tk.Button(root, text="Submit", command=submit)

# Use grid instead of pack
tree.grid(row=0, column=0, sticky='nsew')  # 'nsew' means the widget should expand in both directions
submit_button.grid(row=1, column=0, sticky='w')  # 'w' means the button should stick to the west side of its cell

# Configure the row and column weights to make the treeview expand
root.grid_rowconfigure(0, weight=1)
root.grid_columnconfigure(0, weight=1)

# Run the main loop
root.mainloop()
