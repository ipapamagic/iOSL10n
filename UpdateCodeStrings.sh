#!/bin/sh

#  FindInFile.sh
#  
#
#  Created by Gregory Hill on 2/28/13.
#
# Usage:
# ./FindInFile.sh <baseDir>
#	e.g. ~/Desktop/Code/Pandora/dev/Pandora


baseDir=$1

localeDirExt=".lproj"
stringsFile="Localizable.strings"

baseDirLength=$(echo ${#baseDir})

if [ $baseDirLength -eq 0 ]; then
	echo "FindInFile.sh <baseDir>"
else

	# First, loop through all *.m files and find any occurance of NSLocalizedString().
	# Write anything found to output.txt.  This will be the source for the English versions of all
	#	key/value localized strings.

	fullPath="$baseDir"

	clear
	echo "************************************************************************************"
#	echo "grepping NSLocalizedString(,) occurrences."
	echo "Start: $fullPath"

	# change directory into fullPath

	cd "$fullPath"

	find . -type f -name "*.m*" -print > listOfFiles.txt
   # cat ~/ok.txt | egrep -i ‘NSLocalizedString\(\s*@\s*”.*?”\s*,\s*@“.*?”\)’
#	cat listOfFiles.txt |tr '\n' '\0' |xargs -0 grep -o "NSLocalizedString(@\"[[:graph:] ]*\" *, *@\"[[:graph:] ]*\")" > output.txt

    cat listOfFiles.txt |tr '\n' '\0' |xargs -0 egrep -o 'NSLocalizedString\(\s*@\".+?\"\s*,\s*@\".*?\"\s*\)' > output.txt
    echo "*****Swift*****" >> output.txt
	find . -type f -name "*.swift" -print >> listOfFiles.txt
    cat listOfFiles.txt |tr '\n' '\0' |xargs -0 egrep -o 'NSLocalizedString\(\s*\".+?\"\s*,\s*tableName:.+?,\s*bundle:.+?,\s*value:\s*\".*?\"\s*,\s*comment:\s*\".*?\"\s*\)' >> output.txt

	# Next, get all locale strings folders.  If Localizable.strings found, append to existing file; otherwise, create a new one.

	for localeStringsDir in `find . -name "*$localeDirExt" -print`
	do
		echo "\n**************************************************"
		echo "Found Locale File.\n"
		echo "strings dir: $localeStringsDir"

        pwd
		foundDir=$(echo $localeStringsDir | grep -o "Base.lproj")
		length=$(echo ${#foundDir})

#	# Make sure we aren't touching Base.lproj directory
#		if [ $length -eq 0 ]; then
			# change directory into localeStringsDir
#            cd "$EXCUTE_PATH"
            cd "$fullPath"
			cd "$localeStringsDir"

			echo "cd down to:"
			pwd

			if [ -f $stringsFile ]; then
				echo "File $localeStringsDir/$stringsFile exists"
			else
				echo "File $localeStringsDir/$stringsFile does not exist"

				echo "" > $stringsFile
			fi

			# For each Localizable.strings file, loop through output.txt and parse out the key/value pairs for the localized strings.
			# If the key already exists in the file, then skip; otherwise, append the key/value (in proper format) to the end of the file.
            SWIFT_CODE="OFF"
			while read LINE
			do
#				foundLocalizedString=$(echo "$LINE" | grep -o "NSLocalizedString(@\"[[:alnum:]]*\", @\"[a-zA-Z0-9 !@#\$%\^&\*()\.,-\+']*\")")
#				foundKey=$(echo "$foundLocalizedString" | grep -o "(@\"[[:alnum:]]*\"")
                if [ "$LINE" = "*****Swift*****" ]; then
                    SWIFT_CODE="ON"
                    continue
                fi
                if [[ "$SWIFT_CODE" = "OFF" ]]; then
#                    echo "objc:${LINE}"
                    foundLocalizedString=$(echo "$LINE" | egrep -o 'NSLocalizedString\(\s*@".+?"\s*,\s*@".*?"\s*\)')
                    foundKey=$(echo "$foundLocalizedString" | egrep -o '\(@".*?"')
                    keyStart="\""
                    finalKey=$(echo "$foundKey" | grep -o "$keyStart.*")

                    $(grep -q "$finalKey" $stringsFile)

                    if [ $? -eq 1 ]; then
                        echo "****** key is New: $finalKey"

                        foundComment=$(echo "$foundLocalizedString" | egrep -o ",\s*@\".*?\"\)")
                        commentStart="\""
                        intermediateComment=$(echo "$foundComment" | egrep -o "$commentStart.*")

                        finalComment=$(echo "$intermediateComment" | sed "s/)//")

                        echo "/* $finalComment */" >> $stringsFile
                        echo -e "$finalKey = $finalComment;\n" >> $stringsFile
                    else
                        echo "key Exists: $finalKey"
                    fi
                else
                    foundLocalizedString=$(echo "$LINE" | egrep -o 'NSLocalizedString\(\s*\".+?\"\s*,\s*tableName:.+?,\s*bundle:.+?,\s*value:\s*\".*?\"\s*,\s*comment:\s*\".*?\"\s*\)')
                    foundKey=$( echo "$foundLocalizedString" | egrep -o '\(\s*\".+?\"' )
                    keyStart="\""
                    finalKey=$(echo "$foundKey" | grep -o "$keyStart.*")

                    $(grep -q "$finalKey" $stringsFile)

                    if [ $? -eq 1 ]; then
                        echo "****** key is New: $finalKey"

                        foundComment=$(echo "$foundLocalizedString" | egrep -o "comment:\s*\".*?\"\s*)")
                        echo "comment: $foundComment"
                        commentStart="\""
                        intermediateComment=$(echo "$foundComment" | egrep -o "$commentStart.*")

                        finalComment=$(echo "$intermediateComment" | sed "s/)//")

                        echo "/* $finalComment */" >> $stringsFile
                        echo -e "$finalKey = $finalComment;\n" >> $stringsFile
                    else
                        echo "key Exists: $finalKey"
                    fi
                fi

			done < "$fullPath/output.txt"

			# change directory back to baseDir


			echo "cd back up ..:"
			pwd

#	else
#			echo "Ignoring: $localeStringsDir"
#		fi
	done

	echo "\nDone."
fi


