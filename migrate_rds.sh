#!/bin/bash

# RDS Migration Script
# Purpose: Migrate data from local MySQL to RDS instance
# Requirements:
# - Local MySQL root access (jp)
# - RDS MySQL database credentials
# - Table structure already exists in RDS

LOCAL_USER="root"
LOCAL_PASSWORD="jp"
LOCAL_DB="blog_db"

# User Interaction functions
function prompt_rds_host() {
    while true; do
        read -p "Enter RDS hostname or IP: " RDS_HOST
        if [[ -n "$RDS_HOST" ]]; then
            break
        fi
        echo "Error: Host cannot be empty. Please try again."
    done
}

function confirm_action() {
    local msg="$1"
    while true; do
        read -p "$msg [y/n]: " yn
        case $yn in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer yes or no.";;
        esac
    done
}

echo "Added user interaction functions"

# Database Validation functions
function verify_local_connection() {
    echo -n "Verifying local database connection... "
    if mysql -u $LOCAL_USER -p"$LOCAL_PASSWORD" -e "USE $LOCAL_DB" 2>/dev/null; then
        echo -e "[32mOK[0m"
        return 0
    else
        echo -e "[31mFAILED[0m"
        return 1
    fi
}

function verify_rds_connection() {
    echo -n "Verifying RDS database connection... "
    if mysql -h $RDS_HOST -u $RDS_USER -p"$RDS_PASSWORD" -e "USE $RDS_DB" 2>/dev/null; then
        echo -e "[32mOK[0m"
        return 0
    else
        echo -e "[31mFAILED[0m"
        return 1
    fi
}

function check_table_exists() {
    local host="$1"
    local user="$2"
    local pass="$3"
    local db="$4"
    local table="$5"

    count=$(mysql -h "$host" -u "$user" -p"$pass" "$db" -Nse "SHOW TABLES LIKE \"$table\";" | wc -l)
    [ "$count" -eq 1 ]
}

# Migration functions
function show_progress() {
    while true; do
        printf "."
        sleep 1
    done
}

function migrate_data() {
    echo -e "
Starting data migration from local to RDS..."
    
    # Start progress indicator in background
    show_progress &
    pid=$!
    
    # Perform migration
    mysqldump --no-create-info --single-transaction \
        -u $LOCAL_USER -p"$LOCAL_PASSWORD" $LOCAL_DB blog_post | \
        mysql -h $RDS_HOST -u $RDS_USER -p"$RDS_PASSWORD" $RDS_DB
    
    # Stop progress indicator
    kill $pid >/dev/null 2>&1
    wait $pid 2>/dev/null
    
    echo -e "
[32mMigration completed[0m"
}

# Safety and dry-run functions
function pre_flight_checks() {
    echo "Running pre-flight checks..."
    
    verify_local_connection || return 1
    verify_rds_connection || return 1
    
    echo -n "Checking for source table... "
    if check_table_exists "localhost" $LOCAL_USER $LOCAL_PASSWORD $LOCAL_DB "blog_post"; then
        echo -e "[32mExists[0m"
    else
        echo -e "[31mMissing[0m"
        return 1
    fi
    
    echo -n "Checking for destination table... "
    if check_table_exists $RDS_HOST $RDS_USER $RDS_PASSWORD $RDS_DB "blog_post"; then
        echo -e "[32mExists[0m"
    else
        echo -e "[31mMissing[0m"
        return 1
    fi
    
    echo -e "[32mAll checks passed[0m"
    return 0
}

function count_records() {
    local host="$1" user="$2" pass="$3" db="$4" table="$5"
    mysql -h "$host" -u "$user" -p"$pass" "$db" -Nse "SELECT COUNT(*) FROM $table;" 2>/dev/null
}

function dry_run() {
    echo "DRY RUN: Would execute the following operations:"
    echo "1. Export data from local blog_post table"
    echo "2. Import to RDS blog_post table"
    
    local_count=$(count_records "localhost" $LOCAL_USER $LOCAL_PASSWORD $LOCAL_DB "blog_post")
    echo "Local table contains $local_count records"
    
    # With fake RDS count to avoid accidental connection during dry-run
    echo "RDS table would receive $local_count records"
    
    return 0
}

# Error handling and cleanup
LOCK_FILE="/tmp/rds_migration.lock"

function cleanup() {
    # Remove lock file
    rm -f "$LOCK_FILE"
    # Kill progress indicator if running
    if [ -n "$pid" ]; then
        kill $pid >/dev/null 2>&1
    fi
}

# Setup traps
trap cleanup EXIT
trap "echo \"Migration interrupted\"; exit 1" INT TERM

# File locking to prevent concurrent runs
if ! (set -o noclobber && echo "$$" > "$LOCK_FILE") 2>/dev/null; then
    echo "Error: Another migration is already running (PID $(cat "$LOCK_FILE"))"
    exit 1
fi

# Main script execution
function main() {
    echo -e "[34m=== RDS Migration Tool ===[0m"
    
    prompt_rds_host
    read -p "Enter RDS username (default: coursera): " RDS_USER
    RDS_USER=${RDS_USER:-coursera}
    read -s -p "Enter RDS password: " RDS_PASSWORD
    echo
    read -p "Enter RDS database name: " RDS_DB
    
    if ! confirm_action "Continue with migration?"; then
        echo "Migration cancelled"
        exit 0
    fi
    
    if ! pre_flight_checks; then
        echo -e "[31mPre-flight checks failed. See errors above.[0m"
        exit 1
    fi
    
    echo -e "
Possible actions:"
    echo "1) Dry run (check counts only)"
    echo "2) Full migration"
    
    while true; do
        read -p "Select action (1/2): " choice
        case $choice in
            1) dry_run; break;;
            2) migrate_data; break;;
            *) echo "Invalid choice";;
        esac
    done
    
    post_count=$(count_records $RDS_HOST $RDS_USER $RDS_PASSWORD $RDS_DB "blog_post")
    echo -e "Verification: RDS table now contains $post_count records"
}

# ASCII documentation
cat << \"EOF\" >> migrate_rds.sh

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?

# Architecture Overview:
# +----------------+      +----------------+      +----------------+
# | Local MySQL    |      | Migration      |      | RDS MySQL     |
# | blog_db        |----->| Script         |----->| Instance      |
# | blog_post table|      | Validation &   |      | blog_post     |
# +----------------+      | Transfer       |      | table         |
#                         +----------------+      +----------------+

# Troubleshooting:
# - Connection failures: Verify credentials and network access
# - Missing tables: Ensure identical schema exists in both databases
# - Lock issues: Delete /tmp/rds_migration.lock if script crashed

# Recovery:
# 1. If migration fails mid-process, tables may be partially updated
# 2. Consider restoring from RDS snapshot if needed
# 3. Verify record counts match before and after
EOF

# Start execution
main
exit $?
