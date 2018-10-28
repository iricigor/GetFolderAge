# Release notes

Release notes for PowerShell script **`Get-FolderAge`** by https://github.com/iricigor

## 1.2.1

Date: Sunday, October 28, 2018

### New functionality in 1.2.1

- No new functionality

### Bug fixes in 1.2.1

- Improved input/output file detection (i.e. folders, non-filesystem items, etc)
- Further PowerShell v2 compatibility issues
- Further improved handling of OutputFile when Threads are used

Full list of resolved issues available [here](https://github.com/iricigor/GetFolderAge/milestone/5?closed=1)

## 1.2

Date: Wednesday, October 24, 2018

### New functionality in 1.2

- If interrupted, script can be restarted and it will skip already processed folders
- Added function alias gfa for Get-FolderAge

### Bug fixes in 1.2

- Threads not working properly together with OutputFile
- PowerShell v2 compatibility issues

Full list of resolved issues available [here](https://github.com/iricigor/GetFolderAge/milestone/4?closed=1)

## 1.1

Date: Wednesday, October 17, 2018

### New functionality in 1.1

- Parameter `-Exclude` which specifies list of folders to be excluded from scanning
- Parameter `-Threads` which forces parallel execution of checks on multiple folders, requires https://github.com/PaulHigin/PSThreadJob

## 1.0

Date: Monday, October 15, 2018

### New functionality in 1.0

- First, initial release
