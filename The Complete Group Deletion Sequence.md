The Complete Group Deletion Sequence

# List all group attachments

# 1. Check for users belonging to this group
aws iam get-group --group-name ReadOnly --profile lab

# 2. Check for attached Managed Policies
aws iam list-attached-group-policies --group-name ReadOnly --profile lab

# 3. Check for Inline Policies embedded in the group
aws iam list-group-policies --group-name ReadOnly --profile lab

# Remove all users from the group

aws iam remove-user-from-group --group-name ReadOnly --user-name henry --profile lab

# Detach Managed Policies

aws iam detach-group-policy --group-name ReadOnly --policy-arn "arn:aws:iam::aws:policy/ReadOnlyAccess" --profile lab

# Delete Inline Policies
aws iam delete-group-policy --group-name ReadOnly --policy-name "YourInlinePolicyName" --profile lab

# Delete the empty group
aws iam delete-group --group-name ReadOnly --profile lab