#!/bin/sh
# Update storyboard string files
#
# by 2013 André Pinto andredsp@gmail.com
# based on http://forums.macrumors.com/showthread.php?t=1467446

#update storyboard string   ./UpdateStoryboardString ../Express
#update xib string          ./UpdateStoryboardString ../Express xib


clear

baseDir=$1

stringsExt=".strings"
newStringsExt=".strings.new"
oldStringsExt=".strings.old"
localeDirExt=".lproj"
baselprojName="Base.lproj"
cd $baseDir
# Find Base internationalization folders
find . -name "$baselprojName" | while read baselprojPath
do
    # Get Base project dir
    baselprojDir=$(dirname "$baselprojPath")
    for storyboardExt in ".storyboard" ".xib"
    do
        # Find storyboard file full path inside base project folder
        find "$baselprojPath" -name "*$storyboardExt" | while read storyboardPath

        do
        # Get Base strings file full path
            baseStringsPath=$(echo "$storyboardPath" | sed "s/$storyboardExt/$stringsExt/")

        # Get storyboard file name and folder
            storyboardFile=$(basename "$storyboardPath")
            storyboardDir=$(dirname "$storyboardPath")

        #Get the full path of the storyboard and the temporary string files. This is the fix for ibtool error
            storyboardFullPath=$(echo $(echo `pwd`)$(echo "$storyboardPath" | cut  -c2-))
            newBaseStringsFullPath=$(echo `pwd`"/Main.strings.new")

            echo "Full path of the storyboard $storyboardFullPath"
            echo "Full path of the temporary string files $newBaseStringsFullPath"
            echo "storyboardFile $storyboardFile"
            echo "storyboardDir $storyboardDir"
        # Get New Base strings file full path and strings file name
            stringsFile=$(basename "$baseStringsPath")

        # Create strings file only when storyboard file newer
            newer=$(find "$storyboardPath" -prune -newer "$baseStringsPath")
            [ -f "$baseStringsPath" -a -z "$newer" ] && {
            echo "$storyboardFile file not modified."
                continue
            }

            echo "Creating default $stringsFile for $storyboardFile..."

            ibtool --export-strings-file "$newBaseStringsFullPath" "$storyboardFullPath"
            iconv -f UTF-16 -t UTF-8 "$newBaseStringsFullPath" > "$baseStringsPath"
            rm "$newBaseStringsFullPath"

        # Get all locale strings folder with same parent as Base
            ls -d "$baselprojDir/"*"$localeDirExt" | while read localeStringsDir
            do
            # Skip Base strings folder
                [ "$localeStringsDir" = "$storyboardDir" ] && continue

                localeDir=$(basename "$localeStringsDir")
                localeStringsPath="$localeStringsDir/$stringsFile"

            # Just copy base strings file on first time
                if [ ! -e "$localeStringsPath" ]; then
                    echo "Copying default $stringsFile for $localeDir..."
                    cp "$baseStringsPath" "$localeStringsPath"
                else
                    echo "Merging $stringsFile changes for $localeDir..."
                    oldLocaleStringsPath=$(echo "$localeStringsPath" | sed "s/$stringsExt/$oldStringsExt/")
                    cp "$localeStringsPath" "$oldLocaleStringsPath"

                    # Merge baseStringsPath to localeStringsPath
                    awk 'NR == FNR && /^\/\*/ {x=$0; getline; a[x]=$0; next} /^\/\*/ {x=$0; print; getline; $0=a[x]?a[x]:$0; printf $0"\n\n"}' $oldLocaleStringsPath $baseStringsPath > $localeStringsPath
                    rm "$oldLocaleStringsPath"
                fi
            done
        done
    done
done



