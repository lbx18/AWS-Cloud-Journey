Step 1: Clean All Authentication Credentials
# 1. Delete their Web Console login password
aws iam delete-login-profile --user-name henry --profile lab

# 2. List and delete their CLI Access Keys
aws iam list-access-keys --user-name henry --profile lab
aws iam delete-access-key --user-name henry --access-key-id "YOUR-KEY-ID" --profile lab

# 3. List and deactivate any Multi-Factor Authentication (MFA) devices
aws iam list-mfa-devices --user-name henry --profile lab
aws iam deactivate-mfa-device --user-name henry --serial-number "arn:aws:iam::695331051020:mfa/henry" --profile lab

Step 2: Strip All Policies and Permissions

# 4. List and detach AWS Managed Policies (e.g., AdministratorAccess, ReadOnlyAccess)
aws iam list-attached-user-policies --user-name henry --profile lab
aws iam detach-user-policy --user-name henry --policy-arn "arn:aws:iam::aws:policy/YOUR-POLICY-NAME" --profile lab

# 5. List and delete Inline Policies (policies created directly inside this user)
aws iam list-user-policies --user-name henry --profile lab
aws iam delete-user-policy --user-name henry --policy-name "YOUR-INLINE-POLICY-NAME" --profile lab

# 6. Delete Permissions Boundary (if one was set up)
aws iam delete-user-permissions-boundary --user-name henry --profile lab

Step 3: Sever Structural Connections

# 7. List and remove the user from all IAM groups
aws iam list-groups-for-user --user-name henry --profile lab
aws iam remove-user-from-group --group-name "YOUR-GROUP-NAME" --user-name henry --profile lab

# 8. Delete Git/SSH keys (Only needed if they used AWS CodeCommit)
aws iam list-ssh-public-keys --user-name henry --profile lab
aws iam delete-ssh-public-key --user-name henry --ssh-public-key-id "YOUR-SSH-KEY-ID" --profile lab

Step 4: The Final Purge

aws iam delete-user --user-name henry --profile lab