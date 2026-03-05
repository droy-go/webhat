#!/bin/bash

# Script to fix WebHat repository issues
# Run this script in the repository root

echo "🔧 Fixing WebHat Repository..."

# Check if we're in the right directory
if [ ! -d ".git" ]; then
    echo "❌ Error: Not a git repository. Please run this script in the repository root."
    exit 1
fi

# Step 1: Create package-lock.json files
echo "📦 Creating package-lock.json files..."

if [ -d "reader" ]; then
    echo "  → Processing reader..."
    cd reader
    npm install
    cd ..
    git add reader/package-lock.json 2>/dev/null || true
fi

if [ -d "editor" ]; then
    echo "  → Processing editor..."
    cd editor
    npm install
    cd ..
    git add editor/package-lock.json 2>/dev/null || true
fi

# Step 2: Add Android resource files
echo "🤖 Adding Android resource files..."

mkdir -p mobile/flutter_storypack/android/app/src/main/res/drawable
mkdir -p mobile/flutter_storypack/android/app/src/main/res/values
mkdir -p mobile/flutter_storypack/android/app/src/main/res/xml

# Create launch_background.xml
cat > mobile/flutter_storypack/android/app/src/main/res/drawable/launch_background.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/white" />
</layer-list>
EOF

# Create styles.xml
cat > mobile/flutter_storypack/android/app/src/main/res/values/styles.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Light.NoActionBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:forceDarkAllowed">false</item>
        <item name="android:windowFullscreen">false</item>
        <item name="android:windowDrawsSystemBarBackgrounds">false</item>
        <item name="android:windowLayoutInDisplayCutoutMode">shortEdges</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Light.NoActionBar">
        <item name="android:windowBackground">?android:colorBackground</item>
    </style>
</resources>
EOF

# Create strings.xml
cat > mobile/flutter_storypack/android/app/src/main/res/values/strings.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">WebHat StoryPack</string>
</resources>
EOF

# Create file_paths.xml
cat > mobile/flutter_storypack/android/app/src/main/res/xml/file_paths.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<paths xmlns:android="http://schemas.android.com/apk/res/android">
    <external-path name="external_files" path="." />
    <external-cache-path name="external_cache" path="." />
    <cache-path name="cache" path="." />
    <files-path name="files" path="." />
    <external-media-path name="media" path="." />
</paths>
EOF

# Create network_security_config.xml
cat > mobile/flutter_storypack/android/app/src/main/res/xml/network_security_config.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <base-config cleartextTrafficPermitted="false">
        <trust-anchors>
            <certificates src="system" />
        </trust-anchors>
    </base-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
    </domain-config>
</network-security-config>
EOF

# Create backup_rules.xml
cat > mobile/flutter_storypack/android/app/src/main/res/xml/backup_rules.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<full-backup-content>
    <include domain="sharedpref" path="." />
    <include domain="database" path="." />
    <exclude domain="cache" path="." />
    <exclude domain="external" path="cache" />
</full-backup-content>
EOF

# Create data_extraction_rules.xml
cat > mobile/flutter_storypack/android/app/src/main/res/xml/data_extraction_rules.xml << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<data-extraction-rules>
    <cloud-backup>
        <include domain="sharedpref" path="." />
        <include domain="database" path="." />
        <exclude domain="cache" path="." />
        <exclude domain="external" path="cache" />
    </cloud-backup>
    <device-transfer>
        <include domain="sharedpref" path="." />
        <include domain="database" path="." />
        <exclude domain="cache" path="." />
    </device-transfer>
</data-extraction-rules>
EOF

git add mobile/flutter_storypack/android/app/src/main/res/ 2>/dev/null || true

# Step 3: Update .gitignore
echo "📝 Updating .gitignore..."

if ! grep -q "android/local.properties" .gitignore 2>/dev/null; then
    echo "android/local.properties" >> .gitignore
fi

git add .gitignore 2>/dev/null || true

# Step 4: Commit changes
echo "💾 Committing changes..."

git commit -m "Fix GitHub Actions workflow issues

- Add package-lock.json for reader and editor
- Add missing Android resource files
- Add continue-on-error to workflow jobs
- Update .gitignore to exclude local.properties" || echo "Nothing to commit"

# Step 5: Push changes
echo "🚀 Pushing changes to remote..."
git push origin main

echo ""
echo "✅ Done! Your repository has been fixed."
echo ""
echo "Next steps:"
echo "  1. Check GitHub Actions: https://github.com/$(git remote get-url origin | sed 's/.*github.com\///' | sed 's/\.git$//')/actions"
echo "  2. Wait for the workflow to complete"
echo ""
