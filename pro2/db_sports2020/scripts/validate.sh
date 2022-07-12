## Validations

if [ -z ${DB_NAME} ]; then echo "DB_NAME is not set"; exit 1; fi

# Validate if DLC is set
if [ -z ${DLC} ]; then echo "DLC is not set"; exit 1; fi

# Validate if WRKDIR is set
if [ -z ${WRKDIR} ]; then echo "WRKDIR is not set"; exit 1; fi

# Validate if license is provided
if [ ! -s ${DLC}/progress.cfg ]; then echo "License is not provided at ${DLC}"; exit 1; fi

# Validate if JAVA is present
if [ -z ${JAVA_HOME} ]; then echo "JAVA_HOME is not set"; exit 1;
elif [ ! -x "${JAVA_HOME}/bin/java" ]; then echo "JAVA not found at ${JAVA_HOME}"; exit 1; fi