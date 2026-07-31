# Firebase App Distribution Setup Guide

This document provides step-by-step instructions for configuring GitHub Actions to automatically verify Tower Conquest, build Android APKs, and distribute them to testers via Firebase App Distribution.

## Overview

The workflow (`verify-and-distribute.yml`) performs the following:

1. **On every push to `main` and pull request:** Runs formatting checks, static analysis, unit tests, and a release web build.
2. **On successful verification:** Builds a release-mode APK and uploads it as a GitHub artifact.
3. **On push to `main` or manual dispatch:** Distributes the release-mode APK to Firebase App Distribution using a service-account credential.

The workflow uses **Firebase service-account JSON authentication only** — no user refresh tokens or `FIREBASE_TOKEN`. It provisions Java 17 and the Android SDK on the GitHub-hosted runner before building the APK.

## Prerequisites

Before configuring the workflow, ensure you have:

- A Firebase project with App Distribution enabled
- The Tower Conquest Android app registered in Firebase
- A Google Cloud service account with Firebase App Distribution Admin role
- GitHub repository access with permission to add secrets

## Step 1: Create a Firebase Service Account

1. Open the [Google Cloud Console](https://console.cloud.google.com/).
2. Select your Firebase project.
3. Navigate to **IAM & Admin > Service Accounts**.
4. Click **Create Service Account**.
5. Enter a name (e.g., `tower-conquest-ci`) and description.
6. Click **Create and Continue**.
7. Grant the service account the **Firebase App Distribution Admin** role (`roles/firebaseappdistro.admin`).
8. Click **Continue** and then **Done**.

## Step 2: Create and Download the Service Account Key

1. In the **Service Accounts** list, click the service account you just created.
2. Navigate to the **Keys** tab.
3. Click **Add Key > Create new key**.
4. Select **JSON** as the key type.
5. Click **Create**. A JSON file will be downloaded automatically.
6. **Keep this file secure.** You will use it in the next step.

## Step 3: Add GitHub Secrets

1. Open your GitHub repository.
2. Navigate to **Settings > Secrets and variables > Actions**.
3. Click **New repository secret** and add the following:

### Secret 1: `FIREBASE_SERVICE_ACCOUNT_JSON`

- **Name:** `FIREBASE_SERVICE_ACCOUNT_JSON`
- **Value:** Paste the entire contents of the JSON file downloaded in Step 2.
- **Note:** This is a sensitive credential. Treat it as you would a password.

### Secret 2: `FIREBASE_APP_ID`

- **Name:** `FIREBASE_APP_ID`
- **Value:** Your Firebase App ID for the Android app (format: `1:1234567890:android:0a1b2c3d4e5f67890`).
- **Where to find it:** Firebase Console > Project Settings > Your apps > Android app.

## Release Signing Note

The project’s current `android/app/build.gradle.kts` release configuration signs release-mode builds with the Android debug signing configuration. This is suitable for internal Firebase App Distribution testing, but it is **not suitable for Google Play production publishing**. Before Play Store release, replace the debug signing configuration with a dedicated release keystore managed through protected GitHub secrets.

## Step 4: Verify the Workflow

1. Push a commit to `main` or open a pull request.
2. Navigate to **Actions** in your GitHub repository.
3. Watch the **Verify & Distribute** workflow run.
4. Verify that all steps pass:
   - ✅ Checkout code
   - ✅ Format check
   - ✅ Analyze
   - ✅ Run tests
   - ✅ Build web (release verification)
   - ✅ Build APK (release mode)
   - ✅ Distribute to Firebase App Distribution (on main push only)

## Step 5: Configure Tester Groups in Firebase

1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Navigate to **App Distribution > Testers & Groups**.
3. Create tester groups (e.g., `qa-team`, `internal-testers`).
4. Add tester email addresses to each group.

The workflow defaults to distributing to the `qa-team` group. To change this, either:

- Edit the workflow file and change the `--groups` parameter in the `distribute-firebase` step.
- Use the **workflow_dispatch** manual trigger and specify custom groups in the `tester_groups` input.

## Step 6: Manual Distribution Trigger

To manually trigger a distribution without waiting for a main push:

1. Navigate to **Actions** in your GitHub repository.
2. Select **Verify & Distribute**.
3. Click **Run workflow**.
4. Fill in the optional inputs:
   - **distribute_to_firebase:** Set to `true` to distribute.
   - **tester_groups:** Comma-separated group aliases (e.g., `qa-team,internal-testers`).
   - **release_notes:** Custom release notes for the build.
5. Click **Run workflow**.

## Workflow Behavior

### On Pull Requests

- Runs verification only (format, analysis, tests, web build).
- Does **not** build the APK or distribute to Firebase.
- Provides fast feedback on code quality.

### On Push to Main

- Runs full verification.
- Builds the release-mode APK.
- Automatically distributes to Firebase App Distribution using the `qa-team` group.
- Release notes are auto-generated from the commit SHA and branch name.
- The workflow is pinned to Flutter 3.44.8 for reproducible formatting and build behavior.

### On Manual Dispatch

- Runs full verification.
- Builds the release-mode APK.
- Optionally distributes to Firebase based on the `distribute_to_firebase` input.
- Uses custom tester groups and release notes if provided.

## Troubleshooting

### "Permission denied" or "Invalid service account"

- Verify that the service account JSON is correctly pasted into the `FIREBASE_SERVICE_ACCOUNT_JSON` secret.
- Confirm that the service account has the **Firebase App Distribution Admin** role.
- Check that the JSON is valid by pasting it into a JSON validator.

### "App ID not found"

- Verify that the `FIREBASE_APP_ID` secret matches the app ID in Firebase Console.
- Ensure the app is registered in Firebase for the Android platform.

### APK upload fails

- Check that the APK is built correctly by inspecting the **Build APK** step logs.
- Verify that the Firebase project has App Distribution enabled.
- Confirm that the service account has write permissions to App Distribution.

### Workflow does not run on push

- Verify that the workflow file is in `.github/workflows/` and is committed to the `main` branch.
- Check that the branch protection rules do not prevent the workflow from running.
- Inspect the **Actions** tab for any workflow errors.

## Security Best Practices

1. **Rotate the service account key regularly.** Delete old keys and create new ones every 90 days.
2. **Limit the service account scope.** Use the **Firebase App Distribution Admin** role only; do not grant broader permissions.
3. **Audit secret access.** GitHub logs all secret access in the workflow run logs (secrets are masked).
4. **Never commit secrets to the repository.** Always use GitHub Secrets.
5. **Review workflow changes.** Require pull request reviews before merging changes to the workflow file.

## References

- [Firebase App Distribution Documentation](https://firebase.google.com/docs/app-distribution)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)
- [Google Cloud Service Accounts](https://cloud.google.com/iam/docs/service-accounts)
- [GitHub Actions Secrets](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions)
- [Firebase App Distribution IAM Roles](https://firebase.google.com/docs/projects/iam/roles-predefined-product#firebase-app-distribution-roles)
