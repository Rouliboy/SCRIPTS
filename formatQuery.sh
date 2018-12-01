#!/bin/bash

set -e

PROPERTY_FILE=app.properties

function getProperty {
   PROP_KEY=$1
   PROP_VALUE=`cat $PROPERTY_FILE | grep "$PROP_KEY" | cut -d'=' -f2`
   echo $PROP_VALUE
}

#REPOSITORY_URL=$(getProperty "nexus.repository.url")
#echo $REPOSITORY_URL

echo
echo "# Reading property from $PROPERTY_FILE"
SIGEO_TABLES_PROPERTY=$(getProperty "sigeo.tables")
#echo $SIGEO_TABLES_PROPERTY

SIGEO_TABLES=$(echo $SIGEO_TABLES_PROPERTY | tr "," "\n")

SED_PATTERN=""
index=0

# Compute nb tables
nbTables=0
for table in $SIGEO_TABLES
do
    nbTables=$((nbTables+1))
done
echo "# Nb tables : $nbTables"

echo "# Prefix all tables with [SIGEO_DEVS].[dbo]."
##########################
# Prefix tables with [SIGEO_DEVS].[dbo].
##########################
for table in $SIGEO_TABLES
do
    index=$((index+1))
    CURRENT_SED_PATTERN="s/"${table}"/[SIGEO_DEVS].[dbo]."${table}"/g"
    if [ "$index" -eq 1 ]
    then
        SED_PATTERN="$SED_PATTERN$CURRENT_SED_PATTERN ;"
    elif [ "$index" -eq "$nbTables" ]
    then
       SED_PATTERN="$SED_PATTERN $CURRENT_SED_PATTERN "
    else
        SED_PATTERN="$SED_PATTERN $CURRENT_SED_PATTERN ;"
    fi
done


##########################
#               Substitutions values
##########################
separator="#"
SUBSTITUTION_VALUES_PROPERTY=$(getProperty "substitutions.values")
SUBSTITUTION_VALUES=$(echo $SUBSTITUTION_VALUES_PROPERTY | tr $separator "\n")
nbSubstValues=0
for subst in $SUBSTITUTION_VALUES
do
    nbSubstValues=$((nbSubstValues+1))
done
echo "# Nb subst values : $nbSubstValues"

if [ "$nbSubstValues" -gt "0" ]; then
    SED_PATTERN="$SED_PATTERN ; "
fi

index=0
for subst in $SUBSTITUTION_VALUES
do
    index=$((index+1))
    elementToSubst=""
    subtituedElement=""
    indexElement=0
    SUBSTITUTION_SINGLE=$(echo $subst | tr "\|" "\n")
    for el in $SUBSTITUTION_SINGLE
    do
        indexElement=$((indexElement+1))
        if [ "$indexElement" -eq 1 ]
        then
            elementToSubst=$el
        else
            subtituedElement=$el
        fi
    done
    echo $elementToSubst
    echo $subtituedElement
    
    CURRENT_SED_PATTERN="s/$elementToSubst/$subtituedElement/g"
    if [ "$index" -eq 1 ]
    then
        SED_PATTERN="$SED_PATTERN$CURRENT_SED_PATTERN ;"
    elif [ "$index" -eq "$nbSubstValues" ]
    then
       SED_PATTERN="$SED_PATTERN $CURRENT_SED_PATTERN "
    else
        SED_PATTERN="$SED_PATTERN $CURRENT_SED_PATTERN ;"
    fi
done

echo $SED_PATTERN

sed "$SED_PATTERN" originalQuery.sql > formattedQuery.sql