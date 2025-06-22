# File Comparison Methods

## Using `diff` Command
Basic file comparison tools:
```bash
diff file1.txt file2.txt                  # Basic comparison
diff -u file1.txt file2.txt              # Unified format (more readable)
diff -y file1.txt file2.txt              # Side by side comparison
diff -r directory1 directory2             # Recursive directory comparison
```

## Using `vimdiff`
Visual comparison in vim:
```bash
vimdiff file1.txt file2.txt              # Opens both files in vim with differences highlighted
```

## Using `git diff`
For git repositories:
```bash
git diff file.txt                        # Changes in working directory
git diff commit1 commit2 file.txt        # Between commits
git diff branch1..branch2 file.txt       # Between branches
```

## Comparing Local File with GitHub Repository File

### Using curl with diff
```bash
diff -u <(curl -s https://raw.githubusercontent.com/user/repo/branch/path/to/file) local_file
```

### Download and Compare
```bash
wget https://raw.githubusercontent.com/user/repo/branch/path/to/file -O /tmp/remote_file
diff -u /tmp/remote_file local_file
```
