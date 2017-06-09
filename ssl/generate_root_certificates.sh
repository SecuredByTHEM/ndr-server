#!/bin/sh

. ./config

# We need the GOPATH set
if [ -z $GOPATH ]; then
    echo "GOPATH is not setup! bailing out"
    exit 1
fi

mkdir -p $CERT_ROOT

# Create a template database which we'll copy into place
echo "=== Creating empty template database for CFSSL"
$GOOSE -path $GOPATH/src/github.com/cloudflare/cfssl/certdb/sqlite up

if [ $? -ne 0 ]; then
    echo "goose failed to create the template database; bailing out"
    exit 1
fi

# We should end up with certstore_development.db in the CWD
if [ ! -e $SQLITE_TEMPLATE ]; then
    echo "Template database MIA!"
    exit 1
fi

# {"driver": "postgres", "data_source": ""}
# Let's do the recorder root certificates
mkdir -p $RECORDER_ROOT_DIR
if [ ! -e $RECORDER_ROOT_CERT ]; then
    echo "=== Generating Recorder Root Certificate ==="
    $CFSSL genkey -initca $RECORDER_ROOT_JSON | $CFSSLJSON -bare $RECORDER_ROOT_DIR/ca

    if [ $? -ne 0 ]; then
        echo "Failed to generate root cert, bailing out"
        exit 1
    fi

    # Copy the template database to the root directory
    cp $SQLITE_TEMPLATE $RECORDER_ROOT_DB

    # Generate the root CA sqlite database
    echo "{\"driver\": \"sqlite3\", \"data_source\": \"$RECORDER_ROOT_DB\"}" > $RECORDER_ROOT_DB_CONFIG
else 
    echo "Found Recorder Root, skipping recorder CA generation"
fi

# Now we need to generate the intermediate certificate
mkdir -p $RECORDER_INTERMEDIATE_DIR
if [ ! -e $RECORDER_INTERMEDIATE_CERT ]; then
    echo "=== Generating Recorder Intermediate Certificate ==="
    $CFSSL gencert -ca $RECORDER_ROOT_CERT \
                   -ca-key $RECORDER_ROOT_KEY \
                   -config $CFSSL_CONFIG \
                   -db-config $RECORDER_ROOT_DB_CONFIG \
                   -profile "intermediate" \
                    $RECORDER_INTERMEDIATE_JSON | $CFSSLJSON -bare $RECORDER_INTERMEDIATE_DIR/intermediate

    if [ $? -ne 0 ]; then
        echo "Failed to generate intermediate cert, bailing out"
        exit 1
    fi

    # Copy the template database to the root directory
    cp $SQLITE_TEMPLATE $RECORDER_INTERMEDIATE_DB

    # Generate the root CA sqlite database
    echo "{\"driver\": \"sqlite3\", \"data_source\": \"$RECORDER_INTERMEDIATE_DB\"}" > $RECORDER_INTERMEDIATE_DB_CONFIG
else 
    echo "Found Recorder Intermediate Cert, skipping recorder CA generation"
fi

# Now that we have the intermediate certificate generated, generate the OCSP response certificate
mkdir -p $RECORDER_OCSP_DIR
if [ ! -e $RECORDER_OCSP_KEY ]; then
    echo "=== Generating Recorder OCSP Certificate ==="
    $CFSSL gencert -ca $RECORDER_INTERMEDIATE_CERT \
                   -ca-key $RECORDER_INTERMEDIATE_KEY \
                   -config $CFSSL_CONFIG \
                   -db-config $RECORDER_INTERMEDIATE_DB_CONFIG \
                   -profile "ocsp" \
                    $RECORDER_OCSP_JSON | $CFSSLJSON -bare $RECORDER_OCSP_DIR/ocsp

    if [ $? -ne 0 ]; then
        echo "Failed to generate OCSP cert, bailing out"
        exit 1
    fi

else 
    echo "Found Recorder OCSP Key, skipping recorder OCSP generation"
fi

echo "Copying cerificates to default installation path"
mkdir -p /etc/ndr
sudo cp $RECORDER_ROOT_CERT /etc/ndr/ca.crt
sudo cp $RECORDER_INTERMEDIATE_CERT /etc/ndr/bundle.crt

rm $SQLITE_TEMPLATE
