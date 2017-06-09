#!/bin/sh -x

. ./config

# Start the primary serve service for the recorder intermediate
$CFSSL serve  -db-config $RECORDER_INTERMEDIATE_DB_CONFIG \
              -ca $RECORDER_INTERMEDIATE_CERT \
              -ca-key $RECORDER_INTERMEDIATE_KEY \
              -config $CFSSL_CONFIG \
              -responder $RECORDER_OCSP_CERT \
              -responder-key $RECORDER_OCSP_KEY \
              -ca-bundle $RECORDER_ROOT_CERT \
              -int-bundle $RECORDER_INTERMEDIATE_CERT

