#!/bin/bash
 
main() {
	SCRIPTPATH=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
	# validate OpenEdge variables and java
	source ${SCRIPTPATH}/validate.sh

	# read common properties required for create and start db
	source ${SCRIPTPATH}/db.properties

	mkdir -p ${DB_DIR}
	cd ${DB_DIR}

	if [ -z ${DB_CREATE_METHOD} ]; then
		echo "DB_CREATE_METHOD is not set"
		exit 1
	fi

	case "${DB_CREATE_METHOD}" in
	customDB)
		load_database_structure ${ARTIFACTS_DIR} ${DB_DIR} ${DB_NAME}
		load_database_schema ${ARTIFACTS_DIR} ${DB_NAME}
		load_database_data ${ARTIFACTS_DIR} ${DB_NAME}
		;;
	backupDB)
		BACKUP_FILE=${ARTIFACTS_DIR}/${DB_NAME}.bck
		echo "Restoring database named '${DB_NAME}' from the backup DB file '${DB_NAME}.bck'"
		prorest ${DB_NAME} ${BACKUP_FILE} || exit 1
		;;
	sampleDB)
		echo "Creating a db named '${DB_NAME}' from the sampleDB '${SAMPLE_DB_NAME}' "
		prodb ${DB_NAME} ${SAMPLE_DB_NAME} || exit 1
		;;
	externalDB)
		echo "Loading database named '${DB_NAME}' from external database path '${EXTERNAL_DATABASE_PATH}'"
		procopy ${ARTIFACTS_DIR}/${DB_NAME} ${DB_DIR}/${DB_NAME} -newinstance
		chown pscadmin:pscadmin ${DB_DIR}
		;;
	*)
		echo "Invalid DB_CREATE_METHOD"
		exit 1
		;;
	esac
}

load_database_structure() {

	F_ARTIFACTS_DIR=$1
	F_DB_DIR=$2
	F_DB_NAME=$3

	if [ -e ${F_ARTIFACTS_DIR}/${F_DB_NAME}.st ]; then
		cp ${ARTIFACTS_DIR}/${F_DB_NAME}.st ${F_DB_DIR}/
		# We also support .st files which has relative dependency folder path.
		# For more info refer to : https://documentation.progress.com/output/ua/OpenEdge_latest/index.html#page/dmadm%2Fexample-structure-description-file-for-large-fil.html%23
		# Copy the folder which will be used by .st files.
		count_st_folder=$(ls -d -1 ${F_ARTIFACTS_DIR}/*/ 2>/dev/null | awk '{print $1}' | wc -l)
		if [[ $count_st_folder != 0 ]]; then
			cp -r $(ls -d -1 ${F_ARTIFACTS_DIR}/*/ 2>/dev/null | awk '{print $1}') ${F_DB_DIR}/
		fi

		STRUC_FILE=${F_DB_DIR}/${F_DB_NAME}.st
		echo "Loading ${STRUC_FILE} file ..."
		prostrct create ${F_DB_NAME} ${STRUC_FILE} >>customDB.log
		if [ $? -ne 0 ]; then
			echo "Loading ${STRUC_FILE} file failed." && cat customDB.log
			exit 1
		fi
		procopy ${DLC}/empty ${F_DB_NAME} || exit 1
	else
		prodb ${F_DB_NAME} empty || exit 1
	fi
}

load_database_schema() {

	F_ARTIFACTS_DIR=$1
	F_DB_NAME=$2

	for df in ${F_ARTIFACTS_DIR}/*.df; do
		# This a weird behaviour in shell script. If say there are no .df file, it will run the loop once with value of $df as ${F_ARTIFACTS_DIR}/*.df
		# Below line will handle the case.
		[ -e "$df" ] || continue
		echo "Loading ${df} file ..."
		mpro -i -rx -b -1 -db ${F_DB_NAME} -p ${ABL_UTIL}/customDB/procure.r -param "LOAD_SCHEMA,${df}" >>customDB.log

        # Logic for error while loading .df file: If there is an erorr in a <file-name>.df ,  a <db-name>.e will be generated
		count_error_files=$(ls ${DB_DIR}/*.e 2>/dev/null | wc -l)

		if [[ $count_error_files != 0 ]]; then
			echo "Loading ${df} file failed." && cat customDB.log
			for filename in ${DB_DIR}/*.e; do
				# Handling the case if there are no .e files
				[ -e "$df" ] || continue
				cat $filename
			done
			rm -f ${DB_DIR}/*.e
			exit 1
		fi
	done
}

load_database_data() {

	F_ARTIFACTS_DIR=$1
	F_DB_NAME=$2

	count=$(ls -1 ${F_ARTIFACTS_DIR}/*.d 2>/dev/null | wc -l)
	if [ $count != 0 ]; then
		echo "Loading all .d files ..."
		mpro -i -b -1 -db ${F_DB_NAME} -p ${ABL_UTIL}/customDB/procure.r -param "LOAD_DATA,ALL,${F_ARTIFACTS_DIR}" >>customDB.log
		# Logic for error while loading .d file: If there is an erorr in a <file-name>.d ,  a <file-name>.e will be generated
		count_error_files=$(ls ${F_ARTIFACTS_DIR}/*.e 2>/dev/null | wc -l)
		if [ $count_error_files != 0 ]; then
			echo "Loading of .d  file(s) failed." && cat customDB.log
			for filename in ${F_ARTIFACTS_DIR}/*.e; do
				# Handling the case if there are no .e files
				[ -e "$df" ] || continue
				cat $filename
			done
			exit 1
		fi

	fi
}

main "$@"
