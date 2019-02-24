# Shared Directory

Any modules in here are shared between two or more tasks.

Because Azure DevOps extensions don't support several tasks sharing code, we have to copy-paste these module files into the `Code\Shared` directory of each task to try and keep them all updated and the same.
This can be done by running the `_CopyFilesToTasksSharedCodeDirectories.ps1` script.