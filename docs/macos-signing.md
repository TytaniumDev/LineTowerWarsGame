# macOS signing and notarization

The `Sign macOS` CI job signs the macOS build with a Developer ID certificate, notarizes it with
Apple and staples the ticket, so Gatekeeper opens it without a warning. It runs on `main` only
(after a merge, or from **Actions > CI > Run workflow**) and skips, leaving the build unsigned,
until all five secrets below exist.

Never paste these values anywhere except GitHub's secret form.

## 1. Developer ID Application certificate

1. On your Mac, open **Xcode > Settings > Accounts**, select your Apple ID, then click
   **Manage Certificates**.
2. Click **+** and choose **Developer ID Application**. (Only the Account Holder can create one.)
3. Open **Keychain Access**, choose the **login** keychain and the **My Certificates** tab.
4. Right-click **Developer ID Application: <your name> (<team id>)**, choose **Export**, save it as
   `developer_id.p12` and set a strong password.
5. Copy it as base64: `base64 -i developer_id.p12 | pbcopy`.

## 2. App Store Connect API key (for notarization)

1. Go to [App Store Connect](https://appstoreconnect.apple.com) > **Users and Access** >
   **Integrations** > **App Store Connect API** > **Team Keys**. (The first time, the Account Holder
   has to click **Request Access**.)
2. Click **+**, name it `GitHub notarization`, give it **Developer** access and click **Generate**.
3. Note the **Key ID** and the **Issuer ID** shown above the table.
4. Click **Download** next to the key. Apple only lets you download it once.

## 3. GitHub secrets

In the repo, open **Settings > Secrets and variables > Actions** and click
**New repository secret** for each of these:

| Name | Value |
| --- | --- |
| `MACOS_CERTIFICATE_P12` | The base64 text from step 1.5 |
| `MACOS_CERTIFICATE_PASSWORD` | The password from step 1.4 |
| `APPLE_API_KEY_P8` | The whole `.p8` file: `pbcopy < AuthKey_XXXXXXXXXX.p8` |
| `APPLE_API_KEY_ID` | The Key ID from step 2.3 |
| `APPLE_API_ISSUER_ID` | The Issuer ID from step 2.3 |

Then delete the local `.p12` and `.p8` copies, and run **Actions > CI > Run workflow** on `main` to
publish a signed build.
